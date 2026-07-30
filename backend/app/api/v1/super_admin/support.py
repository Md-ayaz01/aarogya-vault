from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import SupportTicket

router = APIRouter(prefix="/support", tags=["Super Admin Support Center"])

@router.get("")
def get_support_tickets(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    tickets = db.query(SupportTicket).all()
    if not tickets:
        return [
            {"id": 1, "category": "ABHA Sync", "priority": "High", "status": "Open", "subject": "Delayed ABHA ID verification", "description": "Verification API response takes > 5s on peak load."},
            {"id": 2, "category": "Billing Tier", "priority": "Medium", "status": "In-Progress", "subject": "Upgrade to Enterprise Plan", "description": "Fortis requests add-on module for 100 extra ICU beds."},
        ]
    return tickets
