from fastapi import APIRouter, Depends, Body, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.services.super_admin.super_admin_service import SuperAdminService

router = APIRouter(prefix="/hospitals", tags=["Super Admin Hospitals"])

class HospitalCreateRequest(BaseModel):
    name: str
    license_number: str
    address: Optional[str] = "India"
    phone: Optional[str] = "+919999000000"
    email: Optional[str] = "info@hospital.com"

@router.get("")
def get_hospitals_approval(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    return service.get_hospital_approvals(current_user)

@router.get("/list")
def list_empanelled_hospitals(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    hospitals = service.list_empanelled_hospitals(current_user)
    return {"success": True, "data": hospitals}

@router.post("/register")
def register_hospital(
    payload: HospitalCreateRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    hosp = service.create_hospital(
        current_user=current_user,
        name=payload.name,
        license_number=payload.license_number,
        address=payload.address,
        phone=payload.phone,
        email=payload.email
    )
    return {"success": True, "data": {"id": hosp.id, "name": hosp.name, "license_number": hosp.license_number}}

@router.delete("/{hospital_id}")
def delete_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    success = service.delete_hospital(current_user, hospital_id)
    if not success:
        raise HTTPException(status_code=404, detail="Hospital not found")
    return {"success": True, "message": f"Hospital #{hospital_id} deleted successfully"}

@router.put("/{request_id}/status")
def update_hospital_status(
    request_id: int,
    status_val: str = Body(..., alias="status", embed=True),
    notes: Optional[str] = Body(None, embed=True),
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    service = SuperAdminService(db)
    res = service.approve_reject_hospital(current_user, request_id, status_val, notes)
    return {"success": True, "data": res}
