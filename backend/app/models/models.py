from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Text, Float
from sqlalchemy.orm import relationship
from datetime import datetime, timezone
from app.core.database import Base

def get_utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    supabase_user_id = Column(String, unique=True, index=True, nullable=True)
    firebase_uid = Column(String, unique=True, index=True, nullable=True)
    phone = Column(String, unique=True, index=True, nullable=True)
    email = Column(String, unique=True, index=True, nullable=True)
    hashed_password = Column(String, nullable=True)
    biometric_token_hash = Column(String, nullable=True)
    role = Column(String, default="patient", nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    profile = relationship("Profile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    doctor_profile = relationship("DoctorProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    medical_records = relationship("MedicalHistory", back_populates="user", cascade="all, delete-orphan")
    reports = relationship("LabReport", back_populates="user", cascade="all, delete-orphan")
    prescriptions = relationship("Prescription", foreign_keys="[Prescription.user_id]", back_populates="user", cascade="all, delete-orphan")
    doctor_prescriptions = relationship("Prescription", foreign_keys="[Prescription.doctor_id]", back_populates="doctor", cascade="all, delete-orphan")
    reminders = relationship("MedicineReminder", back_populates="user", cascade="all, delete-orphan")
    appointments = relationship("Appointment", foreign_keys="[Appointment.user_id]", back_populates="user", cascade="all, delete-orphan")
    doctor_appointments = relationship("Appointment", foreign_keys="[Appointment.doctor_id]", back_populates="doctor", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="user", cascade="all, delete-orphan")
    chat_messages = relationship("AIChatMessage", back_populates="user", cascade="all, delete-orphan")
    consent_settings = relationship("ConsentSetting", back_populates="user", uselist=False, cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user", cascade="all, delete-orphan")
    refresh_tokens = relationship("RefreshToken", back_populates="user", cascade="all, delete-orphan")
    qr_tokens = relationship("QRToken", back_populates="user", cascade="all, delete-orphan")
    emergency_contacts = relationship("EmergencyContact", back_populates="user", cascade="all, delete-orphan")


class Profile(Base):
    __tablename__ = "profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=False)
    dob = Column(String, nullable=True)
    gender = Column(String, nullable=True)
    blood_group = Column(String, nullable=True)
    address = Column(String, nullable=True)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    aadhaar_number = Column(String, nullable=True)  # Masked when returned
    health_score = Column(Integer, default=92)
    
    user = relationship("User", back_populates="profile")


class MedicalHistory(Base):
    __tablename__ = "medical_records"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    type = Column(String, nullable=False)  # allergy, condition, surgery, vaccination, family, lifestyle
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    date_recorded = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="medical_records")


class LabReport(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String, nullable=False)
    date = Column(String, nullable=False)
    type = Column(String, nullable=False)  # Lab, Imaging, Others
    status = Column(String, default="Final")
    file_name = Column(String, nullable=True)  # Name of file in storage
    file_url = Column(String, nullable=True)   # Public download link
    file_hash = Column(String, nullable=True)  # SHA-256 hash for duplicate check
    summary = Column(Text, nullable=True)      # AI Generated summary
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)
    
    user = relationship("User", back_populates="reports")


class Prescription(Base):
    __tablename__ = "prescriptions"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    doctor_name = Column(String, nullable=False)
    specialty = Column(String, nullable=True)
    date = Column(String, nullable=False)
    diagnosis = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", foreign_keys=[user_id], back_populates="prescriptions")
    doctor = relationship("User", foreign_keys=[doctor_id], back_populates="doctor_prescriptions")
    items = relationship("PrescriptionItem", back_populates="prescription", cascade="all, delete-orphan")


class PrescriptionItem(Base):
    __tablename__ = "prescription_items"
    
    id = Column(Integer, primary_key=True, index=True)
    prescription_id = Column(Integer, ForeignKey("prescriptions.id", ondelete="CASCADE"), nullable=False, index=True)
    medicine_name = Column(String, nullable=False)
    dosage = Column(String, nullable=False)  # e.g., 650mg
    instruction = Column(String, nullable=False)  # e.g., 1-0-1 After Food
    
    prescription = relationship("Prescription", back_populates="items")


class MedicineReminder(Base):
    __tablename__ = "medicine_reminders"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    medicine_name = Column(String, nullable=False)
    dosage = Column(String, nullable=False)
    time = Column(String, nullable=False)  # HH:MM
    instruction = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    status = Column(String, default="Pending")  # Taken, Missed, Pending
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="reminders")


