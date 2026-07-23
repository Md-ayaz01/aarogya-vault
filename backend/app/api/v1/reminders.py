from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, MedicineReminder, AuditLog
from app.schemas.schemas import MedicineReminderCreate, MedicineReminderResponse

router = APIRouter(prefix="/reminders", tags=["reminders"])

@router.get("", response_model=List[MedicineReminderResponse])
def get_reminders(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches medicine reminders belonging to the authenticated patient."""
    return db.query(MedicineReminder).filter(MedicineReminder.user_id == current_user.id).order_by(MedicineReminder.created_at.desc()).all()

@router.post("", response_model=MedicineReminderResponse)
def add_reminder(reminder_in: MedicineReminderCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Creates a new medicine reminder."""
    new_reminder = MedicineReminder(user_id=current_user.id, **reminder_in.dict())
    db.add(new_reminder)
    db.commit()
    db.refresh(new_reminder)
    
    audit = AuditLog(user_id=current_user.id, action="ADD_REMINDER", details=f"Added medicine reminder: {reminder_in.medicine_name}")
    db.add(audit)
    db.commit()
    
    return new_reminder

@router.put("/{reminder_id}/toggle", response_model=MedicineReminderResponse)
def toggle_reminder(reminder_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Toggles active state of a reminder."""
    reminder = db.query(MedicineReminder).filter(MedicineReminder.id == reminder_id, MedicineReminder.user_id == current_user.id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
        
    reminder.is_active = not reminder.is_active
    db.commit()
    db.refresh(reminder)
    
    action = "ENABLE_REMINDER" if reminder.is_active else "DISABLE_REMINDER"
    audit = AuditLog(user_id=current_user.id, action=action, details=f"Toggled medicine reminder: {reminder.medicine_name}")
    db.add(audit)
    db.commit()
    
    return reminder

@router.patch("/{reminder_id}/status", response_model=MedicineReminderResponse)
def update_reminder_status(reminder_id: int, status: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Updates reminder taken/missed status."""
    if status not in ["Taken", "Missed", "Pending"]:
        raise HTTPException(status_code=400, detail="Invalid status. Must be Taken, Missed, or Pending")
        
    reminder = db.query(MedicineReminder).filter(MedicineReminder.id == reminder_id, MedicineReminder.user_id == current_user.id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
        
    reminder.status = status
    db.commit()
    db.refresh(reminder)
    
    audit = AuditLog(user_id=current_user.id, action=f"MARK_{status.upper()}", details=f"Marked reminder {reminder.medicine_name} as {status}")
    db.add(audit)
    db.commit()
    
    return reminder

@router.put("/{reminder_id}", response_model=MedicineReminderResponse)
def update_reminder(reminder_id: int, reminder_in: MedicineReminderCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Updates reminder configuration details."""
    reminder = db.query(MedicineReminder).filter(MedicineReminder.id == reminder_id, MedicineReminder.user_id == current_user.id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
        
    for field, val in reminder_in.dict().items():
        setattr(reminder, field, val)
        
    db.commit()
    db.refresh(reminder)
    
    audit = AuditLog(user_id=current_user.id, action="UPDATE_REMINDER", details=f"Updated medicine reminder: {reminder.medicine_name}")
    db.add(audit)
    db.commit()
    
    return reminder

@router.delete("/{reminder_id}")
def delete_reminder(reminder_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Deletes a reminder record."""
    reminder = db.query(MedicineReminder).filter(MedicineReminder.id == reminder_id, MedicineReminder.user_id == current_user.id).first()
    if not reminder:
        raise HTTPException(status_code=404, detail="Reminder not found")
        
    db.delete(reminder)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_REMINDER", details=f"Deleted medicine reminder ID {reminder_id}")
    db.add(audit)
    db.commit()
    
    return {"success": True, "message": "Reminder deleted successfully"}
