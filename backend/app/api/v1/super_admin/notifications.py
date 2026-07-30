from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/notifications", tags=["Super Admin Broadcast Notifications"])

@router.get("")
def get_broadcasts(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.get_broadcasts(current_user)

@router.post("")
def send_broadcast_notification(
    title: str = Body(..., embed=True),
    message: str = Body(..., embed=True),
    target_role: str = Body("all", embed=True),
    severity: str = Body("info", embed=True),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.send_broadcast(current_user, title, message, target_role, severity)
