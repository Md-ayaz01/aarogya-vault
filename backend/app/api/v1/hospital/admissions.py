from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/admissions", tags=["hospital_admissions"])

class AdmissionCreate(BaseModel):
    patient_id: int
    doctor_id: Optional[int] = None
    department_id: Optional[int] = None
    bed_id: Optional[int] = None
    admission_type: str = "IPD"
    notes: Optional[str] = None

@router.get("")
def list_admissions(
    status_filter: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.read"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.read'"
        )
    admissions = service.repo.list_admissions(status=status_filter)
    res = []
    for a in admissions:
        res.append({
            "id": a.id,
            "patient_id": a.patient_id,
            "patient_name": a.patient.profile.full_name if a.patient and a.patient.profile else f"Patient #{a.patient_id}",
            "doctor_name": a.doctor.doctor_profile.full_name if a.doctor and a.doctor.doctor_profile else "Unassigned",
            "department_name": a.department.name if a.department else "General",
            "bed_number": a.bed.bed_number if a.bed else "N/A",
            "admission_type": a.admission_type,
            "status": a.status,
            "admission_date": a.admission_date.strftime("%Y-%m-%d %H:%M") if a.admission_date else "",
            "notes": a.notes
        })
    return {"success": True, "data": res}

@router.post("")
def create_admission(
    payload: AdmissionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.write"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.write'"
        )
    admission = service.repo.create_admission(
        patient_id=payload.patient_id,
        doctor_id=payload.doctor_id,
        department_id=payload.department_id,
        bed_id=payload.bed_id,
        admission_type=payload.admission_type,
        notes=payload.notes
    )
    return {"success": True, "data": {"id": admission.id, "status": admission.status}}
