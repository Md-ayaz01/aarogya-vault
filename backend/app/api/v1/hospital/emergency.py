from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/emergency", tags=["hospital_emergency"])

class EmergencyCaseCreate(BaseModel):
    patient_id: Optional[int] = None
    severity: str = "High"
    triage_notes: str
    ambulance_unit: Optional[str] = None
    police_notified: bool = False

@router.get("")
def list_emergency_cases(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.dashboard.view"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.dashboard.view'"
        )
    cases = service.repo.list_emergency_cases()
    res = []
    for c in cases:
        res.append({
            "id": c.id,
            "patient_id": c.patient_id,
            "patient_name": c.patient.profile.full_name if c.patient and c.patient.profile else "Unknown Emergency Patient",
            "severity": c.severity,
            "triage_notes": c.triage_notes,
            "ambulance_unit": c.ambulance_unit or "Unit #108",
            "police_notified": c.police_notified,
            "status": c.status,
            "created_at": c.created_at.strftime("%Y-%m-%d %H:%M") if c.created_at else ""
        })
    return {"success": True, "data": res}

@router.post("")
def create_emergency_case(
    payload: EmergencyCaseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.patient.write"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.patient.write'"
        )
    ecase = service.repo.create_emergency_case(
        patient_id=payload.patient_id,
        severity=payload.severity,
        triage_notes=payload.triage_notes,
        ambulance_unit=payload.ambulance_unit,
        police_notified=payload.police_notified
    )
    return {"success": True, "data": {"id": ecase.id, "status": ecase.status}}
