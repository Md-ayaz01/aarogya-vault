from typing import Dict, Any
from app.government.provider import ABHAProvider

class DefaultABHAProvider(ABHAProvider):
    def get_provider_name(self) -> str:
        return "ABHA"

    def is_configured(self) -> bool:
        return False

    def create_abha_number(self, aadhaar_number: str) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government ABHA integration is not configured."
        }

abha_provider = DefaultABHAProvider()
