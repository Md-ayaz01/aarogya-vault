from pydantic import BaseModel, EmailStr
from typing import List, Optional, Any
from datetime import datetime

# Standard API Envelope schemas
class ErrorDetail(BaseModel):
    code: str
    message: str

class ErrorEnvelope(BaseModel):
    success: bool = False
    error: ErrorDetail

class SuccessEnvelope(BaseModel):
    success: bool = True
    data: Any
    message: str = "Success"

# Auth schemas
class UserCreate(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: Optional[str] = None

class DoctorOnboardRequest(BaseModel):
    email: str
    phone: str
    password: str
    full_name: str
    registration_number: str
    specialty: str
    hospital_name: str

class UserLogin(BaseModel):
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    biometric_token: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str
    user_id: int
    refresh_token: Optional[str] = None
    role: Optional[str] = None

class TokenPayload(BaseModel):
    sub: Optional[int] = None

class RefreshTokenRequest(BaseModel):
    refresh_token: str

# Profile schemas
class ProfileCreate(BaseModel):
    full_name: str
    dob: Optional[str] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    aadhaar_number: Optional[str] = None

class ProfileResponse(BaseModel):
    id: int
    user_id: int
    full_name: str
    dob: Optional[str] = None
    gender: Optional[str] = None
    blood_group: Optional[str] = None
    address: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    aadhaar_number: Optional[str] = None
    health_score: int
    
    class Config:
        from_attributes = True

# Medical History
class MedicalHistoryCreate(BaseModel):
    type: str
    title: str
    description: Optional[str] = None
    date_recorded: Optional[str] = None

class MedicalHistoryResponse(BaseModel):
    id: int
    user_id: int
    type: str
    title: str
    description: Optional[str] = None
    date_recorded: Optional[str] = None
    
    class Config:
        from_attributes = True

# Lab Report
class LabReportCreate(BaseModel):
    title: str
    date: str
    type: str
    file_name: Optional[str] = None

class LabReportResponse(BaseModel):
    id: int
    user_id: int
    title: str
    date: str
    type: str
    status: str
    file_name: Optional[str] = None
    file_url: Optional[str] = None
    summary: Optional[str] = None
    
    class Config:
        from_attributes = True

# Prescription Items
class PrescriptionItemSchema(BaseModel):
    medicine_name: str
    alignment: Optional[str] = None
    dosage: str
    instruction: str
    
    class Config:
        from_attributes = True

class PrescriptionCreate(BaseModel):
    doctor_name: str
    specialty: Optional[str] = None
    date: str
    diagnosis: Optional[str] = None
    notes: Optional[str] = None
    items: List[PrescriptionItemSchema]

class PrescriptionResponse(BaseModel):
    id: int
    user_id: int
    doctor_name: str
    specialty: Optional[str] = None
    date: str
    diagnosis: Optional[str] = None
    notes: Optional[str] = None
    items: List[PrescriptionItemSchema]
    
    class Config:
        from_attributes = True

# Reminders
class MedicineReminderCreate(BaseModel):
    medicine_name: str
    dosage: str
    time: str
    instruction: Optional[str] = None

class MedicineReminderResponse(BaseModel):
    id: int
    user_id: int
    medicine_name: str
    dosage: str
    time: str
    instruction: Optional[str] = None
    is_active: bool
    status: str
    
    class Config:
        from_attributes = True

# Appointments
class AppointmentCreate(BaseModel):
    doctor_name: str
    specialty: Optional[str] = None
    date_time: str

class AppointmentResponse(BaseModel):
    id: int
    user_id: int
    doctor_name: str
    specialty: Optional[str] = None
    date_time: str
    status: str
    
    class Config:
        from_attributes = True

# AI Schemas
class AIQueryRequest(BaseModel):
    prompt: str
    context: Optional[str] = None

class AIExplanationResponse(BaseModel):
    explanation: str

# Emergency QR Schemas
class EmergencyAccessResponse(BaseModel):
    patient_name: str
    age: Optional[str] = None
    blood_group: Optional[str] = None
    allergies: List[str]
    chronic_diseases: List[str]
    current_medicines: List[str]
    emergency_contact: str
    aadhaar_status: str  # For Police view verification
    last_updated: str

# AI Chat Schemas
class AIChatMessageCreate(BaseModel):
    message: str
    is_user: bool = True

class AIChatMessageResponse(BaseModel):
    id: int
    user_id: int
    message: str
    is_user: bool
    timestamp: datetime

    class Config:
        from_attributes = True

# Consent Schemas
class ConsentSettingUpdate(BaseModel):
    allow_ai_profile_read: Optional[bool] = None
    allow_ai_records_read: Optional[bool] = None
    allow_emergency_profile_read: Optional[bool] = None
    allow_emergency_records_read: Optional[bool] = None

class ConsentSettingResponse(BaseModel):
    id: int
    user_id: int
    allow_ai_profile_read: bool
    allow_ai_records_read: bool
    allow_emergency_profile_read: bool
    allow_emergency_records_read: bool

    class Config:
        from_attributes = True

# Notification Schemas
class NotificationResponse(BaseModel):
    id: int
    user_id: int
    title: str
    body: str
    type: str
    timestamp: datetime
    is_read: bool

    class Config:
        from_attributes = True
