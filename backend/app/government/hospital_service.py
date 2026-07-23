from typing import List, Dict, Any, Optional
from app.government.pmjay_provider import pmjay_provider
from app.government.nhfr_provider import nhfr_provider

class HospitalService:
    def __init__(self):
        self.pmjay = pmjay_provider
        self.nhfr = nhfr_provider

    def search_nearby_hospitals(self, pincode: Optional[str] = None, city: Optional[str] = None) -> Dict[str, Any]:
        """Orchestrates search for empanelled hospitals, returning consistent unconfigured responses."""
        if not self.pmjay.is_configured():
            return self.pmjay.get_unconfigured_response()
            
        # Implementation when configured...
        hospitals = self.pmjay.search_hospitals(pincode=pincode, city=city)
        return {
            "configured": True,
            "provider": self.pmjay.get_provider_name(),
            "hospitals": hospitals
        }

    def get_facility_info(self, facility_id: str) -> Dict[str, Any]:
        """Fetches NHFR facility info."""
        return self.nhfr.lookup_facility(facility_id)

hospital_service = HospitalService()
