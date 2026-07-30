from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.api.v1.auth import get_current_user
from app.models.models import User
from app.services.hospital.hospital_service import HospitalService

router = APIRouter(prefix="/pharmacy", tags=["hospital_pharmacy"])

class InventoryItemCreate(BaseModel):
    medicine_name: str
    category: str = "General"
    batch_number: str
    stock_quantity: int
    unit_price: int
    expiry_date: str
    reorder_level: int = 20

@router.get("/inventory")
def list_pharmacy_inventory(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.inventory.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.inventory.manage'"
        )
    items = service.repo.list_pharmacy_inventory()
    res = []
    for item in items:
        res.append({
            "id": item.id,
            "medicine_name": item.medicine_name,
            "category": item.category,
            "batch_number": item.batch_number,
            "stock_quantity": item.stock_quantity,
            "unit_price": item.unit_price,
            "reorder_level": item.reorder_level,
            "expiry_date": item.expiry_date,
            "is_low_stock": item.stock_quantity <= item.reorder_level
        })
    return {"success": True, "data": res}

@router.post("/inventory")
def add_medicine_to_inventory(
    payload: InventoryItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    service = HospitalService(db)
    if not service.check_permission(current_user.role, "hospital.inventory.manage"):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access Denied: Required permission 'hospital.inventory.manage'"
        )
    item = service.repo.add_medicine_stock(
        medicine_name=payload.medicine_name,
        category=payload.category,
        batch_number=payload.batch_number,
        stock_quantity=payload.stock_quantity,
        unit_price=payload.unit_price,
        expiry_date=payload.expiry_date,
        reorder_level=payload.reorder_level
    )
    return {"success": True, "data": {"id": item.id, "medicine_name": item.medicine_name}}
