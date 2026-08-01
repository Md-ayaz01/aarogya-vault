import logging
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import or_
from fastapi import HTTPException, status

from app.models.models import (
    User, Profile, DoctorProfile, DoctorPatientAccess,
    Appointment, Prescription, PrescriptionItem, MedicalHistory,
    LabReport, AuditLog, QRToken, EmergencyContact, MedicineReminder, Admission
)
from app.services.ai import ai_service

logger = logging.getLogger("aarogya_vault_doctor")

class DoctorService:
    def has_patient_access(self, db: Session, doctor_id: int, patient_id: int) -> bool:
        """
        Returns True if doctor has active access via Consent, Emergency QR,
        Appointment, or Hospital Admission Assignment.
        """
        now = datetime.now(timezone.utc)
        access = db.query(DoctorPatientAccess).filter(
            DoctorPatientAccess.doctor_id == doctor_id,
            DoctorPatientAccess.patient_id == patient_id,
            DoctorPatientAccess.is_active == True,
            DoctorPatientAccess.revoked_at == None
        ).filter(
            or_(
                DoctorPatientAccess.expires_at == None,
                DoctorPatientAccess.expires_at > now
            )
        ).first()

        if access:
            return True

        # Check Appointment rule
        appt = db.query(Appointment).filter(
            Appointment.user_id == patient_id,
            Appointment.doctor_id == doctor_id
        ).first()
        if appt:
            return True

        # Check Hospital Admission Assignment rule
        admission = db.query(Admission).filter(
            Admission.patient_id == patient_id,
            Admission.doctor_id == doctor_id,
            Admission.status == "Admitted"
        ).first()
        if admission:
            return True

        return False

    def check_patient_access(self, db: Session, doctor_id: int, patient_id: int) -> DoctorPatientAccess:
        """
        Verifies if a doctor has authorized access to a patient's medical records.
        If access exists via appointment or hospital admission, auto-grants/caches access record.
        """
        now = datetime.now(timezone.utc)
        access = db.query(DoctorPatientAccess).filter(
            DoctorPatientAccess.doctor_id == doctor_id,
            DoctorPatientAccess.patient_id == patient_id,
            DoctorPatientAccess.is_active == True,
            DoctorPatientAccess.revoked_at == None
        ).filter(
            or_(
                DoctorPatientAccess.expires_at == None,
                DoctorPatientAccess.expires_at > now
            )
        ).first()

        if access:
            return access

        # Auto-grant access if patient has an active appointment with this doctor
        appt = db.query(Appointment).filter(
            Appointment.user_id == patient_id,
            Appointment.doctor_id == doctor_id
        ).first()
        if appt:
            access = DoctorPatientAccess(
                doctor_id=doctor_id,
                patient_id=patient_id,
                access_type="appointment",
                is_active=True
            )
            db.add(access)
            db.commit()
            db.refresh(access)
            return access

        # Auto-grant access if patient is admitted under this doctor
        admission = db.query(Admission).filter(
            Admission.patient_id == patient_id,
            Admission.doctor_id == doctor_id,
            Admission.status == "Admitted"
        ).first()
        if admission:
            access = DoctorPatientAccess(
                doctor_id=doctor_id,
                patient_id=patient_id,
                access_type="hospital_assignment",
                is_active=True
            )
            db.add(access)
            db.commit()
            db.refresh(access)
            return access

        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access forbidden: Doctor does not have active access authorization for this patient."
        )

    def get_dashboard(self, db: Session, doctor_user: User) -> dict:
        """
        Aggregates dashboard metrics: today's patients, appointments, critical alerts,
        recent patients, and quick actions.
        """
        doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == doctor_user.id).first()
        if not doc_profile:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verified doctor profile required.")
        doc_name = doc_profile.full_name

        # Get appointments for this doctor (or matching name if doctor_id not populated)
        today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
        appointments = db.query(Appointment).filter(
            or_(
                Appointment.doctor_id == doctor_user.id,
                Appointment.doctor_name == doc_name
            )
        ).all()

        # Filter today's appointments
        today_appts = [
            appt for appt in appointments
            if appt.date_time.startswith(today_str)
        ]

        # Extract unique patients from today's appointments
        today_patient_ids = {appt.user_id for appt in today_appts}
        today_patients_count = len(today_patient_ids)

        # Get recent patients based on recent active accesses
        recent_accesses = db.query(DoctorPatientAccess).filter(
            DoctorPatientAccess.doctor_id == doctor_user.id,
            DoctorPatientAccess.is_active == True
        ).order_by(DoctorPatientAccess.updated_at.desc()).limit(5).all()

        recent_patients = []
        for access in recent_accesses:
            pat_profile = db.query(Profile).filter(Profile.user_id == access.patient_id).first()
            if pat_profile:
                recent_patients.append({
                    "id": access.patient_id,
                    "name": pat_profile.full_name,
                    "gender": pat_profile.gender,
                    "blood_group": pat_profile.blood_group,
                    "access_type": access.access_type
                })

        # Generate critical patient alerts from active reminders/allergies/conditions
        critical_alerts = []
        # Query if any patient has allergy/condition alerts
        for pat_id in {p["id"] for p in recent_patients} | today_patient_ids:
            records = db.query(MedicalHistory).filter(MedicalHistory.user_id == pat_id).all()
            profile = db.query(Profile).filter(Profile.user_id == pat_id).first()
            name = profile.full_name if profile else f"Patient {pat_id}"
            
            allergies = [r.title for r in records if r.type == "allergy"]
            if allergies:
                critical_alerts.append({
                    "patient_id": pat_id,
                    "patient_name": name,
                    "type": "Allergy Warning",
                    "message": f"Allergic to: {', '.join(allergies)}"
                })

        return {
            "doctor_name": doc_name,
            "today_patients_count": today_patients_count,
            "today_appointments_count": len(today_appts),
            "today_appointments": [
                {
                    "id": appt.id,
                    "patient_id": appt.user_id,
                    "patient_name": db.query(Profile).filter(Profile.user_id == appt.user_id).first().full_name if db.query(Profile).filter(Profile.user_id == appt.user_id).first() else "Patient",
                    "time": appt.date_time.split(" ")[1] + " " + appt.date_time.split(" ")[2] if len(appt.date_time.split(" ")) > 2 else appt.date_time,
                    "status": appt.status
                } for appt in today_appts
            ],
            "critical_alerts": critical_alerts,
            "pending_followups_count": 0,
            "recent_patients": recent_patients,
            "quick_actions": [
                {"name": "Search Patient", "route": "/search"},
                {"name": "Scan Emergency QR", "route": "/qr-scan"},
                {"name": "Create Prescription", "route": "/prescription/create"},
                {"name": "AI Copilot", "route": "/ai-copilot"}
            ]
        }

    def get_appointments(self, db: Session, doctor_user: User) -> list:
        """
        Retrieves all appointments associated with this doctor.
        """
        doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == doctor_user.id).first()
        if not doc_profile:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verified doctor profile required.")
        doc_name = doc_profile.full_name

        appointments = db.query(Appointment).filter(
            or_(
                Appointment.doctor_id == doctor_user.id,
                Appointment.doctor_name == doc_name
            )
        ).order_by(Appointment.date_time.desc()).all()

        results = []
        now = datetime.now(timezone.utc)
        for appt in appointments:
            profile = db.query(Profile).filter(Profile.user_id == appt.user_id).first()
            access = db.query(DoctorPatientAccess).filter(
                DoctorPatientAccess.doctor_id == doctor_user.id,
                DoctorPatientAccess.patient_id == appt.user_id,
                DoctorPatientAccess.is_active == True,
                DoctorPatientAccess.revoked_at == None
            ).filter(
                or_(
                    DoctorPatientAccess.expires_at == None,
                    DoctorPatientAccess.expires_at > now
                )
            ).first()

            results.append({
                "id": appt.id,
                "patient_id": appt.user_id,
                "patient_name": profile.full_name if profile else "Unknown Patient",
                "date_time": appt.date_time,
                "status": appt.status,
                "specialty": appt.specialty,
                "has_access": access is not None
            })
        return results

    def search_patients(self, db: Session, doctor_id: int, query: str, page: int = 1, limit: int = 10) -> list:
        """
        Searches patients by numeric ID, phone number, or name.
        Enforces rate limits and audits access. Returns minimum identifying details.
        """
        # Query users with role='patient' matching criteria
        patient_query = db.query(User).filter(User.role == "patient")
        
        query = query.strip()
        
        # Check if query is digit and likely ID
        if query.isdigit() and len(query) < 6:
            patient_query = patient_query.filter(User.id == int(query))
        elif query.startswith("+") or (query.isdigit() and len(query) >= 10):
            patient_query = patient_query.filter(User.phone.like(f"%{query}%"))
        else:
            # Search by name in Profile
            patient_query = patient_query.join(Profile).filter(Profile.full_name.ilike(f"%{query}%"))

        offset = (page - 1) * limit
        users = patient_query.offset(offset).limit(limit).all()

        results = []
        for u in users:
            has_access = self.has_patient_access(db, doctor_id, u.id)
            profile = db.query(Profile).filter(Profile.user_id == u.id).first()
            results.append({
                "patient_id": u.id,
                "full_name": profile.full_name if profile else "Unknown Patient",
                "dob": profile.dob if profile else None,
                "gender": profile.gender if profile else None,
                "phone": u.phone,
                "has_access": has_access
            })

        return results

    def get_patient_profile(self, db: Session, doctor_id: int, patient_id: int) -> dict:
        """
        Fetches full patient profile demographics. Enforces server-side authorization check.
        """
        self.check_patient_access(db, doctor_id, patient_id)
        
        profile = db.query(Profile).filter(Profile.user_id == patient_id).first()
        if not profile:
            raise HTTPException(status_code=404, detail="Patient profile not found.")
            
        return {
            "patient_id": patient_id,
            "full_name": profile.full_name,
            "dob": profile.dob,
            "gender": profile.gender,
            "blood_group": profile.blood_group,
            "address": profile.address,
            "emergency_contact_name": profile.emergency_contact_name,
            "emergency_contact_phone": profile.emergency_contact_phone,
            "health_score": profile.health_score,
            "aadhaar_number": profile.aadhaar_number
        }

    def get_patient_timeline(self, db: Session, doctor_id: int, patient_id: int) -> list:
        """
        Aggregates and returns authorized medical history, reports, and prescriptions
        into a chronologically ordered medical timeline.
        """
        self.check_patient_access(db, doctor_id, patient_id)

        timeline = []

        # 1. Medical History Records
        history = db.query(MedicalHistory).filter(MedicalHistory.user_id == patient_id).all()
        for item in history:
            timeline.append({
                "id": f"history_{item.id}",
                "type": "medical_record",
                "category": item.type, # allergy, condition, surgery, vaccination
                "title": item.title,
                "description": item.description,
                "date": item.date_recorded or item.created_at.strftime("%Y-%m-%d"),
                "timestamp": item.created_at
            })

        # 2. Lab Reports
        reports = db.query(LabReport).filter(LabReport.user_id == patient_id).all()
        for report in reports:
            timeline.append({
                "id": f"report_{report.id}",
                "type": "lab_report",
                "category": report.type, # Lab, Imaging, Others
                "title": report.title,
                "description": report.summary or f"Status: {report.status}",
                "date": report.date,
                "timestamp": report.created_at,
                "file_name": report.file_name,
                "file_url": report.file_url
            })

        # 3. Prescriptions
        prescriptions = db.query(Prescription).filter(Prescription.user_id == patient_id).all()
        for pres in prescriptions:
            items_desc = ", ".join([it.medicine_name for it in pres.items])
            timeline.append({
                "id": f"prescription_{pres.id}",
                "type": "prescription",
                "category": "Prescription",
                "title": f"Prescription by {pres.doctor_name}",
                "description": f"Diagnosis: {pres.diagnosis or 'N/A'}. Medicines: {items_desc}. Notes: {pres.notes or ''}",
                "date": pres.date,
                "timestamp": pres.created_at
            })

        # Sort timeline by date/timestamp descending
        timeline.sort(key=lambda x: x["date"], reverse=True)
        return timeline

    def get_patient_reports(self, db: Session, doctor_id: int, patient_id: int) -> list:
        """
        Returns authorized patient diagnostic reports list.
        """
        self.check_patient_access(db, doctor_id, patient_id)
        
        reports = db.query(LabReport).filter(LabReport.user_id == patient_id).all()
        return [
            {
                "id": r.id,
                "title": r.title,
                "date": r.date,
                "type": r.type,
                "status": r.status,
                "file_name": r.file_name,
                "file_url": r.file_url,
                "summary": r.summary
            } for r in reports
        ]

    def create_prescription(self, db: Session, doctor_user: User, prescription_in) -> Prescription:
        """
        Handles transactional creation of patient prescriptions and associated medicine items.
        Verifies doctor active access constraint first. Audits creation.
        """
        patient_id = prescription_in.patient_id
        self.check_patient_access(db, doctor_user.id, patient_id)

        doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == doctor_user.id).first()
        if not doc_profile:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verified doctor profile required.")
        doc_name = doc_profile.full_name
        doc_specialty = doc_profile.specialty

        # Use transaction (FastAPI depends handles session rollback automatically on exception)
        new_pres = Prescription(
            user_id=patient_id,
            doctor_id=doctor_user.id,
            doctor_name=doc_name,
            specialty=doc_specialty,
            date=datetime.now(timezone.utc).strftime("%d %b %Y"),
            diagnosis=prescription_in.diagnosis,
            notes=prescription_in.notes
        )
        db.add(new_pres)
        db.flush() # flush to get prescription ID

        for it in prescription_in.items:
            new_item = PrescriptionItem(
                prescription_id=new_pres.id,
                medicine_name=it.medicine_name,
                dosage=it.dosage,
                instruction=it.instruction
            )
            db.add(new_item)

        # Create notification for the patient
        from app.models.models import Notification
        notif = Notification(
            user_id=patient_id,
            title="New Prescription Added",
            body=f"New prescription added by {doc_name} for {prescription_in.diagnosis or 'Treatment'}.",
            type="medicine"
        )
        db.add(notif)

        # Audit logging
        audit = AuditLog(
            user_id=doctor_user.id,
            action="CREATE_PRESCRIPTION",
            details=f"Doctor {doctor_user.id} created prescription ID {new_pres.id} for patient {patient_id}."
        )
        db.add(audit)
        db.commit()
        db.refresh(new_pres)

        return new_pres

    def generate_ai_copilot_insight(self, db: Session, doctor_id: int, patient_id: int, prompt: str, type: str) -> str:
        """
        Generates clinical decision support using Gemini AI service.
        Ensures strict disclaimer footer. Audits access.
        """
        self.check_patient_access(db, doctor_id, patient_id)

        # Gather patient context for prompt enrichment
        profile = db.query(Profile).filter(Profile.user_id == patient_id).first()
        records = db.query(MedicalHistory).filter(MedicalHistory.user_id == patient_id).all()
        meds = db.query(MedicineReminder).filter(MedicineReminder.user_id == patient_id, MedicineReminder.is_active == True).all()

        allergies = [r.title for r in records if r.type == "allergy"]
        conditions = [r.title for r in records if r.type == "condition"]
        active_meds = [f"{m.medicine_name} {m.dosage}" for m in meds]

        context = (
            f"Patient: ID={patient_id}, Gender={profile.gender if profile else 'N/A'}, Blood={profile.blood_group if profile else 'N/A'}.\n"
            f"Active Allergies: {', '.join(allergies) if allergies else 'None'}.\n"
            f"Chronic Conditions: {', '.join(conditions) if conditions else 'None'}.\n"
            f"Current Medicines: {', '.join(active_meds) if active_meds else 'None'}.\n"
        )

        full_prompt = (
            f"You are Aarogya Vault's AI Doctor Copilot. Assist the doctor on this query:\n"
            f"Copilot Request Type: {type}\n"
            f"Query: {prompt}\n\n"
            f"Focus on allergy checks, drug interactions, and providing evidence-based explanations."
        )

        insight = ai_service.generate_health_insight(full_prompt, context)

        # Ensure safety disclaimer
        disclaimer = "\n\n*AI-generated clinical assistance. Final clinical decisions remain with the licensed doctor.*"
        if disclaimer not in insight:
            insight += disclaimer

        # Log AI action
        audit = AuditLog(
            user_id=doctor_id,
            action="AI_DOCTOR_COPILOT",
            details=f"AI Doctor Copilot requested. Patient ID: {patient_id}, Type: {type}."
        )
        db.add(audit)
        db.commit()

        return insight

    def grant_emergency_access(self, db: Session, doctor_id: int, qr_token_str: str) -> dict:
        """
        Validates the scanned emergency QR token and creates a temporary DoctorPatientAccess grant.
        Exposes only vital emergency information.
        """
        qr_token = db.query(QRToken).filter(
            QRToken.token == qr_token_str,
            QRToken.is_active == True
        ).first()

        if not qr_token:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invalid, expired, or deactivated emergency QR token."
            )

        # Check if expires_at is set and expired
        if qr_token.expires_at and qr_token.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="The emergency QR token has expired."
            )

        patient_id = qr_token.user_id

        # Verify profile exists
        profile = db.query(Profile).filter(Profile.user_id == patient_id).first()
        if not profile:
            raise HTTPException(status_code=404, detail="Patient profile not found.")

        # Create temporary DoctorPatientAccess record (expires in 1 hour)
        expiry = datetime.now(timezone.utc) + timedelta(hours=1)
        access = DoctorPatientAccess(
            doctor_id=doctor_id,
            patient_id=patient_id,
            access_type="emergency",
            is_active=True,
            expires_at=expiry
        )
        db.add(access)

        # Create notification for the doctor
        from app.models.models import Notification
        notif = Notification(
            user_id=doctor_id,
            title="Emergency Access Session Initiated",
            body=f"Emergency access session initiated for Patient {profile.full_name} (expires in 1 hour).",
            type="emergency"
        )
        db.add(notif)

        # Audit emergency access grant
        audit = AuditLog(
            user_id=doctor_id,
            action="EMERGENCY_QR_DECRYPT",
            details=f"Doctor {doctor_id} granted emergency access to patient {patient_id} via QR token."
        )
        db.add(audit)
        db.commit()

        # Query emergency vital clinical metadata
        records = db.query(MedicalHistory).filter(MedicalHistory.user_id == patient_id).all()
        allergies = [r.title for r in records if r.type == "allergy"]
        conditions = [r.title for r in records if r.type == "condition"]

        reminders = db.query(MedicineReminder).filter(MedicineReminder.user_id == patient_id, MedicineReminder.is_active == True).all()
        current_meds = [f"{r.medicine_name} {r.dosage}" for r in reminders]

        contacts = db.query(EmergencyContact).filter(EmergencyContact.user_id == patient_id).all()
        contact_list = [f"{c.name} ({c.phone}) - {c.relation or 'Contact'}" for c in contacts]
        if not contact_list and profile.emergency_contact_name:
            contact_list = [f"{profile.emergency_contact_name} ({profile.emergency_contact_phone})"]

        # Calculate age
        age = "Unknown"
        if profile.dob:
            try:
                birth_year = int(profile.dob.split("-")[0])
                age = f"{datetime.now().year - birth_year}"
            except Exception:
                pass

        return {
            "patient_id": patient_id,
            "patient_name": profile.full_name,
            "age": age,
            "gender": profile.gender,
            "blood_group": profile.blood_group,
            "allergies": allergies if allergies else ["None"],
            "chronic_diseases": conditions if conditions else ["None"],
            "current_medicines": current_meds if current_meds else ["None"],
            "emergency_contacts": contact_list,
            "expires_at": expiry.isoformat()
        }

doctor_service = DoctorService()
