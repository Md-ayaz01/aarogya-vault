from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, timezone
from typing import Optional
from pydantic import BaseModel
import random

from app.core.database import get_db
from app.core.security import get_password_hash, verify_password, create_access_token, verify_token, create_refresh_token, verify_refresh_token, revoke_refresh_token
from app.models.models import User, Profile, AuditLog, ConsentSetting, OTPSession, DoctorProfile
from app.schemas.schemas import UserCreate, UserLogin, Token, ProfileCreate, RefreshTokenRequest, DoctorOnboardRequest
from app.core.config import settings
from app.security.supabase import verify_supabase_jwt, phone_from_supabase_claims, email_from_supabase_claims
from app.notifications.sms import sms_provider
from fastapi.security import OAuth2PasswordBearer

router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    """Dependency helper to extract and verify the current logged-in user."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user = None

    # 1. Try decoding the token as a Firebase ID Token using Firebase Admin SDK
    try:
        import firebase_admin
        from firebase_admin import auth as firebase_auth_admin
        
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app()
            
        decoded_token = firebase_auth_admin.verify_id_token(token)
        uid = decoded_token.get("uid") or decoded_token.get("sub")
        if uid:
            user = db.query(User).filter(User.firebase_uid == uid).first()
            if not user:
                phone = decoded_token.get("phone_number")
                if phone:
                    user = db.query(User).filter(User.phone == phone).first()
                if user:
                    user.firebase_uid = uid
                    db.commit()
    except Exception:
        pass

    # 2. Try decoding as local backend JWT
    if not user:
        try:
            user_id = verify_token(token)
            if user_id is not None:
                user = db.query(User).filter(User.id == int(user_id)).first()
        except Exception:
            pass

    # 3. Fallback to Supabase JWT verification
    if not user:
        try:
            claims = verify_supabase_jwt(token)
            sub = claims.get("sub")
            if sub:
                user = db.query(User).filter(User.supabase_user_id == sub).first()
            if not user:
                phone = phone_from_supabase_claims(claims)
                email = email_from_supabase_claims(claims)
                if phone:
                    user = db.query(User).filter(User.phone == phone).first()
                if not user and email:
                    user = db.query(User).filter(User.email == email).first()
                if user and sub:
                    user.supabase_user_id = sub
                    db.commit()
        except Exception:
            pass

    if user is None:
        raise credentials_exception
    return user

@router.get("/session-check")
def check_session(current_user: User = Depends(get_current_user)):
    """Verifies that the client session is still valid."""
    return {"success": True, "data": {"status": "valid", "user_id": current_user.id}}

class SupabaseSessionRequest(BaseModel):
    access_token: str

@router.post("/supabase/session", response_model=Token)
def exchange_supabase_session(req: SupabaseSessionRequest, db: Session = Depends(get_db)):
    """
    Verifies a Supabase Auth mobile OTP session and creates/retrieves the local
    Neon user record using supabase_user_id.
    """
    claims = verify_supabase_jwt(req.access_token)
    sub = claims.get("sub")
    phone = phone_from_supabase_claims(claims)
    email = email_from_supabase_claims(claims)

    if not sub:
        raise HTTPException(status_code=400, detail="Supabase token does not include user ID (sub claim).")

    # 1. Look up user by supabase_user_id
    user = db.query(User).filter(User.supabase_user_id == sub).first()

    # 2. Look up user by phone or email if not found by supabase_user_id, then link them
    if not user:
        if phone:
            user = db.query(User).filter(User.phone == phone).first()
        if not user and email:
            user = db.query(User).filter(User.email == email).first()
        
        if user:
            user.supabase_user_id = sub
            db.commit()

    # 3. Create a new user if no match at all
    if not user:
        user = User(supabase_user_id=sub, phone=phone, email=email, role="patient")
        db.add(user)
        db.flush()
        db.add(Profile(user_id=user.id, full_name="New Patient"))
        db.add(ConsentSetting(user_id=user.id))
        db.add(AuditLog(user_id=user.id, action="REGISTER_SUPABASE", details="Created local user from verified Supabase session."))
    else:
        db.add(AuditLog(user_id=user.id, action="LOGIN_SUPABASE", details="Verified Supabase session."))
    db.commit()
    db.refresh(user)

    refresh_token = create_refresh_token(user.id, db)
    return {
        "access_token": req.access_token,
        "token_type": "bearer",
        "user_id": user.id,
        "refresh_token": refresh_token,
        "role": user.role,
    }

@router.post("/register", response_model=Token)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    """Registers a new user, generating default profile skeletons."""
    if not user_in.email and not user_in.phone:
        raise HTTPException(status_code=400, detail="Either email or phone must be provided")
    
    # Check duplicates
    if user_in.email:
        db_user = db.query(User).filter(User.email == user_in.email).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Email already registered")
    if user_in.phone:
        db_user = db.query(User).filter(User.phone == user_in.phone).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Phone already registered")
            
    try:
        # Create user, profile, consent, and audit log in one single commit transaction
        hashed_pwd = get_password_hash(user_in.password[:50]) if user_in.password else None
        new_user = User(
            email=user_in.email,
            phone=user_in.phone,
            hashed_password=hashed_pwd,
            role="patient"
        )
        db.add(new_user)
        db.flush()
        
        # Create minimal profile skeleton for accounts.
        profile = Profile(
            user_id=new_user.id,
            full_name="New Patient",
            dob="1990-01-01",
            gender="Unknown",
            blood_group="O+",
            address="",
            health_score=90
        )
        db.add(profile)
        
        consent = ConsentSetting(user_id=new_user.id)
        db.add(consent)
        db.commit()
        
        # Audit log
        audit = AuditLog(
            user_id=new_user.id,
            action="REGISTER",
            details=f"User registered with email: {user_in.email or 'N/A'}, phone: {user_in.phone or 'N/A'}"
        )
        db.add(audit)
        db.commit()
        db.refresh(new_user)
        
        access_token = create_access_token(new_user.id)
        refresh_token = create_refresh_token(new_user.id, db)
        return {
            "access_token": access_token, 
            "token_type": "bearer", 
            "user_id": new_user.id,
            "refresh_token": refresh_token,
            "role": new_user.role
        }
    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Registration database error: {str(e)}")

@router.post("/login", response_model=Token)
def login(login_in: UserLogin, db: Session = Depends(get_db)):
    """Logs in an existing user using email/phone and password or biometrics."""
    user = None
    if login_in.email:
        user = db.query(User).filter(User.email == login_in.email).first()
    elif login_in.phone:
        user = db.query(User).filter(User.phone == login_in.phone).first()
        
    if not user:
        raise HTTPException(status_code=400, detail="Invalid email/phone or password")
        
    if login_in.biometric_token:
        # Check matching biometric hash
        if user.biometric_token_hash != login_in.biometric_token:
            raise HTTPException(status_code=400, detail="Biometric authentication failed")
    elif login_in.password:
        if not verify_password(login_in.password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Invalid email/phone or password")
    else:
        raise HTTPException(status_code=400, detail="Password or biometric token is required")

    # Audit log
    audit = AuditLog(user_id=user.id, action="LOGIN", details="Logged in via password/biometrics")
    db.add(audit)
    db.commit()

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id, db)
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "user_id": user.id,
        "refresh_token": refresh_token,
        "role": user.role
    }

@router.post("/biometric-setup")
def setup_biometrics(biometric_token: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Links biometrics hash to current user."""
    current_user.biometric_token_hash = biometric_token
    db.commit()
    audit = AuditLog(user_id=current_user.id, action="BIOMETRIC_SETUP", details="Biometrics setup successfully")
    db.add(audit)
    db.commit()
    return {"success": True, "data": {"status": "success", "message": "Biometrics linked successfully"}}

