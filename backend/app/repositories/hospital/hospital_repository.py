from sqlalchemy.orm import Session
from sqlalchemy import func, desc, or_
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone

from app.models.models import (
    User, Profile, DoctorProfile, Department, Ward, Bed, Admission,
    BedAssignmentHistory, EmergencyCase, PharmacyInventory, MedicineRequest,
    MedicineIssue, LabOrder, RadiologyOrder, HospitalStaff, RolePermission,
    HospitalNotification, DepartmentStatistics, Appointment, AuditLog, LabReport, Prescription
)

def get_utc_now():
    return datetime.now(timezone.utc)

class HospitalRepository:
    def __init__(self, db: Session):
        self.db = db

    # --- DASHBOARD & METRICS ---
    def get_dashboard_metrics(self) -> Dict[str, Any]:
        total_patients = self.db.query(User).filter(User.role == "patient").count()
        total_doctors = self.db.query(DoctorProfile).count()
        active_admissions = self.db.query(Admission).filter(Admission.status == "Admitted").count()
        total_beds = self.db.query(Bed).count()
        occupied_beds = self.db.query(Bed).filter(Bed.is_occupied == True).count()
        emergency_cases = self.db.query(EmergencyCase).filter(EmergencyCase.status == "Active").count()
        today_appointments = self.db.query(Appointment).count()
        low_stock_medicines = self.db.query(PharmacyInventory).filter(PharmacyInventory.stock_quantity <= PharmacyInventory.reorder_level).count()

        return {
            "total_patients": total_patients,
            "total_doctors": total_doctors,
            "active_admissions": active_admissions,
            "total_beds": total_beds or 100,
            "occupied_beds": occupied_beds,
            "available_beds": max(0, (total_beds or 100) - occupied_beds),
            "emergency_cases": emergency_cases,
            "today_appointments": today_appointments,
            "low_stock_medicines": low_stock_medicines,
            "bed_occupancy_rate": round((occupied_beds / max(1, total_beds or 100)) * 100, 1)
        }

    # --- PATIENT MANAGEMENT ---
    def list_patients(self, search: Optional[str] = None, skip: int = 0, limit: int = 50) -> List[User]:
        query = self.db.query(User).filter(User.role == "patient")
        if search:
            query = query.join(Profile, isouter=True).filter(
                or_(
                    User.phone.ilike(f"%{search}%"),
                    User.email.ilike(f"%{search}%"),
                    Profile.full_name.ilike(f"%{search}%")
                )
            )
        return query.order_by(desc(User.created_at)).offset(skip).limit(limit).all()

    # --- DOCTOR MANAGEMENT ---
    def list_doctors(self, department_id: Optional[int] = None) -> List[DoctorProfile]:
        query = self.db.query(DoctorProfile)
        return query.all()

    # --- DEPARTMENTS ---
    def list_departments(self) -> List[Department]:
        return self.db.query(Department).all()

    def create_department(self, name: str, code: str, head_doctor_id: Optional[int] = None, description: Optional[str] = None) -> Department:
        dept = Department(name=name, code=code, head_doctor_id=head_doctor_id, description=description)
        self.db.add(dept)
        self.db.commit()
        self.db.refresh(dept)
        return dept

    # --- WARDS & BEDS ---
    def list_wards(self) -> List[Ward]:
        return self.db.query(Ward).all()

    def list_beds(self, ward_id: Optional[int] = None) -> List[Bed]:
        query = self.db.query(Bed)
        if ward_id:
            query = query.filter(Bed.ward_id == ward_id)
        return query.all()

    # --- ADMISSIONS ---
    def list_admissions(self, status: Optional[str] = None) -> List[Admission]:
        query = self.db.query(Admission)
        if status:
            query = query.filter(Admission.status == status)
        return query.order_by(desc(Admission.admission_date)).all()

    def create_admission(self, patient_id: int, doctor_id: Optional[int], department_id: Optional[int], bed_id: Optional[int], admission_type: str = "IPD", notes: Optional[str] = None) -> Admission:
        admission = Admission(
            patient_id=patient_id,
            doctor_id=doctor_id,
            department_id=department_id,
            bed_id=bed_id,
            admission_type=admission_type,
            status="Admitted",
            notes=notes
        )
        self.db.add(admission)
        if bed_id:
            bed = self.db.query(Bed).filter(Bed.id == bed_id).first()
            if bed:
                bed.is_occupied = True
                history = BedAssignmentHistory(admission=admission, bed=bed, notes="Initial admission assignment")
                self.db.add(history)
        self.db.commit()
        self.db.refresh(admission)
        return admission

    # --- EMERGENCY ---
    def list_emergency_cases(self) -> List[EmergencyCase]:
        return self.db.query(EmergencyCase).order_by(desc(EmergencyCase.created_at)).all()

    def create_emergency_case(self, patient_id: Optional[int], severity: str, triage_notes: str, ambulance_unit: Optional[str] = None, police_notified: bool = False) -> EmergencyCase:
        ecase = EmergencyCase(
            patient_id=patient_id,
            severity=severity,
            triage_notes=triage_notes,
            ambulance_unit=ambulance_unit,
            police_notified=police_notified,
            status="Active"
        )
        self.db.add(ecase)
        self.db.commit()
        self.db.refresh(ecase)
        return ecase

    # --- PHARMACY ---
    def list_pharmacy_inventory(self) -> List[PharmacyInventory]:
        return self.db.query(PharmacyInventory).order_by(PharmacyInventory.medicine_name).all()

    def add_medicine_stock(self, medicine_name: str, category: str, batch_number: str, stock_quantity: int, unit_price: int, expiry_date: str, reorder_level: int = 20) -> PharmacyInventory:
        item = PharmacyInventory(
            medicine_name=medicine_name,
            category=category,
            batch_number=batch_number,
            stock_quantity=stock_quantity,
            unit_price=unit_price,
            expiry_date=expiry_date,
            reorder_level=reorder_level
        )
        self.db.add(item)
        self.db.commit()
        self.db.refresh(item)
        return item

    # --- LAB & RADIOLOGY ORDERS ---
    def list_lab_orders(self) -> List[LabOrder]:
        return self.db.query(LabOrder).order_by(desc(LabOrder.created_at)).all()

    def list_radiology_orders(self) -> List[RadiologyOrder]:
        return self.db.query(RadiologyOrder).order_by(desc(RadiologyOrder.created_at)).all()

    # --- AUDIT LOGS ---
    def list_audit_logs(self, limit: int = 100) -> List[AuditLog]:
        return self.db.query(AuditLog).order_by(desc(AuditLog.created_at)).limit(limit).all()
