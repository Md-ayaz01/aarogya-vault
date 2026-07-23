from typing import Dict, Any
from app.government.provider import HPRProvider

class DefaultHPRProvider(HPRProvider):
    def get_provider_name(self) -> str:
        return "HPR"

    def is_configured(self) -> bool:
        return False

    def verify_practitioner(self, registration_number: str) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government Health Professional Registry (HPR) integration is not configured."
        }

hpr_provider = DefaultHPRProvider()