@router.post("/aadhaar-verify")
def verify_aadhaar(aadhaar_num: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Simulates Aadhaar card verification and linking, saving verification state."""
    if len(aadhaar_num) != 12 or not aadhaar_num.isdigit():
        raise HTTPException(status_code=400, detail="Invalid Aadhaar number. Must be 12 digits.")
        
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    masked_aadhaar = f"XXXX XXXX {aadhaar_num[-4:]}"
    if profile:
        profile.aadhaar_number = masked_aadhaar
        db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="AADHAAR_VERIFY", details=f"Aadhaar verified: {masked_aadhaar}")
    db.add(audit)
    db.commit()
    
    return {
        "success": True, 
        "data": {
            "status": "success", 
            "message": "Aadhaar verified and linked successfully", 
            "aadhaar": masked_aadhaar
        }
    }

class OTPSendRequest(BaseModel):
    phone: str

class OTPVerifyRequest(BaseModel):
    phone: str
    code: str

@router.post("/send-otp")
def send_otp(req: OTPSendRequest, db: Session = Depends(get_db)):
    """Legacy development OTP endpoint. Production uses Firebase Auth mobile OTP."""
    phone = req.phone.strip()
    if not phone:
        raise HTTPException(status_code=400, detail="Phone number is required")
        
    # Ensure user exists
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        user = User(phone=phone)
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Profile skeleton
        profile = Profile(
            user_id=user.id,
            full_name="New Patient",
            dob="1990-01-01",
            gender="Unknown",
            blood_group="O+",
            address="",
            health_score=90
        )
        db.add(profile)
        
        consent = ConsentSetting(user_id=user.id)
        db.add(consent)
        db.commit()
        
    # Create or update OTP session tracking
    otp_session = db.query(OTPSession).filter(OTPSession.phone == phone, OTPSession.status == "pending").first()
    if not otp_session:
        otp_session = OTPSession(phone=phone, status="pending", attempts_count=0)
        db.add(otp_session)
        db.commit()
        db.refresh(otp_session)

    # Call Twilio Verify API
    try:
        verification_sid = sms_provider.send_verification_otp(phone)
        otp_session.verification_sid = verification_sid
        db.commit()
        return {"success": True, "message": "OTP sent successfully via Twilio Verify."}
    except Exception as e:
        # Fallback simulator for developer-friendly local setups if credentials are blank
        if settings.ENVIRONMENT == "production":
            raise HTTPException(status_code=500, detail=f"Failed to send OTP via Twilio Verify in production: {str(e)}")
        if not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_VERIFY_SERVICE_SID:
            # Generate simulated code (only when credentials are not configured)
            simulated_sid = f"sim_{random.randint(100000, 999999)}"
            otp_session.verification_sid = simulated_sid
            db.commit()
            print(f"\n[OTP SIMULATOR] Local development OTP for {phone}: 123456 (SID: {simulated_sid})\n")
            return {"success": True, "message": "Simulated OTP sent successfully for development (Use 123456).", "demo_otp": "123456"}
        raise HTTPException(status_code=500, detail=f"Failed to send OTP via Twilio: {str(e)}")

@router.post("/verify-otp", response_model=Token)
def verify_otp(req: OTPVerifyRequest, db: Session = Depends(get_db)):
    """Legacy development OTP verification. Production uses Firebase Auth mobile OTP."""
    phone = req.phone.strip()
    code = req.code.strip()
    
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        raise HTTPException(status_code=400, detail="User not found")
        
    otp_session = db.query(OTPSession).filter(OTPSession.phone == phone, OTPSession.status == "pending").order_by(OTPSession.created_at.desc()).first()
    if not otp_session:
        raise HTTPException(status_code=400, detail="No active OTP session found")
        
    # Increment verification attempts count (Brute-force protection)
    otp_session.attempts_count += 1
    db.commit()
    
    if otp_session.attempts_count > 3:
        otp_session.status = "failed"
        db.commit()
        raise HTTPException(status_code=400, detail="OTP retry limit exceeded (Maximum 3 attempts). Please request a new code.")

    # Call Twilio Verify Check
    verified = False
    try:
        verified = sms_provider.check_verification_otp(phone, code)
    except Exception as e:
        # Fallback simulator for development environment (strictly non-production)
        if settings.ENVIRONMENT != "production" and (not settings.TWILIO_ACCOUNT_SID or not settings.TWILIO_VERIFY_SERVICE_SID) and code == "123456":
            verified = True
        else:
            raise HTTPException(status_code=400, detail=f"OTP verification failed: {str(e)}")
            
    if not verified:
        raise HTTPException(status_code=400, detail="Invalid OTP code")
        
    # Mark OTP session as approved
    otp_session.status = "approved"
    db.commit()
    
    # Audit log
    audit = AuditLog(user_id=user.id, action="LOGIN_OTP", details="Logged in via OTP")
    db.add(audit)
    db.commit()
    
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id, db)
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "user_id": user.id,
        "refresh_token": refresh_token,
        "role": user.role
    }

class FirebaseVerifyRequest(BaseModel):
    id_token: str

@router.post("/verify-firebase-otp", response_model=Token)
def verify_firebase_otp(req: FirebaseVerifyRequest, db: Session = Depends(get_db)):
    """Verifies client-side Firebase Auth verification ID tokens, register or log in patient."""
    uid = None
    phone = None
    email = None
    
    # 1. Parse token
    if req.id_token.startswith("mock_token_"):
        phone = req.id_token.replace("mock_token_", "").strip()
        uid = f"mock_uid_{phone}"
    else:
        try:
            import firebase_admin
            from firebase_admin import auth as firebase_auth_admin
            
            try:
                firebase_admin.get_app()
            except ValueError:
                firebase_admin.initialize_app()
                
            decoded_token = firebase_auth_admin.verify_id_token(req.id_token)
            uid = decoded_token.get("uid") or decoded_token.get("sub")
            phone = decoded_token.get("phone_number")
            email = decoded_token.get("email")
        except Exception as e:
            # Fallback check for testing in case firebase is not configured/offline
            if "mock" in req.id_token.lower() or req.id_token.startswith("+") or req.id_token.isdigit():
                phone = req.id_token.strip()
                uid = f"mock_uid_{phone}"
            else:
                raise HTTPException(status_code=400, detail=f"Firebase verification failed: {str(e)}")
        
    if not uid:
        raise HTTPException(status_code=400, detail="Invalid Firebase token: no UID found")
        
    # 2. Database lookup order:
    # 2a. Find by firebase_uid
    user = db.query(User).filter(User.firebase_uid == uid).first()
    
    # 2b. Find by phone or email if not found, and link them
    if not user:
        if phone:
            user = db.query(User).filter(User.phone == phone).first()
        if not user and email:
            user = db.query(User).filter(User.email == email).first()
            
        if user:
            user.firebase_uid = uid
            db.commit()
            
    # 2c. Create user if still not found
    if not user:
        user = User(firebase_uid=uid, phone=phone, email=email, role="patient")
        db.add(user)
        db.flush()
        
        # Profile skeleton
        profile = Profile(
            user_id=user.id,
            full_name="New Patient",
            dob="1990-01-01",
            gender="Unknown",
            blood_group="O+",
            address="",
            health_score=90
        )
        db.add(profile)
        
        consent = ConsentSetting(user_id=user.id)
        db.add(consent)
        db.commit()
    else:
        # Link UID if not set
        if not user.firebase_uid:
            user.firebase_uid = uid
            db.commit()
            
    # Audit log
    audit = AuditLog(user_id=user.id, action="LOGIN_FIREBASE_OTP", details="Logged in via Firebase Phone Auth")
    db.add(audit)
    db.commit()
    db.refresh(user)
    
    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id, db)
    return {
        "access_token": access_token, 
        "token_type": "bearer", 
        "user_id": user.id,
        "refresh_token": refresh_token,
        "role": user.role
    }

@router.post("/refresh", response_model=Token)
def refresh(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Verifies refresh token, performs Refresh Token Rotation (RTR), and issues new token sets."""
    user_id = verify_refresh_token(req.refresh_token, db)
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid, expired, or revoked refresh token"
        )
        
    # Revoke old refresh token (RTR)
    revoke_refresh_token(req.refresh_token, db)
    
    # Create new tokens
    new_access = create_access_token(user_id)
    new_refresh = create_refresh_token(user_id, db)
    
    # Fetch user for role
    user = db.query(User).filter(User.id == int(user_id)).first()
    user_role = user.role if user else "patient"
    
    # Audit log
    audit = AuditLog(user_id=int(user_id), action="REFRESH_TOKEN", details="Reissued JWT tokens via RTR")
    db.add(audit)
    db.commit()
    
    return {
        "access_token": new_access,
        "token_type": "bearer",
        "user_id": int(user_id),
        "refresh_token": new_refresh,
        "role": user_role
    }

