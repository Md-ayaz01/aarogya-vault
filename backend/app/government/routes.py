from fastapi import APIRouter, Query
from typing import Optional
from app.government.hospital_service import hospital_service
from app.government.doctor_service import doctor_service

router = APIRouter(prefix="/government", tags=["government"])

@router.get("/hospitals")
def get_hospitals(city: Optional[str] = Query(None), pincode: Optional[str] = Query(None)):
    """Search government PM-JAY empanelled hospitals."""
    return hospital_service.search_nearby_hospitals(pincode=pincode, city=city)

@router.get("/hospitals/nearby")
def get_nearby_hospitals(pincode: str = Query(...)):
    """Search empanelled hospitals by pincode."""
    return hospital_service.search_nearby_hospitals(pincode=pincode)

@router.get("/doctors")
def get_doctors(registration_number: str = Query(...)):
    """Verify practitioner registration in Health Professional Registry (HPR)."""
    return doctor_service.verify_doctor_status(registration_number)
