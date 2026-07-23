from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional

class BaseGovernmentProvider(ABC):
    @abstractmethod
    def get_provider_name(self) -> str:
        """Returns the name of the government integration provider."""
        pass

    @abstractmethod
    def is_configured(self) -> bool:
        """Returns True if the provider is fully configured with credentials."""
        pass


class ABDMProvider(BaseGovernmentProvider):
    @abstractmethod
    def verify_abha(self, abha_number: str) -> Dict[str, Any]:
        """Verifies or links ABDM ABHA ID."""
        pass


class PMJAYProvider(BaseGovernmentProvider):
    @abstractmethod
    def search_hospitals(self, pincode: Optional[str] = None, city: Optional[str] = None) -> List[Dict[str, Any]]:
        """Searches PMJAY empanelled hospitals."""
        pass

    @abstractmethod
    def get_hospital_details(self, hospital_id: str) -> Dict[str, Any]:
        """Fetches detailed empanelment information."""
        pass


class ABHAProvider(BaseGovernmentProvider):
    @abstractmethod
    def create_abha_number(self, aadhaar_number: str) -> Dict[str, Any]:
        """Triggers UIDAI OTP flow for ABHA generation."""
        pass


class NHFRProvider(BaseGovernmentProvider):
    @abstractmethod
    def lookup_facility(self, facility_id: str) -> Dict[str, Any]:
        """Looks up health facility details in National Health Facility Registry."""
        pass


class HPRProvider(BaseGovernmentProvider):
    @abstractmethod
    def verify_practitioner(self, registration_number: str) -> Dict[str, Any]:
        """Looks up professional status in Health Professional Registry."""
        pass
