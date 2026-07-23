from typing import Dict, Any
from app.government.hpr_provider import hpr_provider

class DoctorService:
    def __init__(self):
        self.hpr = hpr_provider

    def verify_doctor_status(self, registration_number: str) -> Dict[str, Any]:
        """Orchestrates doctor lookup against Government HPR."""
        return self.hpr.verify_practitioner(registration_number)

doctor_service = DoctorService()
