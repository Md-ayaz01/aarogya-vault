from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Prescription, DoctorProfile
from app.services.doctor_service import doctor_service

router = APIRouter(prefix="/doctor", tags=["doctor"])

# Pydantic Schemas for Doctor Requests
class DoctorPrescriptionItem(BaseModel):
    medicine_name: str
    dosage: str
    instruction: str

class DoctorPrescriptionCreate(BaseModel):
    patient_id: int
    diagnosis: Optional[str] = None
    notes: Optional[str] = None
    items: List[DoctorPrescriptionItem]

class DoctorAICopilotRequest(BaseModel):
    patient_id: int
    prompt: str
    type: str  # summary, interaction, soap, explanation

class EmergencyAccessRequest(BaseModel):
    qr_token: str

# Dependency to enforce doctor role
def get_current_doctor(current_user: User = Depends(get_current_user)) -> User:
    if current_user.role != "doctor":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Doctor role required."
        )
    return current_user

def get_verified_doctor(
    current_user: User = Depends(get_current_doctor),
    db: Session = Depends(get_db),
) -> User:
    profile = db.query(DoctorProfile).filter(
        DoctorProfile.user_id == current_user.id,
        DoctorProfile.is_verified == True,
    ).first()
    if not profile:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: verified doctor profile required."
        )
    return current_user

@router.get("/dashboard")
def get_dashboard(
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Returns doctor dashboard overview (Today's appts, alerts, recent patients, quick actions).
    """
    return doctor_service.get_dashboard(db, current_doctor)

@router.get("/profile")
def get_doctor_profile(
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Returns the logged-in doctor's own professional profile (DoctorProfile).
    """
    from app.models.models import DoctorProfile
    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == current_doctor.id).first()
    if not doc_profile:
        return {
            "full_name": "Dr.",
            "specialty": "Specialist",
            "hospital_name": "Hospital",
            "registration_number": "N/A",
            "email": current_doctor.email,
            "phone": current_doctor.phone,
            "is_verified": False
        }
    return {
        "full_name": doc_profile.full_name,
        "specialty": doc_profile.specialty,
        "hospital_name": doc_profile.hospital_name,
        "registration_number": doc_profile.registration_number,
        "email": current_doctor.email,
        "phone": current_doctor.phone,
        "is_verified": bool(doc_profile.is_verified)
    }

@router.get("/patients/search")
def search_patients(
    query: str = Query(..., min_length=1),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=50),
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Searches patients database by ID, phone, or name, returning minimal details.
    """
    return doctor_service.search_patients(db, current_doctor.id, query, page, limit)

@router.get("/patients/{patient_id}/profile")
def get_patient_profile(
    patient_id: int,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Fetches patient's demographics. Enforces server-side authorization check.
    """
    return doctor_service.get_patient_profile(db, current_doctor.id, patient_id)

@router.get("/patients/{patient_id}/timeline")
def get_patient_timeline(
    patient_id: int,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Chronological medical history, diagnostic reports, and prescriptions. Enforces access check.
    """
    return doctor_service.get_patient_timeline(db, current_doctor.id, patient_id)

@router.get("/patients/{patient_id}/reports")
def get_patient_reports(
    patient_id: int,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Fetches patient diagnostic reports list. Enforces access check.
    """
    return doctor_service.get_patient_reports(db, current_doctor.id, patient_id)

@router.post("/prescriptions")
def create_prescription(
    prescription_in: DoctorPrescriptionCreate,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Saves a new prescription record and items transactionally. Audits creation.
    """
    prescription = doctor_service.create_prescription(db, current_doctor, prescription_in)
    return {"success": True, "data": {"id": prescription.id}, "message": "Prescription created successfully."}

@router.post("/ai/copilot")
def get_ai_copilot(
    copilot_req: DoctorAICopilotRequest,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    AI assistant query helper for summary, warning, or SOAP note generation.
    """
    insight = doctor_service.generate_ai_copilot_insight(
        db, current_doctor.id, copilot_req.patient_id, copilot_req.prompt, copilot_req.type
    )
    return {"success": True, "data": {"insight": insight}}

@router.post("/emergency-access")
def post_emergency_access(
    req: EmergencyAccessRequest,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Validates scanned emergency QR token and unlocks emergency-safe vital information.
    """
    return doctor_service.grant_emergency_access(db, current_doctor.id, req.qr_token)

@router.get("/appointments")
def get_appointments(
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Fetches all appointments for the logged-in doctor.
    """
    return {"success": True, "data": doctor_service.get_appointments(db, current_doctor)}

@router.patch("/appointments/{appointment_id}/status")
def update_appointment_status(
    appointment_id: int,
    status: str,
    current_doctor: User = Depends(get_verified_doctor),
    db: Session = Depends(get_db)
):
    """
    Doctor can update the status of an appointment.
    """
    from app.models.models import Appointment, DoctorProfile, AuditLog
    from sqlalchemy import or_

    if status not in ["Upcoming", "Completed", "Cancelled"]:
        raise HTTPException(status_code=400, detail="Invalid status. Must be Upcoming, Completed, or Cancelled")
    
    # Verify the appointment belongs to this doctor
    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == current_doctor.id).first()
    if not doc_profile:
        raise HTTPException(status_code=403, detail="Verified doctor profile required.")
    doc_name = doc_profile.full_name
    
    appointment = db.query(Appointment).filter(
        Appointment.id == appointment_id,
        or_(
            Appointment.doctor_id == current_doctor.id,
            Appointment.doctor_name == doc_name
        )
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    old_status = appointment.status
    appointment.status = status
    db.commit()
    
    # Create notification for the patient if status changed
    if old_status != status:
        from app.models.models import Notification
        notif = Notification(
            user_id=appointment.user_id,
            title="Appointment Update",
            body=f"Your appointment status with {doc_name} has been updated to {status}.",
            type="appointment"
        )
        db.add(notif)

    audit = AuditLog(
        user_id=current_doctor.id,
        action=f"APPOINTMENT_{status.upper()}",
        details=f"Doctor updated appointment ID {appointment_id} from {old_status} to {status}"
    )
    db.add(audit)
    db.commit()
    
    return {"success": True, "data": {"id": appointment.id, "status": appointment.status}}
