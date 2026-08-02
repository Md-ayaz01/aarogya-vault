from fastapi import APIRouter
from app.api.v1.hospital.dashboard import router as dashboard_router
from app.api.v1.hospital.patients import router as patients_router
from app.api.v1.hospital.doctors import router as doctors_router
from app.api.v1.hospital.departments import router as departments_router
from app.api.v1.hospital.admissions import router as admissions_router
from app.api.v1.hospital.beds import router as beds_router
from app.api.v1.hospital.appointments import router as appointments_router
from app.api.v1.hospital.laboratory import router as laboratory_router
from app.api.v1.hospital.radiology import router as radiology_router
from app.api.v1.hospital.pharmacy import router as pharmacy_router
from app.api.v1.hospital.emergency import router as emergency_router
from app.api.v1.hospital.analytics import router as analytics_router
from app.api.v1.hospital.reports import router as reports_router
from app.api.v1.hospital.settings import router as settings_router
from app.api.v1.hospital.notifications import router as notifications_router

hospital_master_router = APIRouter(prefix="/hospital", tags=["hospital"])

# Register all modular hospital sub-routers
hospital_master_router.include_router(dashboard_router)
hospital_master_router.include_router(patients_router)
hospital_master_router.include_router(doctors_router)
hospital_master_router.include_router(departments_router)
hospital_master_router.include_router(admissions_router)
hospital_master_router.include_router(beds_router)
hospital_master_router.include_router(appointments_router)
hospital_master_router.include_router(laboratory_router)
hospital_master_router.include_router(radiology_router)
hospital_master_router.include_router(pharmacy_router)
hospital_master_router.include_router(emergency_router)
hospital_master_router.include_router(analytics_router)
hospital_master_router.include_router(reports_router)
hospital_master_router.include_router(settings_router)
hospital_master_router.include_router(notifications_router)

