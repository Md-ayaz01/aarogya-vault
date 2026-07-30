from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import RolePermission

router = APIRouter(prefix="/rbac", tags=["Super Admin RBAC"])

@router.get("")
def get_rbac_matrix(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    perms = db.query(RolePermission).all()
    if not perms:
        return [
            {"role_name": "super_admin", "permission_key": "super_admin.*"},
            {"role_name": "hospital_admin", "permission_key": "hospital.*"},
            {"role_name": "doctor", "permission_key": "doctor.*"},
            {"role_name": "patient", "permission_key": "patient.*"},
        ]
    return perms
