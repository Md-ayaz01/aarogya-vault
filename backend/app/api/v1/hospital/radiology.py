from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/radiology", tags=["hospital_radiology"])

@router.get("")
def list_radiology_orders(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.read"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.read'"
        )
    orders = service.repo.list_radiology_orders()
    res = []
    for o in orders:
        res.append({
            "id": o.id,
            "patient_id": o.patient_id,
            "patient_name": o.patient.profile.full_name if o.patient and o.patient.profile else f"Patient #{o.patient_id}",
            "modality": o.modality,
            "body_part": o.body_part or "General",
            "status": o.status,
            "image_url": o.image_url,
            "created_at": o.created_at.strftime("%Y-%m-%d %H:%M") if o.created_at else ""
        })
    return {"success": True, "data": res}