class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    doctor_name = Column(String, nullable=False)
    specialty = Column(String, nullable=True)
    date_time = Column(String, nullable=False)  # YYYY-MM-DD HH:MM
    status = Column(String, default="Upcoming")  # Upcoming, Completed, Cancelled
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", foreign_keys=[user_id], back_populates="appointments")
    doctor = relationship("User", foreign_keys=[doctor_id], back_populates="doctor_appointments")


class AuditLog(Base):
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    action = Column(String, nullable=False)
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    endpoint = Column(String, nullable=True)
    request_method = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)
    details = Column(Text, nullable=True)
    
    user = relationship("User", back_populates="audit_logs")


class AIChatMessage(Base):
    __tablename__ = "ai_chat_messages"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    message = Column(Text, nullable=False)
    is_user = Column(Boolean, default=True)
    timestamp = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="chat_messages")


class ConsentSetting(Base):
    __tablename__ = "consent_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    allow_ai_profile_read = Column(Boolean, default=True)
    allow_ai_records_read = Column(Boolean, default=True)
    allow_emergency_profile_read = Column(Boolean, default=True)
    allow_emergency_records_read = Column(Boolean, default=True)
    
    user = relationship("User", back_populates="consent_settings")


class Notification(Base):
    __tablename__ = "notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String, nullable=False)
    body = Column(Text, nullable=False)
    type = Column(String, default="alert")  # alert, medicine, appointment, emergency
    timestamp = Column(DateTime, default=get_utc_now, nullable=False)
    is_read = Column(Boolean, default=False)
    
    user = relationship("User", back_populates="notifications")


class EmergencyContact(Base):
    __tablename__ = "emergency_contacts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False)
    phone = Column(String, nullable=False)
    relation = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="emergency_contacts")


class QRToken(Base):
    __tablename__ = "qr_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String, unique=True, nullable=False, index=True)
    is_active = Column(Boolean, default=True, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    updated_at = Column(DateTime, default=get_utc_now, onupdate=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="qr_tokens")


class OTPSession(Base):
    __tablename__ = "otp_sessions"
    
    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String, nullable=False, index=True)
    verification_sid = Column(String, nullable=True)
    attempts_count = Column(Integer, default=0, nullable=False)
    status = Column(String, default="pending", nullable=False)  # pending, approved, failed
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    updated_at = Column(DateTime, default=get_utc_now, onupdate=get_utc_now, nullable=False)


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token = Column(String, unique=True, nullable=False, index=True)
    expires_at = Column(DateTime, nullable=False, index=True)
    is_revoked = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="refresh_tokens")


class DoctorProfile(Base):
    __tablename__ = "doctor_profiles"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    full_name = Column(String, nullable=False)
    registration_number = Column(String, unique=True, nullable=False, index=True)
    specialty = Column(String, nullable=False)
    hospital_name = Column(String, nullable=False)
    is_verified = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    updated_at = Column(DateTime, default=get_utc_now, onupdate=get_utc_now, nullable=False)
    
    user = relationship("User", back_populates="doctor_profile")


class DoctorPatientAccess(Base):
    __tablename__ = "doctor_patient_access"
    
    id = Column(Integer, primary_key=True, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    access_type = Column(String, nullable=False)  # appointment, consent, emergency
    is_active = Column(Boolean, default=True, nullable=False)
    granted_at = Column(DateTime, default=get_utc_now, nullable=False)
    expires_at = Column(DateTime, nullable=True)
    revoked_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    updated_at = Column(DateTime, default=get_utc_now, onupdate=get_utc_now, nullable=False)
    
    doctor = relationship("User", foreign_keys=[doctor_id])
    patient = relationship("User", foreign_keys=[patient_id])


class Hospital(Base):
    __tablename__ = "hospitals"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    license_number = Column(String, unique=True, nullable=False, index=True)
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
    email = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)


class Department(Base):
    __tablename__ = "departments"
    
    id = Column(Integer, primary_key=True, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=True, index=True)
    name = Column(String, nullable=False, index=True)
    code = Column(String, unique=True, nullable=False, index=True)
    head_doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    head_doctor = relationship("User", foreign_keys=[head_doctor_id])


