import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal, engine, Base
from app.core.security import get_password_hash
from app.models import User, Profile, MedicalHistory, LabReport, Prescription, PrescriptionItem, MedicineReminder, Appointment, ConsentSetting, Notification, AIChatMessage, DoctorProfile, DoctorPatientAccess

def seed_database():
    print("Initializing database schemas...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # Check if user already exists
        user = db.query(User).filter((User.email == "majid@aarogyavault.com") | (User.phone == "+919876543210")).first()
        if not user:
            print("Creating test user: majid@aarogyavault.com...")
            user = User(
                email="majid@aarogyavault.com",
                phone="+919876543210",
                hashed_password=get_password_hash("Password123"),
                biometric_token_hash="mock_bio_token_for_device_2026",
                role="patient"
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            user.email = "majid@aarogyavault.com"
            user.phone = "+919876543210"
            if not user.hashed_password:
                user.hashed_password = get_password_hash("Password123")
            user.role = "patient"
            db.commit()

        # Check if test doctor exists
        doctor = db.query(User).filter(User.email == "doctor@aarogyavault.com").first()
        if not doctor:
            print("Creating test doctor: doctor@aarogyavault.com...")
            doctor = User(
                email="doctor@aarogyavault.com",
                phone="+919999988888",
                hashed_password=get_password_hash("Password123"),
                role="doctor"
            )
            db.add(doctor)
            db.commit()
            db.refresh(doctor)

            # Create Doctor Profile
            doc_profile = DoctorProfile(
                user_id=doctor.id,
                full_name="Dr. Ravi Sharma",
                registration_number="D12345",
                specialty="Cardiology",
                hospital_name="Apollo Hospital, Indore",
                is_verified=True
            )
            db.add(doc_profile)
            db.commit()

        # Create Profile
        profile = db.query(Profile).filter(Profile.user_id == user.id).first()
        if not profile:
            print("Creating patient profile details...")
            profile = Profile(
                user_id=user.id,
                full_name="Majid Shaikh",
                dob="1998-01-12",
                gender="Male",
                blood_group="O+",
                address="Dewas, Madhya Pradesh, India",
                emergency_contact_name="Sikandar Shaikh (Father)",
                emergency_contact_phone="+91 91234 56789",
                aadhaar_number="XXXX XXXX 1234",
                health_score=92
            )
            db.add(profile)

        # Create Medical History items
        if db.query(MedicalHistory).filter(MedicalHistory.user_id == user.id).count() == 0:
            print("Creating medical history records...")
            histories = [
                MedicalHistory(user_id=user.id, type="condition", title="Chronic Diseases", description="No chronic disease diagnosed.", date_recorded="2026-05-10"),
                MedicalHistory(user_id=user.id, type="allergy", title="Allergies", description="Penicillin, Pollen", date_recorded="2024-03-05"),
                MedicalHistory(user_id=user.id, type="surgery", title="Surgeries", description="Appendectomy (2019)", date_recorded="2019-08-20"),
                MedicalHistory(user_id=user.id, type="family", title="Family History", description="Diabetes, Hypertension", date_recorded="2025-11-15"),
                MedicalHistory(user_id=user.id, type="vaccination", title="Vaccination", description="Up to date (Hep B, Covid Booster)", date_recorded="2025-01-10"),
            ]
            for h in histories:
                db.add(h)

        # Create Lab Reports
        if db.query(LabReport).filter(LabReport.user_id == user.id).count() == 0:
            print("Creating diagnostic lab reports...")
            reports = [
                LabReport(
                    user_id=user.id,
                    title="Blood Report",
                    date="12 Apr 2024",
                    type="Lab",
                    status="Final",
                    file_name="blood_report_20240412.pdf",
                    summary="AI Summary: Hemoglobin, platelets, and white blood cell count are within healthy limits. Fasting glucose is 98 mg/dL. Suggest monitoring sugar intake."
                ),
                LabReport(
                    user_id=user.id,
                    title="X-Ray Chest",
                    date="05 Mar 2024",
                    type="Imaging",
                    status="Final",
                    file_name="chest_xray_20240305.pdf",
                    summary="AI Summary: Lungs are clear. Normal cardiac outline. No active structural lesions."
                ),
                LabReport(
                    user_id=user.id,
                    title="MRI Brain",
                    date="22 Feb 2024",
                    type="Imaging",
                    status="Final",
                    file_name="mri_brain_20240222.pdf",
                    summary="AI Summary: Normal MRI scan. No indicators of mass effect or acute infarction."
                ),
                LabReport(
                    user_id=user.id,
                    title="ECG Report",
                    date="18 Jan 2024",
                    type="Lab",
                    status="Final",
                    file_name="ecg_report_20240118.pdf",
                    summary="AI Summary: Normal sinus rhythm. Heart rate 72 bpm."
                ),
                LabReport(
                    user_id=user.id,
                    title="CT Scan Abdomen",
                    date="10 Dec 2023",
                    type="Imaging",
                    status="Final",
                    file_name="ct_abdomen_20231210.pdf",
                    summary="AI Summary: Unremarkable abdominal organs. No abnormalities detected."
                ),
            ]
            for r in reports:
                db.add(r)

        # Create Reminders
        if db.query(MedicineReminder).filter(MedicineReminder.user_id == user.id).count() == 0:
            print("Creating medicine reminders...")
            reminders = [
                MedicineReminder(user_id=user.id, medicine_name="Paracetamol", dosage="650mg", time="08:00 AM", instruction="1 Tablet After Food", is_active=True, status="Taken"),
                MedicineReminder(user_id=user.id, medicine_name="Azithromycin", dosage="500mg", time="02:00 PM", instruction="1 Tablet After Food", is_active=True, status="Pending"),
                MedicineReminder(user_id=user.id, medicine_name="Cetirizine", dosage="10mg", time="08:00 PM", instruction="1 Tablet Before Sleep", is_active=True, status="Pending"),
            ]
            for rem in reminders:
                db.add(rem)

        # Create Prescription
        if db.query(Prescription).filter(Prescription.user_id == user.id).count() == 0:
            print("Creating prescriptions...")
            doc_user = db.query(User).filter(User.email == "doctor@aarogyavault.com").first()
            doc_id = doc_user.id if doc_user else None
            prescription = Prescription(
                user_id=user.id,
                doctor_id=doc_id,
                doctor_name="Dr. Ravi Sharma",
                specialty="MBBS, MD (Medicine)\nApollo Hospital, Indore",
                date="12 Apr 2024",
                diagnosis="Viral Fever",
                notes="Take rest and drink plenty of fluids."
            )
            db.add(prescription)
            db.commit() # Save prescription so we get an ID
            
            items = [
                PrescriptionItem(prescription_id=prescription.id, medicine_name="Paracetamol 650mg", dosage="1 Tablet", instruction="1-0-1 After Food"),
                PrescriptionItem(prescription_id=prescription.id, medicine_name="Azithromycin 500mg", dosage="1 Tablet", instruction="0-0-1 After Food"),
                PrescriptionItem(prescription_id=prescription.id, medicine_name="Cetirizine 10mg", dosage="1 Tablet", instruction="0-0-1 Before Sleep"),
            ]
            for it in items:
                db.add(it)

        # Create Appointments
        if db.query(Appointment).filter(Appointment.user_id == user.id).count() == 0:
            print("Creating appointments...")
            doc_user = db.query(User).filter(User.email == "doctor@aarogyavault.com").first()
            doc_id = doc_user.id if doc_user else None
            appointments = [
                Appointment(user_id=user.id, doctor_id=doc_id, doctor_name="Dr. Ravi Sharma", specialty="Cardiologist", date_time="2026-07-20 10:00 AM", status="Upcoming"),
                Appointment(user_id=user.id, doctor_name="Dr. Ananya Goel", specialty="Dermatologist", date_time="2026-07-10 04:30 PM", status="Completed"),
            ]
            for a in appointments:
                db.add(a)

        # Create default Consent Settings
        consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == user.id).first()
        if not consent:
            print("Creating privacy settings...")
            consent = ConsentSetting(
                user_id=user.id,
                allow_ai_profile_read=True,
                allow_ai_records_read=True,
                allow_emergency_profile_read=True,
                allow_emergency_records_read=True
            )
            db.add(consent)

        # Create default Notifications
        if db.query(Notification).filter(Notification.user_id == user.id).count() == 0:
            print("Creating default notifications...")
            notifications = [
                Notification(
                    user_id=user.id,
                    title="Medicine Reminder",
                    body="It's time to take your Paracetamol 650mg tablet.",
                    type="medicine",
                    is_read=False
                ),
                Notification(
                    user_id=user.id,
                    title="Appointment Confirmation",
                    body="Your appointment with Dr. Ravi Sharma is confirmed for July 20 at 10:00 AM.",
                    type="appointment",
                    is_read=True
                ),
                Notification(
                    user_id=user.id,
                    title="Emergency Contact Synced",
                    body="Sikandar Shaikh has been set as your primary emergency contact.",
                    type="emergency",
                    is_read=False
                ),
            ]
            for n in notifications:
                db.add(n)

        # Create default AI Chat Messages
        if db.query(AIChatMessage).filter(AIChatMessage.user_id == user.id).count() == 0:
            print("Creating demo chat messages...")
            chat_messages = [
                AIChatMessage(
                    user_id=user.id,
                    message="Can you explain my last blood report glucose level?",
                    is_user=True
                ),
                AIChatMessage(
                    user_id=user.id,
                    message="Certainly! In your blood report from 12 Apr 2024, your fasting glucose level is 98 mg/dL. While this is within the normal limit (< 100 mg/dL), it is near the upper limit. I recommend monitoring sugar intake, eating balanced meals, and staying active.",
                    is_user=False
                ),
            ]
            for msg in chat_messages:
                db.add(msg)

        db.commit()
        print("\n--- DATABASE SEEDED SUCCESSFULLY ---")
    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
