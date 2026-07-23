from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, ConsentSetting, AuditLog
from app.schemas import ConsentSettingResponse, ConsentSettingUpdate

router = APIRouter(prefix="/consent", tags=["consent"])

@router.get("", response_model=ConsentSettingResponse)
def get_consent_settings(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if not consent:
        consent = ConsentSetting(user_id=current_user.id)
        db.add(consent)
        db.commit()
        db.refresh(consent)
    return consent

@router.put("", response_model=ConsentSettingResponse)
def update_consent_settings(
    consent_in: ConsentSettingUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == current_user.id).first()
    if not consent:
        consent = ConsentSetting(user_id=current_user.id)
        db.add(consent)
        db.commit()
        db.refresh(consent)
        
    for field, value in consent_in.dict(exclude_unset=True).items():
        setattr(consent, field, value)
        
    db.commit()
    db.refresh(consent)
    
    # Log audit
    audit = AuditLog(user_id=current_user.id, action="UPDATE_CONSENT", details="User privacy consent settings updated")
    db.add(audit)
    db.commit()
    
    return consent

@router.get("/audit-logs", response_model=List[dict])
def get_audit_logs(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    logs = db.query(AuditLog).filter(AuditLog.user_id == current_user.id).order_by(AuditLog.timestamp.desc()).all()
    result = []
    for log in logs:
        result.append({
            "id": log.id,
            "action": log.action,
            "timestamp": log.timestamp.isoformat(),
            "details": log.details
        })
    return result
