from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/api-keys", tags=["Super Admin API Management"])

@router.get("")
def get_api_keys_list(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.get_api_keys(current_user)
