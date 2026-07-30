from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/analytics", tags=["Super Admin Analytics"])

@router.get("")
def get_platform_analytics(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return {
        "kpis": service.get_dashboard_kpis(current_user),
        "hospital_occupancy_avg": 86.4,
        "patient_satisfaction_avg": 4.85,
        "monthly_throughput": "18,420 Patients Treated Across Ecosystem"
    }
