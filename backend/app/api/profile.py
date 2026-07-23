from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.auth import get_current_user
from app.models import User, Profile, MedicalHistory, AuditLog
from app.schemas import ProfileCreate, ProfileResponse, MedicalHistoryCreate, MedicalHistoryResponse

router = APIRouter(prefix="/profile", tags=["profile"])

@router.get("", response_model=ProfileResponse)
def get_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    if not profile:
        # Create a mock default profile for testing matching Majid Shaikh
        profile = Profile(
            user_id=current_user.id,
            full_name="Majid Shaikh",
            dob="1998-01-12",
            gender="Male",
            blood_group="O+",
            address="Dewas, Madhya Pradesh, India",
            emergency_contact_name="Sikandar Shaikh (Father)",
            emergency_contact_phone="+91 91234 56789",
            aadhaar_number="XXXX XXXX 1234",
            health_score=92
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
    return profile

@router.put("", response_model=ProfileResponse)
def update_profile(profile_in: ProfileCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    if not profile:
        profile = Profile(user_id=current_user.id, **profile_in.dict())
        db.add(profile)
    else:
        for field, value in profile_in.dict(exclude_unset=True).items():
            setattr(profile, field, value)
            
    db.commit()
    db.refresh(profile)
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="UPDATE_PROFILE", details="Patient profile updated")
    db.add(audit)
    db.commit()
    
    return profile

@router.get("/medical-history", response_model=List[MedicalHistoryResponse])
def get_medical_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    histories = db.query(MedicalHistory).filter(MedicalHistory.user_id == current_user.id).all()
    
    # Add mock data if empty
    if not histories:
        mock_data = [
            MedicalHistory(user_id=current_user.id, type="condition", title="Chronic Diseases", description="No chronic disease diagnosed.", date_recorded="2026-05-10"),
            MedicalHistory(user_id=current_user.id, type="allergy", title="Allergies", description="Penicillin, Pollen", date_recorded="2024-03-05"),
            MedicalHistory(user_id=current_user.id, type="surgery", title="Surgeries", description="Appendectomy (2019)", date_recorded="2019-08-20"),
            MedicalHistory(user_id=current_user.id, type="family", title="Family History", description="Diabetes, Hypertension", date_recorded="2025-11-15"),
            MedicalHistory(user_id=current_user.id, type="vaccination", title="Vaccination", description="Up to date (Hep B, Covid Booster)", date_recorded="2025-01-10"),
        ]
        for item in mock_data:
            db.add(item)
        db.commit()
        histories = db.query(MedicalHistory).filter(MedicalHistory.user_id == current_user.id).all()
        
    return histories

@router.post("/medical-history", response_model=MedicalHistoryResponse)
def add_medical_history(history_in: MedicalHistoryCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    new_item = MedicalHistory(user_id=current_user.id, **history_in.dict())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="ADD_MEDICAL_HISTORY", details=f"Added medical history: {history_in.title}")
    db.add(audit)
    db.commit()
    
    return new_item

@router.delete("/medical-history/{item_id}")
def delete_medical_history(item_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    item = db.query(MedicalHistory).filter(MedicalHistory.id == item_id, MedicalHistory.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Medical history item not found")
        
    db.delete(item)
    db.commit()
    return {"status": "success", "message": "Medical history item deleted"}