class Ward(Base):
    __tablename__ = "wards"
    
    id = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False, index=True)
    ward_type = Column(String, nullable=False, default="General")  # ICU, General, Private, Emergency
    capacity = Column(Integer, default=10, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    department = relationship("Department")
    beds = relationship("Bed", back_populates="ward", cascade="all, delete-orphan")


class Bed(Base):
    __tablename__ = "beds"
    
    id = Column(Integer, primary_key=True, index=True)
    ward_id = Column(Integer, ForeignKey("wards.id", ondelete="CASCADE"), nullable=False, index=True)
    bed_number = Column(String, nullable=False, index=True)
    is_occupied = Column(Boolean, default=False, nullable=False)
    daily_rate = Column(Integer, default=1500, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    ward = relationship("Ward", back_populates="beds")


class Admission(Base):
    __tablename__ = "admissions"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id", ondelete="SET NULL"), nullable=True, index=True)
    bed_id = Column(Integer, ForeignKey("beds.id", ondelete="SET NULL"), nullable=True, index=True)
    admission_type = Column(String, nullable=False, default="IPD")  # IPD, OPD, Emergency
    status = Column(String, nullable=False, default="Admitted")  # Admitted, Transferred, Discharged
    admission_date = Column(DateTime, default=get_utc_now, nullable=False)
    discharge_date = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    patient = relationship("User", foreign_keys=[patient_id])
    doctor = relationship("User", foreign_keys=[doctor_id])
    department = relationship("Department")
    bed = relationship("Bed")


class BedAssignmentHistory(Base):
    __tablename__ = "bed_assignment_history"
    
    id = Column(Integer, primary_key=True, index=True)
    admission_id = Column(Integer, ForeignKey("admissions.id", ondelete="CASCADE"), nullable=False, index=True)
    bed_id = Column(Integer, ForeignKey("beds.id", ondelete="CASCADE"), nullable=False, index=True)
    assigned_at = Column(DateTime, default=get_utc_now, nullable=False)
    released_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    
    admission = relationship("Admission")
    bed = relationship("Bed")


class EmergencyCase(Base):
    __tablename__ = "emergency_cases"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    severity = Column(String, nullable=False, default="High")  # Critical, High, Moderate
    triage_notes = Column(Text, nullable=True)
    ambulance_unit = Column(String, nullable=True)
    police_notified = Column(Boolean, default=False, nullable=False)
    status = Column(String, default="Active", nullable=False)  # Active, Resolved, Transferred
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)
    
    patient = relationship("User", foreign_keys=[patient_id])


class PharmacyInventory(Base):
    __tablename__ = "pharmacy_inventory"
    
    id = Column(Integer, primary_key=True, index=True)
    medicine_name = Column(String, nullable=False, index=True)
    category = Column(String, nullable=False, default="General")
    batch_number = Column(String, nullable=False, index=True)
    stock_quantity = Column(Integer, default=100, nullable=False)
    unit_price = Column(Integer, default=50, nullable=False)
    reorder_level = Column(Integer, default=20, nullable=False)
    expiry_date = Column(String, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)


class MedicineRequest(Base):
    __tablename__ = "medicine_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    medicine_name = Column(String, nullable=False)
    quantity = Column(Integer, default=1, nullable=False)
    status = Column(String, default="Pending", nullable=False)  # Pending, Approved, Issued, Cancelled
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    patient = relationship("User", foreign_keys=[patient_id])
    doctor = relationship("User", foreign_keys=[doctor_id])


class MedicineIssue(Base):
    __tablename__ = "medicine_issues"
    
    id = Column(Integer, primary_key=True, index=True)
    request_id = Column(Integer, ForeignKey("medicine_requests.id", ondelete="CASCADE"), nullable=False, index=True)
    pharmacist_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    issued_quantity = Column(Integer, nullable=False)
    issued_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    request = relationship("MedicineRequest")
    pharmacist = relationship("User", foreign_keys=[pharmacist_id])


class LabOrder(Base):
    __tablename__ = "lab_orders"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    test_name = Column(String, nullable=False, index=True)
    status = Column(String, default="Pending", nullable=False)  # Pending, In-Progress, Completed, Cancelled
    results_summary = Column(Text, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)
    
    patient = relationship("User", foreign_keys=[patient_id])
    doctor = relationship("User", foreign_keys=[doctor_id])


class RadiologyOrder(Base):
    __tablename__ = "radiology_orders"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True)
    modality = Column(String, nullable=False)  # MRI, CT, X-Ray, Ultrasound
    body_part = Column(String, nullable=True)
    status = Column(String, default="Pending", nullable=False)
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)
    
    patient = relationship("User", foreign_keys=[patient_id])
    doctor = relationship("User", foreign_keys=[doctor_id])


