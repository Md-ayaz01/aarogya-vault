from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/notifications", tags=["hospital_notifications"])

class NotificationCreate(BaseModel):
    title: str
    body: str
    type: Optional[str] = "info"

@router.get("")
def list_hospital_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    notifs = service.repo.list_notifications()
    res = []
    for n in notifs:
        res.append({
            "id": n.id,
            "title": n.title,
            "body": n.body,
            "type": n.type,
            "time": n.created_at.strftime("%Y-%m-%d %H:%M") if n.created_at else "Just now"
        })
    return {"success": True, "data": res}

@router.post("")
def create_hospital_notification(
    payload: NotificationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    notif = service.repo.create_notification(
        title=payload.title,
        body=payload.body,
        notification_type=payload.type or "info"
    )
    return {"success": True, "data": {"id": notif.id, "title": notif.title}}
