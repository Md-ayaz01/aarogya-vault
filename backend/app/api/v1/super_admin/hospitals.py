from fastapi import APIRouter, Depends, Body
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/hospitals", tags=["Super Admin Hospitals"])

@router.get("")
def get_hospitals_approval(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.get_hospital_approvals(current_user)

@router.put("/{request_id}/status")
def update_hospital_status(
    request_id: int,
    status: str = Body(..., embed=True),
    notes: str = Body(None, embed=True),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.approve_reject_hospital(current_user, request_id, status, notes)
