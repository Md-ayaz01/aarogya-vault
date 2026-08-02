from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, DoctorProfile
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/doctors", tags=["hospital_doctors"])

@router.get("")
def list_hospital_doctors(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.doctor.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.doctor.manage'"
        )
    doctors = service.repo.list_doctors()
    res = []
    for d in doctors:
        res.append({
            "id": d.id,
            "user_id": d.user_id,
            "full_name": d.full_name,
            "registration_number": d.registration_number,
            "specialty": d.specialty,
            "hospital_name": d.hospital_name,
            "is_verified": d.is_verified,
            "availability_status": "Available",
            "schedule": "09:00 AM - 05:00 PM"
        })
    return {"success": True, "data": res}

from pydantic import BaseModel
from typing import Optional

class DoctorCreateRequest(BaseModel):
    full_name: str
    specialty: str
    registration_number: str
    department_name: Optional[str] = "General Medicine"

@router.post("")
def add_hospital_doctor(
    payload: DoctorCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.doctor.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.doctor.manage'"
        )
    doc = service.repo.create_doctor_profile(
        full_name=payload.full_name,
        specialty=payload.specialty,
        registration_number=payload.registration_number,
        department_name=payload.department_name or "General Medicine"
    )
    return {"success": True, "data": {"id": doc.id, "full_name": doc.full_name}}

