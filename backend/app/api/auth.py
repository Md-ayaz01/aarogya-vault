from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import Optional
import random
from pydantic import BaseModel

from app.core.database import get_db
from app.core.security import get_password_hash, verify_password, create_access_token, verify_token
from app.models import User, Profile, AuditLog, ConsentSetting
from app.schemas import UserCreate, UserLogin, Token, ProfileCreate
from app.core.config import settings
from fastapi.security import OAuth2PasswordBearer


router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    user_id = verify_token(token)
    if user_id is None:
        raise credentials_exception
    user = db.query(User).filter(User.id == int(user_id)).first()
    if user is None:
        raise credentials_exception
    return user

@router.post("/register", response_model=Token)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    if not user_in.email and not user_in.phone:
        raise HTTPException(status_code=400, detail="Either email or phone must be provided")
    
    # Check duplicate
    if user_in.email:
        db_user = db.query(User).filter(User.email == user_in.email).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Email already registered")
    if user_in.phone:
        db_user = db.query(User).filter(User.phone == user_in.phone).first()
        if db_user:
            raise HTTPException(status_code=400, detail="Phone already registered")
            
    try:
        # Create user
        raw_password = (user_in.password or "")[:50]
        hashed_pwd = get_password_hash(raw_password) if raw_password else None
        new_user = User(
            email=user_in.email,
            phone=user_in.phone,
            hashed_password=hashed_pwd,
            role="patient"
        )
        db.add(new_user)
        db.flush()
        
        # Create profile skeleton
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
        
        # Create default consent settings
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
    user = None
    if login_in.email:
        user = db.query(User).filter(User.email == login_in.email).first()
    elif login_in.phone:
        user = db.query(User).filter(User.phone == login_in.phone).first()
        
    if not user:
        raise HTTPException(status_code=400, detail="Invalid email/phone or password")
        
    # Check password or biometric
    if login_in.biometric_token:
        # Check matching hash (stored previously on device setup)
        if user.biometric_token_hash != login_in.biometric_token:
            raise HTTPException(status_code=400, detail="Biometric authentication failed")
    elif login_in.password:
        if not verify_password(login_in.password, user.hashed_password):
            raise HTTPException(status_code=400, detail="Invalid email/phone or password")
    else:
        # Simulated OTP Login (Any password accepted for mock testing/OTP code flow)
        pass

    # Log audit
    audit = AuditLog(user_id=user.id, action="LOGIN", details=f"User logged in successfully")
    db.add(audit)
    db.commit()

    token = create_access_token(user.id)
    return {"access_token": token, "token_type": "bearer", "user_id": user.id}

@router.post("/biometric-setup")
def setup_biometrics(biometric_token: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    current_user.biometric_token_hash = biometric_token
    db.commit()
    audit = AuditLog(user_id=current_user.id, action="BIOMETRIC_SETUP", details="Biometrics set up successfully")
    db.add(audit)
    db.commit()
    return {"status": "success", "message": "Biometrics linked successfully"}

@router.post("/aadhaar-verify")
def verify_aadhaar(aadhaar_num: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if len(aadhaar_num) != 12 or not aadhaar_num.isdigit():
        raise HTTPException(status_code=400, detail="Invalid Aadhaar number. Must be 12 digits.")
        
    # In a real integration this sends request to UIDAI. Here we update profile.
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    masked_aadhaar = f"XXXX XXXX {aadhaar_num[-4:]}"
    if profile:
        profile.aadhaar_number = masked_aadhaar
        db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="AADHAAR_VERIFY", details=f"Aadhaar verified: {masked_aadhaar}")
    db.add(audit)
    db.commit()
    
    return {"status": "success", "message": "Aadhaar verified and linked successfully", "aadhaar": masked_aadhaar}

class OTPSendRequest(BaseModel):
    phone: str

class OTPVerifyRequest(BaseModel):
    phone: str
    code: str

@router.get("/session-check")
def check_session(current_user: User = Depends(get_current_user)):
    return {"status": "valid", "user_id": current_user.id}

@router.post("/send-otp")
def send_otp(req: OTPSendRequest, db: Session = Depends(get_db)):
    phone = req.phone.strip()
    if not phone:
        raise HTTPException(status_code=400, detail="Phone number is required")
    
    # Check if user exists
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        # Create user skeleton
        user = User(phone=phone)
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Create profile skeleton
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
        
        # Create default consent settings
        consent = ConsentSetting(user_id=user.id)
        db.add(consent)
        db.commit()
    else:
        # Ensure consent settings exist even for older users
        consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == user.id).first()
        if not consent:
            consent = ConsentSetting(user_id=user.id)
            db.add(consent)
            db.commit()

    # Generate a random 6 digit code
    otp = str(random.randint(100000, 999999))
    user.otp_code = otp
    user.otp_expiry = datetime.utcnow() + timedelta(minutes=5)
    db.commit()
    
    # Send via Twilio if credentials are provided in settings
    if settings.TWILIO_ACCOUNT_SID and settings.TWILIO_AUTH_TOKEN:
        try:
            from twilio.rest import Client
            client = Client(settings.TWILIO_ACCOUNT_SID, settings.TWILIO_AUTH_TOKEN)
            client.messages.create(
                body=f"Your Aarogya Vault secure verification OTP code is: {otp}. It expires in 5 minutes.",
                from_=settings.TWILIO_PHONE_NUMBER,
                to=phone
            )
            print(f"[OTP SERVICE] Real SMS sent to {phone} via Twilio.")
        except Exception as e:
            print(f"[OTP SERVICE] Twilio send failed: {e}")
            
    # Print it to the backend log/stdout
    print(f"\n[OTP SERVICE] Sent OTP {otp} to {phone}\n")
    
    return {"status": "success", "message": "OTP sent successfully", "demo_otp": otp}


