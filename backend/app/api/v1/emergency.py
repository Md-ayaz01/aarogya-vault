import secrets
import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Dict, Any

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Profile, MedicalHistory, MedicineReminder, AuditLog, QRToken, EmergencyContact
from app.schemas.schemas import EmergencyAccessResponse
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_emergency")
router = APIRouter(tags=["emergency"])

def get_clean_domain() -> str:
    """Helper to extract backend root domain for public URL construction."""
    domain = settings.API_BASE_URL
    if not domain or "127.0.0.1" in domain or "localhost" in domain:
        return "https://aarogya-vault.onrender.com"
    if domain.endswith("/api/v1"):
        domain = domain[:-7]
    elif domain.endswith("/api/v1/"):
        domain = domain[:-8]
    return domain

@router.get("/qr")
def get_qr_token(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches or generates the active secure 256-bit QR token for a user."""
    qr_token = db.query(QRToken).filter(
        QRToken.user_id == current_user.id, 
        QRToken.is_active == True
    ).first()
    
    if not qr_token:
        # Generate cryptographically secure 256-bit token (32 bytes url-safe base64)
        token = secrets.token_urlsafe(32)
        qr_token = QRToken(
            user_id=current_user.id,
            token=token,
            is_active=True
        )
        db.add(qr_token)
        db.commit()
        db.refresh(qr_token)
        
    domain = get_clean_domain()
    qr_url = f"{domain}/api/v1/emergency/access/{qr_token.token}"
    return {
        "success": True, 
        "data": {
            "qr_token": qr_token.token, 
            "qr_url": qr_url
        }
    }

@router.post("/qr/regenerate")
def regenerate_qr_token(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Rotates/regenerates user's QR token, invalidating all previous tokens."""
    # Invalidate previous active tokens
    db.query(QRToken).filter(
        QRToken.user_id == current_user.id,
        QRToken.is_active == True
    ).update({"is_active": False, "updated_at": datetime.now(timezone.utc)})
    db.commit()
    
    # Generate new 256-bit token
    token = secrets.token_urlsafe(32)
    new_qr = QRToken(
        user_id=current_user.id,
        token=token,
        is_active=True
    )
    db.add(new_qr)
    db.commit()
    db.refresh(new_qr)
    
    # Log audit trail
    audit = AuditLog(user_id=current_user.id, action="REGENERATE_QR", details="Regenerated emergency QR token.")
    db.add(audit)
    db.commit()
    
    domain = get_clean_domain()
    qr_url = f"{domain}/api/v1/emergency/access/{new_qr.token}"
    return {
        "success": True,
        "data": {
            "qr_token": new_qr.token,
            "qr_url": qr_url
        }
    }

@router.get("/emergency/access/{token}", response_model=EmergencyAccessResponse)
def public_emergency_access(token: str, db: Session = Depends(get_db)):
    """Publicly accessible unauthenticated endpoint for emergency personnel to view patient vitals."""
    # Validate token lifecycle
    qr_token = db.query(QRToken).filter(
        QRToken.token == token,
        QRToken.is_active == True
    ).first()
    
    if not qr_token:
        raise HTTPException(status_code=404, detail="Invalid, expired, or deactivated emergency QR token.")
        
    user_id = qr_token.user_id
    profile = db.query(Profile).filter(Profile.user_id == user_id).first()
    if not profile:
        raise HTTPException(status_code=404, detail="Patient profile not found.")
        
    # Query clinical metadata
    records = db.query(MedicalHistory).filter(MedicalHistory.user_id == user_id).all()
    allergies = [r.description or r.title for r in records if r.type == "allergy"]
    conditions = [r.description or r.title for r in records if r.type == "condition"]
    
    # Get active medications
    reminders = db.query(MedicineReminder).filter(MedicineReminder.user_id == user_id, MedicineReminder.is_active == True).all()
    current_meds = [f"{r.medicine_name} {r.dosage}" for r in reminders]
    
    # Get emergency contact details
    contacts = db.query(EmergencyContact).filter(EmergencyContact.user_id == user_id).all()
    contact_list = [f"{c.name} ({c.phone}) - {c.relation or 'Contact'}" for c in contacts]
    # Fallback to profile contact if table is empty
    if not contact_list:
        contact_list = [f"{profile.emergency_contact_name} ({profile.emergency_contact_phone})"]
        
    # Log emergency access audit
    audit = AuditLog(
        user_id=user_id, 
        action="EMERGENCY_QR_ACCESS", 
        details=f"Public emergency portal accessed via secure token: {token[:8]}..."
    )
    db.add(audit)
    db.commit()
    
    # Compute age dynamically
    age = "Unknown"
    if profile.dob:
        try:
            birth_year = int(profile.dob.split("-")[0])
            age = f"{datetime.now().year - birth_year} Years"
        except Exception:
            pass

    return EmergencyAccessResponse(
        patient_name=profile.full_name,
        age=age,
        blood_group=profile.blood_group,
        allergies=allergies if allergies else ["None"],
        chronic_diseases=conditions if conditions else ["None"],
        current_medicines=current_meds if current_meds else ["None"],
        emergency_contact=", ".join(contact_list),
        aadhaar_status="Verified" if profile.aadhaar_number else "Not Linked",
        last_updated=qr_token.updated_at.strftime("%Y-%m-%d %H:%M UTC")
    )
