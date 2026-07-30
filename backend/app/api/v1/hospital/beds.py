from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/beds", tags=["hospital_beds"])

@router.get("")
def list_beds(
    ward_id: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    beds = service.repo.list_beds(ward_id=ward_id)
    res = []
    for b in beds:
        res.append({
            "id": b.id,
            "ward_id": b.ward_id,
            "ward_name": b.ward.name if b.ward else "General Ward",
            "bed_number": b.bed_number,
            "is_occupied": b.is_occupied,
            "daily_rate": b.daily_rate
        })
    return {"success": True, "data": res}
