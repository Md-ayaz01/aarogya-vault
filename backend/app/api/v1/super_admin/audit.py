from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/audit", tags=["Super Admin Audit"])

@router.get("")
def get_audit_trail(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.get_platform_audit_logs(current_user)
