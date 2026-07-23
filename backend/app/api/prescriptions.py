from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, Prescription, PrescriptionItem, AuditLog
from app.schemas import PrescriptionCreate, PrescriptionResponse

router = APIRouter(prefix="/prescriptions", tags=["prescriptions"])

@router.get("", response_model=List[PrescriptionResponse])
def get_prescriptions(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    prescriptions = db.query(Prescription).filter(Prescription.user_id == current_user.id).all()
    
    # Seed default data if empty (matching the mock data in client)
    if not prescriptions:
        prescription = Prescription(
            user_id=current_user.id,
            doctor_name="Dr. Ravi Sharma",
            specialty="MBBS, MD (Medicine)\nApollo Hospital, Indore",
            date="12 Apr 2024",
            diagnosis="Viral Fever",
            notes="Take rest and drink plenty of fluids."
        )
        db.add(prescription)
        db.commit()
        db.refresh(prescription)
        
        items = [
            PrescriptionItem(prescription_id=prescription.id, medicine_name="Paracetamol 650mg", dosage="1 Tablet", instruction="1-0-1 After Food"),
            PrescriptionItem(prescription_id=prescription.id, medicine_name="Azithromycin 500mg", dosage="1 Tablet", instruction="0-0-1 After Food"),
            PrescriptionItem(prescription_id=prescription.id, medicine_name="Cetirizine 10mg", dosage="1 Tablet", instruction="0-0-1 Before Sleep"),
        ]
        for it in items:
            db.add(it)
        db.commit()
        db.refresh(prescription)
        prescriptions = [prescription]
        
    return prescriptions

@router.get("/{prescription_id}", response_model=PrescriptionResponse)
def get_prescription(prescription_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    prescription = db.query(Prescription).filter(Prescription.id == prescription_id, Prescription.user_id == current_user.id).first()
    if not prescription:
        raise HTTPException(status_code=404, detail="Prescription not found")
    return prescription

@router.post("", response_model=PrescriptionResponse)
def create_prescription(prescription_in: PrescriptionCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
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
    prescription = db.query(Prescription).filter(Prescription.id == prescription_id, Prescription.user_id == current_user.id).first()
    if not prescription:
        raise HTTPException(status_code=404, detail="Prescription not found")
        
    db.delete(prescription)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_PRESCRIPTION", details=f"Deleted prescription ID {prescription_id}")
    db.add(audit)
    db.commit()
    
    return {"status": "success", "message": "Prescription deleted successfully"}