@router.post("/verify-otp", response_model=Token)
def verify_otp(req: OTPVerifyRequest, db: Session = Depends(get_db)):
    phone = req.phone.strip()
    code = req.code.strip()
    
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        raise HTTPException(status_code=400, detail="User not found")
        
    if not user.otp_code or user.otp_code != code:
        raise HTTPException(status_code=400, detail="Invalid OTP code")
        
    if datetime.utcnow() > user.otp_expiry:
        raise HTTPException(status_code=400, detail="OTP code has expired")
        
    # Clear OTP
    user.otp_code = None
    user.otp_expiry = None
    
    # Log audit
    audit = AuditLog(user_id=user.id, action="LOGIN_OTP", details="Logged in via OTP")
    db.add(audit)
    db.commit()
    
    token = create_access_token(user.id)
    return {"access_token": token, "token_type": "bearer", "user_id": user.id}

class FirebaseVerifyRequest(BaseModel):
    id_token: str

@router.post("/verify-firebase-otp", response_model=Token)
def verify_firebase_otp(req: FirebaseVerifyRequest, db: Session = Depends(get_db)):
    phone = None
    # Check for mock token first (e.g., mock_token_+919876543210)
    if req.id_token.startswith("mock_token_"):
        phone = req.id_token.replace("mock_token_", "").strip()
        print(f"[AUTH] Mock Firebase token verified fallback: {phone}")
    else:
        try:
            import firebase_admin
            from firebase_admin import auth as firebase_auth_admin
            
            # Initialize firebase_admin if not already initialized
            try:
                firebase_admin.get_app()
            except ValueError:
                firebase_admin.initialize_app()
                
            decoded_token = firebase_auth_admin.verify_id_token(req.id_token)
            phone = decoded_token.get("phone_number")
        except Exception as e:
            # Fallback check for testing in case firebase is not configured/offline
            if "mock" in req.id_token.lower() or req.id_token.startswith("+"):
                phone = req.id_token.strip()
                print(f"[AUTH] Firebase error, falling back to direct token as phone: {phone}")
            else:
                raise HTTPException(status_code=400, detail=f"Firebase verification failed: {str(e)}")
        
    if not phone:
        raise HTTPException(status_code=400, detail="Invalid Firebase token: no phone number found")
        
    # Find or create user
    user = db.query(User).filter(User.phone == phone).first()
    if not user:
        user = User(phone=phone)
        db.add(user)
        db.commit()
        db.refresh(user)
        
        # Create profile skeleton
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
        
        # Create default consent settings
        consent = ConsentSetting(user_id=user.id)
        db.add(consent)
        db.commit()
    else:
        # Ensure consent settings exist
        consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == user.id).first()
        if not consent:
            consent = ConsentSetting(user_id=user.id)
            db.add(consent)
            db.commit()
            
    # Log audit
    audit = AuditLog(user_id=user.id, action="LOGIN_FIREBASE_OTP", details="Logged in via Firebase Phone Auth")
    db.add(audit)
    db.commit()
    
    token = create_access_token(user.id)
    return {"access_token": token, "token_type": "bearer", "user_id": user.id}


