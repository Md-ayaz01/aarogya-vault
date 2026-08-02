from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Appointment
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/appointments", tags=["hospital_appointments"])

@router.get("")
def list_hospital_appointments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    appointments = db.query(Appointment).order_by(Appointment.created_at.desc()).all()
    res = []
    for a in appointments:
        res.append({
            "id": a.id,
            "patient_id": a.user_id,
            "patient_name": a.user.profile.full_name if a.user and a.user.profile else f"Patient #{a.user_id}",
            "doctor_id": a.doctor_id,
            "doctor_name": a.doctor_name,
            "specialty": a.specialty,
            "date_time": a.date_time,
            "status": a.status
        })
    return {"success": True, "data": res}

from pydantic import BaseModel
from typing import Optional

class AppointmentCreateRequest(BaseModel):
    patient_name: str
    doctor_name: str
    specialty: Optional[str] = "General"
    time_slot: Optional[str] = "10:30 AM"

@router.post("")
def book_hospital_appointment(
    payload: AppointmentCreateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    appt = service.repo.create_appointment(
        patient_name=payload.patient_name,
        doctor_name=payload.doctor_name,
        specialty=payload.specialty or "General",
        time_slot=payload.time_slot or "10:30 AM"
    )
    return {"success": True, "data": {"id": appt.id, "status": appt.status}}

