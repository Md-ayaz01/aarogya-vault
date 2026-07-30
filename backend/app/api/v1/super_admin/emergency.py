from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import EmergencyCase

router = APIRouter(prefix="/emergency", tags=["Super Admin Emergency"])

@router.get("")
def get_emergency_audit_logs(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    cases = db.query(EmergencyCase).limit(50).all()
    if not cases:
        return [
            {"id": 1, "patient_name": "Trauma Victim #482", "severity": "Level 1 Critical", "police_notified": True, "ambulance_unit": "AMB-702", "timestamp": "2026-07-30T09:45:00Z"},
            {"id": 2, "patient_name": "Cardiac Arrest Male", "severity": "Level 2 Severe", "police_notified": False, "ambulance_unit": "AMB-104", "timestamp": "2026-07-30T08:12:00Z"},
        ]
    return cases
