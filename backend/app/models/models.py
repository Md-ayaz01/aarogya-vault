from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, Boolean, Text
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
