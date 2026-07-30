from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/settings", tags=["Super Admin Platform Settings"])

@router.get("")
def get_platform_settings(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    return {
        "platform_name": "Aarogya Vault Enterprise Health Ecosystem",
        "maintenance_mode": False,
        "backup_status": "Daily Automated Backup (Neon PostgreSQL & Supabase Storage)",
        "security_level": "AES-256 Multi-tenant Encryption Active",
        "gemini_ai_model": "gemini-1.5-pro",
        "environment": "production"
    }
