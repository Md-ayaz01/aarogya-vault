from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
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
