from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/settings", tags=["hospital_settings"])

@router.get("/audit-logs")
def get_hospital_audit_logs(
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.audit.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.audit.view'"
        )
    logs = service.repo.list_audit_logs(limit=limit)
    res = []
    for l in logs:
        res.append({
            "id": l.id,
            "user_id": l.user_id,
            "action": l.action,
            "details": l.details,
            "endpoint": l.endpoint,
            "created_at": l.created_at.strftime("%Y-%m-%d %H:%M:%S") if l.created_at else ""
        })
    return {"success": True, "data": res}
