from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Prescription, PrescriptionItem, AuditLog
from app.schemas.schemas import PrescriptionCreate, PrescriptionResponse

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])

@router.get("", response_model=List[PrescriptionResponse])
def get_prescriptions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches prescriptions belonging to the authenticated patient."""
    return db.query(Prescription).filter(Prescription.user_id == current_user.id).order_by(Prescription.created_at.desc()).all()

@router.get("/{prescription_id}", response_model=PrescriptionResponse)
def get_prescription(prescription_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches a specific prescription by ID."""
    prescription = db.query(Prescription).filter(Prescription.id == prescription_id, Prescription.user_id == current_user.id).first()
    if not prescription:
        raise HTTPException(status_code=404, detail="Prescription not found")
    return prescription

@router.post("", response_model=PrescriptionResponse)
def create_prescription(prescription_in: PrescriptionCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Creates a new prescription record and items."""
    new_pres = Prescription(
        user_id=current_user.id,
        doctor_name=prescription_in.doctor_name,
        specialty=prescription_in.specialty,
        date=prescription_in.date,
        diagnosis=prescription_in.diagnosis,
        notes=prescription_in.notes
    )
    db.add(new_pres)
    db.commit()
    db.refresh(new_pres)
    
    for it in prescription_in.items:
        new_item = PrescriptionItem(
            prescription_id=new_pres.id,
            medicine_name=it.medicine_name,
            dosage=it.dosage,
            instruction=it.instruction
        )
        db.add(new_item)
    db.commit()
    db.refresh(new_pres)
    
    audit = AuditLog(user_id=current_user.id, action="CREATE_PRESCRIPTION", details=f"Created prescription from {prescription_in.doctor_name}")
    db.add(audit)
    db.commit()
    
    return new_pres

@router.delete("/{prescription_id}")
def delete_prescription(prescription_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Deletes a prescription by ID."""
    prescription = db.query(Prescription).filter(Prescription.id == prescription_id, Prescription.user_id == current_user.id).first()
    if not prescription:
        raise HTTPException(status_code=404, detail="Prescription not found")
        
    db.delete(prescription)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_PRESCRIPTION", details=f"Deleted prescription ID {prescription_id}")
    db.add(audit)
    db.commit()
    
    return {"success": True, "message": "Prescription deleted successfully"}
