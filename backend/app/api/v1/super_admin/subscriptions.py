from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import PlatformSubscriptionPlan

router = APIRouter(prefix="/subscriptions", tags=["Super Admin Subscriptions"])

@router.get("")
def get_subscriptions_list(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    plans = db.query(PlatformSubscriptionPlan).all()
    if not plans:
        return [
            {"id": 1, "hospital_name": "Apollo Care Hospital", "plan_name": "Enterprise Suite", "billing_status": "Active", "monthly_price": 4999.0, "renewal_date": "2026-08-31"},
            {"id": 2, "hospital_name": "Fortis Healthcare Center", "plan_name": "Pro Tier", "billing_status": "Active", "monthly_price": 1999.0, "renewal_date": "2026-08-15"},
        ]
    return plans
