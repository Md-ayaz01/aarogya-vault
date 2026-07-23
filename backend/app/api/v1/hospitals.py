from fastapi import APIRouter, Depends, Query
from typing import List, Optional

from app.api.v1.auth import get_current_user
from app.models.models import User

router = APIRouter(prefix="/hospitals", tags=["hospitals"])

@router.get("")
def search_hospitals(
    specialty: Optional[str] = Query(None),
    pincode: Optional[str] = Query(None),
    city: Optional[str] = Query(None),
    current_user: User = Depends(get_current_user)
):
    """Searches empanelled hospitals, returning mock data compatible with search screens."""
    mock_hospitals = [
        {
            "id": 1,
            "name": "Apollo Hospitals, Indore",
            "address": "Vijay Nagar, Indore, Madhya Pradesh 452010",
            "distance": "1.2 km",
            "specialties": ["Cardiology", "Neurology", "Orthopedics"],
            "pmjay_status": "Empanelled",
            "isEmergency": True,
            "type": "Private Hospital",
            "latitude": 22.9620,
            "longitude": 76.0500
        },
        {
            "id": 2,
            "name": "Medanta Hospital, Indore",
            "address": "Scheme 54, Indore, Madhya Pradesh 452010",
            "distance": "2.8 km",
            "specialties": ["Oncology", "Nephrology", "General Surgery"],
            "pmjay_status": "Empanelled",
            "isEmergency": False,
            "type": "Private Hospital",
            "latitude": 22.9630,
            "longitude": 76.0600
        },
        {
            "id": 3,
            "name": "Choithram Hospital, Indore",
            "address": "Manik Bagh Road, Indore, Madhya Pradesh 452001",
            "distance": "4.5 km",
            "specialties": ["Pediatrics", "Cardiology", "Urology"],
            "pmjay_status": "Empanelled",
            "isEmergency": True,
            "type": "Trust Hospital",
            "latitude": 22.9640,
            "longitude": 76.0700
        },
        {
            "id": 4,
            "name": "Indore District Government Hospital",
            "address": "Dhar Road, Indore, Madhya Pradesh 452002",
            "distance": "5.1 km",
            "specialties": ["General Medicine", "Pediatrics", "Gynecology"],
            "pmjay_status": "Empanelled",
            "isEmergency": True,
            "type": "Government Hospital",
            "latitude": 22.9650,
            "longitude": 76.0800
        }
    ]
    
    # Filter logically by search text if provided
    result = mock_hospitals
    if city:
        result = [h for h in result if city.lower() in h["address"].lower()]
    if pincode:
        result = [h for h in result if pincode in h["address"]]
    if specialty:
        result = [h for h in result if any(specialty.lower() in s.lower() for s in h["specialties"])]
        
    return result
