from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/reports", tags=["hospital_reports"])

@router.get("/patients")
def get_patient_operational_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.reports.export"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.reports.export'"
        )
    return {
        "success": True,
        "data": {
            "report_title": "Patient Operations Summary",
            "total_registered": service.repo.get_dashboard_metrics()["total_patients"],
            "export_formats": ["PDF", "EXCEL", "CSV"]
        }
    }

@router.get("/doctors")
def get_doctor_performance_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.reports.export"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.reports.export'"
        )
    return {
        "success": True,
        "data": {
            "report_title": "Doctor Performance & Schedule Metrics",
            "total_doctors": service.repo.get_dashboard_metrics()["total_doctors"],
            "export_formats": ["PDF", "EXCEL", "CSV"]
        }
    }

@router.get("/departments")
def get_department_occupancy_reports(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.reports.export"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.reports.export'"
        )
    return {
        "success": True,
        "data": {
            "report_title": "Department Occupancy & Resource Allocation",
            "departments": len(service.repo.list_departments()),
            "export_formats": ["PDF", "EXCEL", "CSV"]
        }
    }
