from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user

router = APIRouter(prefix="/reports", tags=["Super Admin Reports"])

@router.get("")
def get_platform_reports(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    return [
        {"id": 1, "name": "Ecosystem Platform Health Summary", "type": "PDF", "size": "12.4 MB", "generated_at": "2026-07-30T00:00:00Z"},
        {"id": 2, "name": "ABHA & PM-JAY Compliance Audit", "type": "Excel", "size": "4.8 MB", "generated_at": "2026-07-29T18:00:00Z"},
        {"id": 3, "name": "Gemini AI Clinical Usage & Token Report", "type": "PDF", "size": "8.2 MB", "generated_at": "2026-07-28T12:00:00Z"},
    ]
