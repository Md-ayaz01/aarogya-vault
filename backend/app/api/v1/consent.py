from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, ConsentSetting, AuditLog
from app.schemas.schemas import ConsentSettingResponse, ConsentSettingUpdate

router = APIRouter(prefix="/consent", tags=["consent"])

@router.get("", response_model=ConsentSettingResponse)
def get_consent_settings(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches user privacy consent configuration."""
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if not consent:
        consent = ConsentSetting(user_id=current_user.id)
        db.add(consent)
        db.commit()
        db.refresh(consent)
    return consent

@router.put("", response_model=ConsentSettingResponse)
def update_consent_settings(consent_in: ConsentSettingUpdate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Updates user privacy consent configuration and logs changes."""
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if not consent:
        consent = ConsentSetting(user_id=current_user.id, **consent_in.dict())
        db.add(consent)
    else:
        for field, value in consent_in.dict(exclude_unset=True).items():
            setattr(consent, field, value)
            
    db.commit()
    db.refresh(consent)
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="UPDATE_CONSENT", details="Consent privacy settings updated.")
    db.add(audit)
    db.commit()
    
    return consent

from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timedelta, timezone
from app.models.models import DoctorPatientAccess

class GrantDoctorAccessRequest(BaseModel):
    doctor_id: int
    expires_in_hours: Optional[int] = 24

@router.get("/doctors-list")
def list_available_doctors(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Lists verified doctors for patient consent selection."""
    from app.models.models import DoctorProfile
    doc_profiles = db.query(DoctorProfile).filter(DoctorProfile.is_verified == True).all()
    results = []
    for dp in doc_profiles:
        results.append({
            "doctor_id": dp.user_id,
            "full_name": dp.full_name,
            "specialty": dp.specialty or "General Practice",
            "hospital_name": dp.hospital_name or "Central Hospital",
            "registration_number": dp.registration_number or ""
        })
    return results

@router.get("/active-grants")
def get_active_consent_grants(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Lists doctors who currently have active consent access granted by this patient."""
    from app.models.models import DoctorPatientAccess, DoctorProfile
    now = datetime.now(timezone.utc)
    accesses = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.patient_id == current_user.id,
        DoctorPatientAccess.is_active == True,
        DoctorPatientAccess.revoked_at == None
    ).all()
    results = []
    for acc in accesses:
        try:
            if acc.expires_at:
                exp = acc.expires_at if getattr(acc.expires_at, 'tzinfo', None) else acc.expires_at.replace(tzinfo=timezone.utc)
                if exp < now:
                    continue
            dp = db.query(DoctorProfile).filter(DoctorProfile.user_id == acc.doctor_id).first()
            g_at = getattr(acc, 'granted_at', None) or getattr(acc, 'created_at', None)
            granted_str = g_at.strftime("%Y-%m-%d %H:%M:%S") if g_at else ""
            results.append({
                "doctor_id": acc.doctor_id,
                "doctor_name": dp.full_name if dp else f"Doctor {acc.doctor_id}",
                "specialty": dp.specialty if (dp and dp.specialty) else "General Practice",
                "access_type": acc.access_type or "consent",
                "granted_at": granted_str
            })
        except Exception:
            continue
    return results

@router.post("/grant-doctor-access")
def grant_doctor_access(
    req: GrantDoctorAccessRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Allows a patient in the Patient App to grant explicit consent access to a specific doctor."""
    expires_at = None
    if req.expires_in_hours:
        expires_at = datetime.now(timezone.utc) + timedelta(hours=req.expires_in_hours)
        
    access = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.patient_id == current_user.id,
        DoctorPatientAccess.doctor_id == req.doctor_id
    ).first()
    
    if not access:
        access = DoctorPatientAccess(
            patient_id=current_user.id,
            doctor_id=req.doctor_id,
            access_type="consent",
            is_active=True,
            expires_at=expires_at
        )
        db.add(access)
    else:
        access.is_active = True
        access.revoked_at = None
        access.expires_at = expires_at
        
    audit = AuditLog(
        user_id=current_user.id,
        action="GRANT_DOCTOR_CONSENT",
        details=f"Patient {current_user.id} granted consent access to doctor {req.doctor_id}."
    )
    db.add(audit)
    db.commit()
    return {"success": True, "message": "Doctor access consent granted successfully."}

@router.post("/revoke-doctor-access")
def revoke_doctor_access(
    doctor_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Allows a patient in the Patient App to revoke consent access for a specific doctor."""
    access = db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.patient_id == current_user.id,
        DoctorPatientAccess.doctor_id == doctor_id
    ).first()
    
    if access:
        access.is_active = False
        access.revoked_at = datetime.now(timezone.utc)
        db.commit()
        
    audit = AuditLog(
        user_id=current_user.id,
        action="REVOKE_DOCTOR_CONSENT",
        details=f"Patient {current_user.id} revoked consent access for doctor {doctor_id}."
    )
    db.add(audit)
    db.commit()
    return {"success": True, "message": "Doctor access consent revoked successfully."}

@router.get("/audit-logs")
def get_consent_audit_logs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches user audit history logging record access and authentication requests."""
    logs = db.query(AuditLog).filter(AuditLog.user_id == current_user.id).order_by(AuditLog.created_at.desc()).all()
    serialized_logs = []
    for log in logs:
        serialized_logs.append({
            "id": log.id,
            "action": log.action,
            "timestamp": log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "details": log.details or ""
        })
    return serialized_logs
