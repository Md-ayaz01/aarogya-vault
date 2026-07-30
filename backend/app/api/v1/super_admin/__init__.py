from fastapi import APIRouter
from app.api.v1.super_admin.dashboard import router as dashboard_router
from app.api.v1.super_admin.hospitals import router as hospitals_router
from app.api.v1.super_admin.doctors import router as doctors_router
from app.api.v1.super_admin.patients import router as patients_router
from app.api.v1.super_admin.users import router as users_router
from app.api.v1.super_admin.ai_control import router as ai_control_router
from app.api.v1.super_admin.emergency import router as emergency_router
from app.api.v1.super_admin.ayushman import router as ayushman_router
from app.api.v1.super_admin.analytics import router as analytics_router
from app.api.v1.super_admin.reports import router as reports_router
from app.api.v1.super_admin.audit import router as audit_router
from app.api.v1.super_admin.rbac import router as rbac_router
from app.api.v1.super_admin.api_management import router as api_management_router
from app.api.v1.super_admin.notifications import router as notifications_router
from app.api.v1.super_admin.settings import router as settings_router
from app.api.v1.super_admin.subscriptions import router as subscriptions_router
from app.api.v1.super_admin.support import router as support_router

super_admin_master_router = APIRouter(prefix="/super_admin", tags=["Super Admin Master Portal"])

# Mount 17 Super Admin sub-routers
super_admin_master_router.include_router(dashboard_router)
super_admin_master_router.include_router(hospitals_router)
super_admin_master_router.include_router(doctors_router)
super_admin_master_router.include_router(patients_router)
super_admin_master_router.include_router(users_router)
super_admin_master_router.include_router(ai_control_router)
super_admin_master_router.include_router(emergency_router)
super_admin_master_router.include_router(ayushman_router)
super_admin_master_router.include_router(analytics_router)
super_admin_master_router.include_router(reports_router)
super_admin_master_router.include_router(audit_router)
super_admin_master_router.include_router(rbac_router)
super_admin_master_router.include_router(api_management_router)
super_admin_master_router.include_router(notifications_router)
super_admin_master_router.include_router(settings_router)
super_admin_master_router.include_router(subscriptions_router)
super_admin_master_router.include_router(support_router)
