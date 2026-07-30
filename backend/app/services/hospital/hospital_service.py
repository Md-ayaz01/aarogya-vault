from typing import Dict, Any, List, Optional
from sqlalchemy.orm import Session
from app.repositories.hospital.hospital_repository import HospitalRepository
from app.services.ai import ai_service

class HospitalService:
    def __init__(self, db: Session):
        self.db = db
        self.repo = HospitalRepository(db)

    # --- PERMISSION & RBAC ---
    ROLE_PERMISSIONS = {
        "super_admin": [
            "hospital.dashboard.view", "hospital.patient.read", "hospital.patient.write",
            "hospital.department.manage", "hospital.doctor.manage", "hospital.inventory.manage",
            "hospital.analytics.view", "hospital.audit.view", "hospital.settings.manage",
            "hospital.reports.export"
        ],
        "hospital_admin": [
            "hospital.dashboard.view", "hospital.patient.read", "hospital.patient.write",
            "hospital.department.manage", "hospital.doctor.manage", "hospital.inventory.manage",
            "hospital.analytics.view", "hospital.audit.view", "hospital.settings.manage",
            "hospital.reports.export"
        ],
        "doctor": [
            "hospital.dashboard.view", "hospital.patient.read", "hospital.patient.write",
            "hospital.analytics.view", "hospital.reports.export"
        ],
        "nurse": [
            "hospital.dashboard.view", "hospital.patient.read", "hospital.patient.write"
        ],
        "pharmacist": [
            "hospital.dashboard.view", "hospital.inventory.manage"
        ],
        "lab_tech": [
            "hospital.dashboard.view", "hospital.patient.read"
        ],
        "radiologist": [
            "hospital.dashboard.view", "hospital.patient.read"
        ],
        "receptionist": [
            "hospital.dashboard.view", "hospital.patient.read", "hospital.patient.write"
        ]
    }

    def check_permission(self, role: str, required_permission: str) -> bool:
        if role == "hospital_admin" or role == "admin" or role == "super_admin":
            return True
        allowed_perms = self.ROLE_PERMISSIONS.get(role, [])
        return required_permission in allowed_perms

    # --- DASHBOARD & ANALYTICS ---
    def get_overview(self) -> Dict[str, Any]:
        return self.repo.get_dashboard_metrics()

    # --- AI INSIGHTS ---
    def generate_hospital_ai_analytics(self) -> Dict[str, Any]:
        metrics = self.repo.get_dashboard_metrics()
        prompt = (
            f"Analyze operational metrics for Aarogya Vault Hospital Admin Portal: "
            f"Bed Occupancy Rate: {metrics['bed_occupancy_rate']}%, Active Admissions: {metrics['active_admissions']}, "
            f"Emergency Cases: {metrics['emergency_cases']}, Low Stock Medicines: {metrics['low_stock_medicines']}. "
            f"Provide 3 high-priority clinical operational insights and readmission risk mitigation advice."
        )
        insight_text = ai_service.generate_health_insight(prompt)
        
        return {
            "metrics": metrics,
            "ai_insights": insight_text,
            "risk_analysis": {
                "readmission_risk_score": 14.2,
                "high_risk_patients_count": max(1, metrics['emergency_cases']),
                "disease_trends": [
                    {"name": "Acute Upper Respiratory", "case_count": 42, "trend": "Increasing"},
                    {"name": "Type 2 Diabetes Mellitus", "case_count": 128, "trend": "Stable"},
                    {"name": "Hypertension & Cardiac", "case_count": 89, "trend": "Decreasing"}
                ]
            }
        }
