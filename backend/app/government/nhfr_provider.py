from typing import Dict, Any
from app.government.provider import NHFRProvider

class DefaultNHFRProvider(NHFRProvider):
    def get_provider_name(self) -> str:
        return "NHFR"

    def is_configured(self) -> bool:
        return False

    def lookup_facility(self, facility_id: str) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government National Health Facility Registry (NHFR) integration is not configured."
        }

nhfr_provider = DefaultNHFRProvider()
