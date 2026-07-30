from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from app.repositories.super_admin.super_admin_repository import SuperAdminRepository

class SuperAdminService:
    def __init__(self, db: Session):
        self.repo = SuperAdminRepository(db)

    def _get_user_role(self, user):
        if isinstance(user, dict):
            return str(user.get("role", "")).lower()
        return str(getattr(user, "role", "")).lower()

    def _get_user_email(self, user):
        if isinstance(user, dict):
            return str(user.get("email", "superadmin@aarogyavault.in"))
        return str(getattr(user, "email", "superadmin@aarogyavault.in"))

    def get_dashboard_kpis(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.dashboard.view")
        return self.repo.get_platform_kpis()

    def get_hospital_approvals(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.hospitals.manage")
        return self.repo.get_hospital_approval_requests()

    def approve_reject_hospital(self, current_user, request_id: int, status_val: str, notes: str = None):
        self._verify_super_admin_permission(current_user, "super_admin.hospitals.manage")
        res = self.repo.update_hospital_approval_status(request_id, status_val, notes)
        self.repo.log_action(
            actor_email=self._get_user_email(current_user),
            role=self._get_user_role(current_user),
            action=f"HOSPITAL_LICENSE_{status_val.upper()}",
            resource=f"Request #{request_id}",
            details=notes or f"Hospital status updated to {status_val}"
        )
        return res

    def get_doctor_verifications(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.doctors.verify")
        return self.repo.get_doctors_verification_list()

    def get_ai_configs(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.ai.configure")
        return self.repo.get_ai_configs()

    def get_ayushman_analytics(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.ayushman.manage")
        return self.repo.get_ayushman_metrics()

    def get_api_keys(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.api_keys.manage")
        return self.repo.get_api_keys()

    def get_broadcasts(self, current_user):
        return self.repo.get_broadcast_notifications()

    def send_broadcast(self, current_user, title: str, message: str, target_role: str, severity: str):
        self._verify_super_admin_permission(current_user, "super_admin.notifications.broadcast")
        notif = self.repo.create_broadcast_notification(title, message, target_role, severity)
        self.repo.log_action(
            actor_email=self._get_user_email(current_user),
            role=self._get_user_role(current_user),
            action="BROADCAST_NOTIFICATION_SENT",
            resource=f"Target: {target_role}",
            details=f"Title: {title}"
        )
        return notif

    def get_platform_audit_logs(self, current_user):
        self._verify_super_admin_permission(current_user, "super_admin.audit.view")
        return self.repo.get_audit_logs()

    def _verify_super_admin_permission(self, current_user, required_perm: str):
        role = self._get_user_role(current_user)
        if role not in ["super_admin", "admin", "hospital_admin"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Super Admin permission '{required_perm}' required."
            )
