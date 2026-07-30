from fastapi import APIRouter
from app.api.v1.auth import router as auth_router
from app.api.v1.profile import router as profile_router
from app.api.v1.reports import router as reports_router
from app.api.v1.emergency import router as emergency_router
from app.api.v1.ai import router as ai_router
from app.api.v1.monitoring import router as monitoring_router
from app.api.v1.prescriptions import router as prescriptions_router
from app.api.v1.reminders import router as reminders_router
from app.api.v1.appointments import router as appointments_router
from app.api.v1.consent import router as consent_router
from app.api.v1.hospitals import router as hospitals_router
from app.api.v1.notifications import router as notifications_router
from app.government.routes import router as government_router
from app.api.v1.doctor import router as doctor_router
from app.api.v1.hospital import hospital_master_router
from app.api.v1.super_admin import super_admin_master_router

api_v1_router = APIRouter()

# Register sub-routers
api_v1_router.include_router(auth_router)
api_v1_router.include_router(profile_router)
api_v1_router.include_router(reports_router)
api_v1_router.include_router(emergency_router)
api_v1_router.include_router(ai_router)
api_v1_router.include_router(monitoring_router)
api_v1_router.include_router(prescriptions_router)
api_v1_router.include_router(reminders_router)
api_v1_router.include_router(appointments_router)
api_v1_router.include_router(consent_router)
api_v1_router.include_router(hospitals_router)
api_v1_router.include_router(notifications_router)
api_v1_router.include_router(government_router)
api_v1_router.include_router(doctor_router)
api_v1_router.include_router(hospital_master_router)
api_v1_router.include_router(super_admin_master_router)
