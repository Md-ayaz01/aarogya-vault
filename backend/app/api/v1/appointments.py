from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Appointment, AuditLog
from app.schemas.schemas import AppointmentCreate, AppointmentResponse

router = APIRouter(prefix="/appointments", tags=["appointments"])

@router.get("", response_model=List[AppointmentResponse])
def get_appointments(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches appointments belonging to the authenticated patient."""
    return db.query(Appointment).filter(Appointment.user_id == current_user.id).order_by(Appointment.created_at.desc()).all()

@router.post("", response_model=AppointmentResponse)
def create_appointment(appt_in: AppointmentCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Registers a new appointment."""
    from app.models.models import DoctorProfile, Profile, Notification

    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.full_name.ilike(appt_in.doctor_name)).first()
    doc_id = doc_profile.user_id if doc_profile else None

    new_appt = Appointment(
        user_id=current_user.id,
        doctor_id=doc_id,
        doctor_name=appt_in.doctor_name,
        specialty=appt_in.specialty,
        date_time=appt_in.date_time,
        status="Upcoming"
    )
    db.add(new_appt)
    db.commit()
    db.refresh(new_appt)
    
    # Create notification for doctor if doctor exists
    if doc_id:
        pat_profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
        pat_name = pat_profile.full_name if pat_profile else "Patient"
        notif = Notification(
            user_id=doc_id,
            title="New Appointment Scheduled",
            body=f"New appointment scheduled with Patient {pat_name} for {appt_in.date_time}.",
            type="appointment"
        )
        db.add(notif)
        db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="CREATE_APPOINTMENT", details=f"Scheduled appointment with {appt_in.doctor_name}")
    db.add(audit)
    db.commit()
    
    return new_appt


@router.delete("/{appt_id}")
def delete_appointment(appt_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Deletes an appointment by ID."""
    appt = db.query(Appointment).filter(Appointment.id == appt_id, Appointment.user_id == current_user.id).first()
    if not appt:
         raise HTTPException(status_code=404, detail="Appointment not found")
         
    db.delete(appt)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_APPOINTMENT", details=f"Cancelled appointment ID {appt_id}")
    db.add(audit)
    db.commit()
    
    return {"success": True, "message": "Appointment cancelled successfully"}
