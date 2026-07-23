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

@router.get("/audit-logs")
def get_consent_audit_logs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches user audit history logging record access and authentication requests."""
    logs = db.query(AuditLog).filter(AuditLog.user_id == current_user.id).order_by(AuditLog.created_at.desc()).all()
    # Format to simple JSON list for client presentation
    serialized_logs = []
    for log in logs:
        serialized_logs.append({
            "id": log.id,
            "action": log.action,
            "timestamp": log.created_at.strftime("%Y-%m-%d %H:%M:%S"),
            "details": log.details or ""
        })
    return serialized_logs
