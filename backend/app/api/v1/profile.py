from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User, Profile, MedicalHistory, AuditLog, EmergencyContact
from app.schemas.schemas import ProfileCreate, ProfileResponse, MedicalHistoryCreate, MedicalHistoryResponse

router = APIRouter(tags=["profile"])

@router.get("/profile", response_model=ProfileResponse)
def get_profile(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches user profile information, creating only a minimal empty profile if needed."""
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    if not profile:
        profile = Profile(
            user_id=current_user.id,
            full_name="New Patient",
            health_score=0,
        )
        db.add(profile)
        db.commit()
        db.refresh(profile)
        
    return profile

@router.put("/profile", response_model=ProfileResponse)
def update_profile(profile_in: ProfileCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Updates profile details and synchronizes the emergency_contacts table."""
    profile = db.query(Profile).filter(Profile.user_id == current_user.id).first()
    if not profile:
        profile = Profile(user_id=current_user.id, **profile_in.dict())
        db.add(profile)
    else:
        for field, value in profile_in.dict(exclude_unset=True).items():
            setattr(profile, field, value)
            
    db.commit()
    db.refresh(profile)
    
    # Synchronize emegency contact registry
    if profile_in.emergency_contact_name and profile_in.emergency_contact_phone:
        # Check if already exists
        contact = db.query(EmergencyContact).filter(EmergencyContact.user_id == current_user.id).first()
        relation = "Emergency Contact"
        name_clean = profile_in.emergency_contact_name
        if "(" in name_clean:
            parts = name_clean.split("(")
            name_clean = parts[0].strip()
            relation = parts[1].replace(")", "").strip()
            
        if not contact:
            contact = EmergencyContact(
                user_id=current_user.id,
                name=name_clean,
                phone=profile_in.emergency_contact_phone,
                relation=relation
            )
            db.add(contact)
        else:
            contact.name = name_clean
            contact.phone = profile_in.emergency_contact_phone
            contact.relation = relation
        db.commit()
        
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="UPDATE_PROFILE", details="Patient profile updated")
    db.add(audit)
    db.commit()
    
    return profile

# Register endpoints under both /profile/medical-history and /medical-history paths for backward compatibility

@router.get("/profile/medical-history", response_model=List[MedicalHistoryResponse])
@router.get("/medical-history", response_model=List[MedicalHistoryResponse])
def get_medical_history(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Fetches user medical history items without creating fake clinical data."""
    return db.query(MedicalHistory).filter(MedicalHistory.user_id == current_user.id).order_by(MedicalHistory.created_at.desc()).all()

@router.post("/profile/medical-history", response_model=MedicalHistoryResponse)
@router.post("/medical-history", response_model=MedicalHistoryResponse)
def add_medical_history(history_in: MedicalHistoryCreate, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Adds a new medical history item."""
    new_item = MedicalHistory(user_id=current_user.id, **history_in.dict())
    db.add(new_item)
    db.commit()
    db.refresh(new_item)
    
    # Audit log
    audit = AuditLog(user_id=current_user.id, action="ADD_MEDICAL_HISTORY", details=f"Added medical record: {history_in.title}")
    db.add(audit)
    db.commit()
    
    return new_item

@router.delete("/profile/medical-history/{item_id}")
@router.delete("/medical-history/{item_id}")
def delete_medical_history(item_id: int, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    """Deletes an existing medical history record."""
    item = db.query(MedicalHistory).filter(MedicalHistory.id == item_id, MedicalHistory.user_id == current_user.id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Medical history item not found")
        
    db.delete(item)
    db.commit()
    
    audit = AuditLog(user_id=current_user.id, action="DELETE_MEDICAL_HISTORY", details=f"Deleted medical record ID {item_id}")
    db.add(audit)
    db.commit()
    
    return {"success": True, "message": "Medical history item deleted"}
