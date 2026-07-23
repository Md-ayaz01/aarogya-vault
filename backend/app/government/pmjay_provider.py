from typing import List, Dict, Any, Optional
from app.government.provider import PMJAYProvider

class DefaultPMJAYProvider(PMJAYProvider):
    def get_provider_name(self) -> str:
        return "PM-JAY"

    def is_configured(self) -> bool:
        return False

    def search_hospitals(self, pincode: Optional[str] = None, city: Optional[str] = None) -> List[Dict[str, Any]]:
        # In consistent response pattern, we return a list with a single dictionary indicating configuration status,
        # or we throw/return config indicators. To keep list signatures correct:
        return []

    def get_hospital_details(self, hospital_id: str) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government PM-JAY integration is not configured."
        }

    def get_unconfigured_response(self) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government PM-JAY integration is not configured."
        }

pmjay_provider = DefaultPMJAYProvider()
