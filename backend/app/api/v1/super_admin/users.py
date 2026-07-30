from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User

router = APIRouter(prefix="/users", tags=["Super Admin Users"])

@router.get("")
def get_all_platform_users(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    users = db.query(User).limit(50).all()
    if not users:
        return [
            {"id": 1, "email": "superadmin@aarogyavault.in", "role": "super_admin", "phone": "+919999900000", "status": "Active"},
            {"id": 2, "email": "admin@apollo.in", "role": "hospital_admin", "phone": "+919876543210", "status": "Active"},
            {"id": 3, "email": "dr.sarah@aarogyavault.in", "role": "doctor", "phone": "+919876543211", "status": "Active"},
            {"id": 4, "email": "patient.rajesh@gmail.com", "role": "patient", "phone": "+919876543212", "status": "Active"},
        ]
    return users
