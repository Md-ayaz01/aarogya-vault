from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/departments", tags=["hospital_departments"])

class DepartmentCreate(BaseModel):
    name: str
    code: str
    head_doctor_id: Optional[int] = None
    description: Optional[str] = None

@router.get("")
def list_departments(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.department.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.department.manage'"
        )
    depts = service.repo.list_departments()
    res = []
    for d in depts:
        res.append({
            "id": d.id,
            "name": d.name,
            "code": d.code,
            "head_doctor_id": d.head_doctor_id,
            "head_doctor_name": d.head_doctor.doctor_profile.full_name if d.head_doctor and d.head_doctor.doctor_profile else "Unassigned",
            "description": d.description
        })
    return {"success": True, "data": res}

from sqlalchemy.exc import IntegrityError

@router.post("")
def create_department(
    payload: DepartmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.department.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.department.manage'"
        )
    try:
        dept = service.repo.create_department(
            name=payload.name,
            code=payload.code,
            head_doctor_id=payload.head_doctor_id,
            description=payload.description
        )
        return {"success": True, "data": {"id": dept.id, "name": dept.name, "code": dept.code}}
    except IntegrityError:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Department code '{payload.code}' already exists"
        )
