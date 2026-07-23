from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import Notification, User, AuditLog
from app.schemas import NotificationResponse

router = APIRouter(prefix="/notifications", tags=["notifications"])

@router.get("/", response_model=List[NotificationResponse])
def list_notifications(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    notes = db.query(Notification).filter(Notification.user_id == current_user.id).order_by(Notification.timestamp.desc()).all()
    return notes

@router.post("/", response_model=NotificationResponse)
def create_notification(
    title: str,
    body: str,
    type: str = "alert",
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    notif = Notification(
        user_id=current_user.id,
        title=title,
        body=body,
        type=type
    )
    db.add(notif)
    db.commit()
    db.refresh(notif)
    audit = AuditLog(user_id=current_user.id, action="CREATE_NOTIFICATION", details=f"Notification '{title}' created")
    db.add(audit)
    db.commit()
    return notif

@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def mark_notification_read(notification_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    notif = db.query(Notification).filter(Notification.id == notification_id, Notification.user_id == current_user.id).first()
    if not notif:
        raise HTTPException(status_code=404, detail="Notification not found")
    notif.is_read = True
    db.commit()
    db.refresh(notif)
    audit = AuditLog(user_id=current_user.id, action="MARK_NOTIFICATION_READ", details=f"Notification ID {notification_id} marked read")
    db.add(audit)
    db.commit()
    return notif
