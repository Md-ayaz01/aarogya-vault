from typing import Dict, Any
from app.government.provider import ABDMProvider

class DefaultABDMProvider(ABDMProvider):
    def get_provider_name(self) -> str:
        return "ABDM"

    def is_configured(self) -> bool:
        return False

    def verify_abha(self, abha_number: str) -> Dict[str, Any]:
        return {
            "configured": False,
            "provider": self.get_provider_name(),
            "message": "Government ABDM integration is not configured."
        }

abdm_provider = DefaultABDMProvider()
