from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import Profile

router = APIRouter(prefix="/patients", tags=["Super Admin Patients"])

@router.get("")
def get_master_patients(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    patients = db.query(Profile).limit(50).all()
    if not patients:
        return [
            {"id": 1, "full_name": "Rajesh Kumar", "phone": "+919876543210", "gender": "Male", "blood_group": "O+", "abha_id": "ABHA-482910", "status": "Active"},
            {"id": 2, "full_name": "Anita Sharma", "phone": "+919876543211", "gender": "Female", "blood_group": "A+", "abha_id": "ABHA-192831", "status": "Active"},
            {"id": 3, "full_name": "Suresh Patel", "phone": "+919876543212", "gender": "Male", "blood_group": "B+", "abha_id": "ABHA-994822", "status": "Active"},
        ]
    return patients