class HospitalStaff(Base):
    __tablename__ = "hospital_staff"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    department_id = Column(Integer, ForeignKey("departments.id", ondelete="SET NULL"), nullable=True, index=True)
    role_title = Column(String, nullable=False)  # Hospital Admin, Nurse, Pharmacist, Lab Tech, Radiologist
    shift_schedule = Column(String, default="Morning Shift")
    created_at = Column(DateTime, default=get_utc_now, nullable=False)
    
    user = relationship("User", foreign_keys=[user_id])
    department = relationship("Department")


class RolePermission(Base):
    __tablename__ = "role_permissions"
    
    id = Column(Integer, primary_key=True, index=True)
    role_name = Column(String, nullable=False, index=True)
    permission_key = Column(String, nullable=False, index=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)


class HospitalNotification(Base):
    __tablename__ = "hospital_notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=True, index=True)
    title = Column(String, nullable=False)
    body = Column(Text, nullable=False)
    type = Column(String, default="alert")
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)


class DepartmentStatistics(Base):
    __tablename__ = "department_statistics"
    
    id = Column(Integer, primary_key=True, index=True)
    department_id = Column(Integer, ForeignKey("departments.id", ondelete="CASCADE"), nullable=False, index=True)
    total_patients = Column(Integer, default=0)
    active_admissions = Column(Integer, default=0)
    recorded_date = Column(String, nullable=False, index=True)
    
    department = relationship("Department")


class HospitalApprovalRequest(Base):
    __tablename__ = "hospital_approval_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    hospital_name = Column(String, nullable=False, index=True)
    license_number = Column(String, nullable=False, index=True)
    status = Column(String, default="Pending", index=True)
    requested_at = Column(DateTime, default=get_utc_now, nullable=False)
    reviewed_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)


class AIModelConfig(Base):
    __tablename__ = "ai_model_configs"
    
    id = Column(Integer, primary_key=True, index=True)
    model_name = Column(String, nullable=False, index=True)
    temperature = Column(Float, default=0.7)
    max_tokens = Column(Integer, default=2048)
    system_prompt = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    updated_at = Column(DateTime, default=get_utc_now, onupdate=get_utc_now, nullable=False)


class AyushmanIntegrationSetting(Base):
    __tablename__ = "ayushman_integration_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=True, index=True)
    pmjay_id = Column(String, nullable=False, index=True)
    coverage_status = Column(String, default="Active")
    claims_processed = Column(Integer, default=0)
    updated_at = Column(DateTime, default=get_utc_now, nullable=False)


class PlatformApiKey(Base):
    __tablename__ = "platform_api_keys"
    
    id = Column(Integer, primary_key=True, index=True)
    client_name = Column(String, nullable=False, index=True)
    api_key_hash = Column(String, nullable=False, unique=True, index=True)
    rate_limit = Column(Integer, default=1000)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=get_utc_now, nullable=False)


class BroadcastNotification(Base):
    __tablename__ = "broadcast_notifications"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    message = Column(Text, nullable=False)
    target_role = Column(String, default="all", index=True)
    severity = Column(String, default="info")
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)


class PlatformSubscriptionPlan(Base):
    __tablename__ = "platform_subscription_plans"
    
    id = Column(Integer, primary_key=True, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=True, index=True)
    plan_name = Column(String, nullable=False, index=True)
    billing_status = Column(String, default="Active")
    monthly_price = Column(Float, default=999.0)
    renewal_date = Column(String, nullable=False)


class SupportTicket(Base):
    __tablename__ = "support_tickets"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True, index=True)
    category = Column(String, nullable=False)
    priority = Column(String, default="Medium")
    status = Column(String, default="Open", index=True)
    subject = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    created_at = Column(DateTime, default=get_utc_now, nullable=False, index=True)


class PlatformAuditLog(Base):
    __tablename__ = "platform_audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    actor_email = Column(String, nullable=False, index=True)
    role = Column(String, nullable=False, index=True)
    action = Column(String, nullable=False, index=True)
    resource = Column(String, nullable=False)
    details = Column(Text, nullable=True)
    timestamp = Column(DateTime, default=get_utc_now, nullable=False, index=True)