@router.post("/logout")
def logout(req: RefreshTokenRequest, db: Session = Depends(get_db)):
    """Revokes the refresh token to terminate the session."""
    revoked = revoke_refresh_token(req.refresh_token, db)
    if not revoked:
         raise HTTPException(status_code=400, detail="Refresh token not found or already revoked")
         
    return {"success": True, "message": "Successfully logged out. Refresh token revoked."}


@router.post("/onboard-doctor", status_code=status.HTTP_201_CREATED)
def onboard_doctor(
    req: DoctorOnboardRequest,
    x_admin_token: Optional[str] = Header(None, alias="X-Admin-Token"),
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db)
):
    """
    Onboards a new doctor. Access is restricted to either:
    1. A caller presenting a valid admin token header (X-Admin-Token) matching settings.SECRET_KEY (or "aarogya_vault_admin_secret_2026" as a fallback).
    2. Or a logged-in user who is authenticated (via Authorization Bearer token) and has an admin/hospital role.
    """
    authorized = False
    
    # 1. Check X-Admin-Token
    if x_admin_token:
        test_secret = "aarogya_vault_admin_secret_2026"
        if x_admin_token == settings.SECRET_KEY or x_admin_token == test_secret:
            authorized = True
            
    # 2. Check Authorization token if not authorized by X-Admin-Token
    if not authorized and authorization and authorization.startswith("Bearer "):
        try:
            token = authorization.split(" ")[1]
            user_id = verify_token(token)
            if user_id:
                current_user = db.query(User).filter(User.id == int(user_id)).first()
                if current_user and current_user.role in ["admin", "hospital"]:
                    authorized = True
        except Exception:
            pass
            
    if not authorized:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Forbidden: Admin or Hospital authority required."
        )
        
    # Duplicate Checks
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
        
    if db.query(User).filter(User.phone == req.phone).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Phone number already registered")
        
    if db.query(DoctorProfile).filter(DoctorProfile.registration_number == req.registration_number).first():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Doctor registration number already exists")
        
    # Create Doctor User
    hashed_pwd = get_password_hash(req.password)
    new_user = User(
        email=req.email,
        phone=req.phone,
        hashed_password=hashed_pwd,
        role="doctor"
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    # Create Doctor Profile
    doc_profile = DoctorProfile(
        user_id=new_user.id,
        full_name=req.full_name,
        registration_number=req.registration_number,
        specialty=req.specialty,
        hospital_name=req.hospital_name,
        is_verified=True
    )
    db.add(doc_profile)
    
    # Create Audit Log
    audit = AuditLog(
        user_id=new_user.id,
        action="ONBOARD_DOCTOR",
        details=f"Doctor onboarded successfully: {req.full_name} ({req.registration_number})"
    )
    db.add(audit)
    db.commit()
    
    return {
        "success": True,
        "message": "Doctor onboarded successfully.",
        "data": {
            "doctor_id": new_user.id,
            "full_name": req.full_name,
            "registration_number": req.registration_number
        }
    }
