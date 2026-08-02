from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Profile
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/patients", tags=["hospital_patients"])

@router.get("")
def list_hospital_patients(
    search: Optional[str] = Query(None),
    skip: int = 0,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.read"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.read'"
        )
    patients = service.repo.list_patients(search=search, skip=skip, limit=limit)
    res = []
    for p in patients:
        profile = p.profile
        res.append({
            "id": p.id,
            "phone": p.phone,
            "email": p.email,
            "full_name": profile.full_name if profile else "Patient",
            "blood_group": profile.blood_group if profile else "N/A",
            "gender": profile.gender if profile else "N/A",
            "dob": profile.dob if profile else "N/A",
            "health_score": profile.health_score if profile else 90
        })
    return {"success": True, "data": res}

from pydantic import BaseModel

class PatientRegisterRequest(BaseModel):
    full_name: str
    phone: str
    abha_id: Optional[str] = None

@router.post("")
def register_patient(
    payload: PatientRegisterRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.write"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.write'"
        )
    user = service.repo.create_patient_user(
        full_name=payload.full_name,
        phone=payload.phone,
        abha_id=payload.abha_id
    )
    return {"success": True, "data": {"id": user.id, "phone": user.phone}}

@router.delete("/{patient_id}")
def delete_patient(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.write"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.write'"
        )
    user = db.query(User).filter(User.id == patient_id, User.role == "patient").first()
    if not user:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # Delete all associated records with correct column references
    from app.models.models import (
        Profile, ConsentSetting, Notification, MedicalHistory, LabReport,
        Prescription, Appointment, Admission, DoctorPatientAccess, AuditLog,
        AIChatMessage, MedicineReminder, EmergencyContact
    )
    db.query(Profile).filter(Profile.user_id == patient_id).delete(synchronize_session=False)
    db.query(ConsentSetting).filter(ConsentSetting.user_id == patient_id).delete(synchronize_session=False)
    db.query(Notification).filter(Notification.user_id == patient_id).delete(synchronize_session=False)
    db.query(MedicalHistory).filter(MedicalHistory.user_id == patient_id).delete(synchronize_session=False)
    db.query(LabReport).filter(LabReport.user_id == patient_id).delete(synchronize_session=False)
    db.query(Prescription).filter(Prescription.user_id == patient_id).delete(synchronize_session=False)
    db.query(Appointment).filter(Appointment.user_id == patient_id).delete(synchronize_session=False)
    db.query(Admission).filter(Admission.patient_id == patient_id).delete(synchronize_session=False)
    db.query(DoctorPatientAccess).filter(DoctorPatientAccess.patient_id == patient_id).delete(synchronize_session=False)
    db.query(AuditLog).filter(AuditLog.user_id == patient_id).delete(synchronize_session=False)
    db.query(AIChatMessage).filter(AIChatMessage.user_id == patient_id).delete(synchronize_session=False)
    db.query(MedicineReminder).filter(MedicineReminder.user_id == patient_id).delete(synchronize_session=False)
    db.query(EmergencyContact).filter(EmergencyContact.user_id == patient_id).delete(synchronize_session=False)

    db.delete(user)
    db.commit()
    return {"success": True, "message": f"Patient #{patient_id} deleted"}

