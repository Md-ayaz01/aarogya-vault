from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, Appointment, AuditLog
from app.schemas import AppointmentCreate, AppointmentResponse

router = APIRouter(prefix="/appointments", tags=["appointments"])

@router.get("", response_model=List[AppointmentResponse])
def get_appointments(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    appointments = db.query(Appointment).filter(Appointment.user_id == current_user.id).all()
    
    # Seed default data if empty (matching the mock data in client)
    if not appointments:
        appointments = [
            Appointment(user_id=current_user.id, doctor_name="Dr. Ravi Sharma", specialty="Cardiologist", date_time="2026-07-20 10:00 AM", status="Upcoming"),
            Appointment(user_id=current_user.id, doctor_name="Dr. Ananya Goel", specialty="Dermatologist", date_time="2026-07-10 04:30 PM", status="Completed"),
        ]
        for a in appointments:
            db.add(a)
        db.commit()
        appointments = db.query(Appointment).filter(Appointment.user_id == current_user.id).all()
        
    return appointments

@router.post("", response_model=AppointmentResponse)
def book_appointment(appointment_in: AppointmentCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    new_app = Appointment(
        user_id=current_user.id,
        doctor_name=appointment_in.doctor_name,
        specialty=appointment_in.specialty,
        date_time=appointment_in.date_time,
        status="Upcoming"
    )
    db.add(new_app)
    db.commit()
    db.refresh(new_app)
    
    audit = AuditLog(user_id=current_user.id, action="BOOK_APPOINTMENT", details=f"Booked appointment with {appointment_in.doctor_name} at {appointment_in.date_time}")
    db.add(audit)
    db.commit()
    
    return new_app

@router.patch("/{appointment_id}/status", response_model=AppointmentResponse)
def update_appointment_status(appointment_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    if status not in ["Upcoming", "Completed", "Cancelled"]:
        raise HTTPException(status_code=400, detail="Invalid status. Must be Upcoming, Completed, or Cancelled")
        
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id, Appointment.user_id == current_user.id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    appointment.status = status
    db.commit()
    db.refresh(appointment)
    
    audit = AuditLog(user_id=current_user.id, action=f"APPOINTMENT_{status.upper()}", details=f"Updated appointment with {appointment.doctor_name} to {status}")
    db.add(audit)
    db.commit()
    
    return appointment

@router.delete("/{appointment_id}")
def delete_appointment(appointment_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    appointment = db.query(Appointment).filter(Appointment.id == appointment_id, Appointment.user_id == current_user.id).first()
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
        
    db.delete(appointment)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_APPOINTMENT", details=f"Deleted appointment ID {appointment_id}")
    db.add(audit)
    db.commit()
    
    return {"status": "success", "message": "Appointment deleted successfully"}
