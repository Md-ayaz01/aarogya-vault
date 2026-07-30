import sys
import os
import json
from datetime import datetime, timedelta, timezone
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal, Base, engine
from app.models.models import User, Profile, DoctorProfile, DoctorPatientAccess, Prescription, PrescriptionItem, AuditLog, QRToken, Appointment, Notification
from app.core.security import get_password_hash

client = TestClient(app)

def setup_test_data():
    db = SessionLocal()
    # Clean up test accounts if they exist
    db.query(Notification).delete()
    db.query(Appointment).delete()
    db.query(DoctorPatientAccess).delete()
    db.query(PrescriptionItem).delete()
    db.query(Prescription).delete()
    db.query(DoctorProfile).delete()
    db.query(QRToken).delete()
    db.query(Profile).delete()
    db.query(AuditLog).delete()
    db.query(User).filter(User.email.in_(["test_patient@aarogyavault.com", "test_doctor@aarogyavault.com", "unauth_doctor@aarogyavault.com"])).delete()
    db.commit()


    # Create Patient User
    patient = User(
        email="test_patient@aarogyavault.com",
        phone="+919999900001",
        hashed_password=get_password_hash("Password123"),
        role="patient"
    )
    db.add(patient)
    db.commit()
    db.refresh(patient)

    pat_profile = Profile(
        user_id=patient.id,
        full_name="Test Patient",
        dob="1990-01-01",
        gender="Male",
        blood_group="O+",
        health_score=90
    )
    db.add(pat_profile)
    db.commit()

    # Create Authorized Doctor User
    doctor = User(
        email="test_doctor@aarogyavault.com",
        phone="+919999900002",
        hashed_password=get_password_hash("Password123"),
        role="doctor"
    )
    db.add(doctor)
    db.commit()
    db.refresh(doctor)

    doc_profile = DoctorProfile(
        user_id=doctor.id,
        full_name="Test Doctor",
        registration_number="D99999",
        specialty="Cardiology",
        hospital_name="Test General Hospital",
        is_verified=True
    )
    db.add(doc_profile)
    db.commit()

    # Create Unauthorized Doctor User
    unauth_doctor = User(
        email="unauth_doctor@aarogyavault.com",
        phone="+919999900003",
        hashed_password=get_password_hash("Password123"),
        role="doctor"
    )
    db.add(unauth_doctor)
    db.commit()
    db.refresh(unauth_doctor)

    unauth_doc_profile = DoctorProfile(
        user_id=unauth_doctor.id,
        full_name="Unauth Doctor",
        registration_number="D88888",
        specialty="Dermatology",
        hospital_name="Test Dermatology Clinic",
        is_verified=True
    )
    db.add(unauth_doc_profile)
    db.commit()

    # Create QR token for patient
    qr_token = QRToken(
        user_id=patient.id,
        token="test_qr_token_xyz_123",
        is_active=True
    )
    db.add(qr_token)
    db.commit()

    # Create test appointment
    appointment = Appointment(
        user_id=patient.id,
        doctor_id=doctor.id,
        doctor_name="Test Doctor",
        specialty="Cardiology",
        date_time="2026-07-20 10:30 AM",
        status="Upcoming"
    )
    db.add(appointment)
    db.commit()

    pat_id = patient.id
    doc_id = doctor.id
    unauth_doc_id = unauth_doctor.id
    db.close()
    return pat_id, doc_id, unauth_doc_id


def test_doctor_app_workflows():
    print("--- STARTING DOCTOR WORKFLOW TEST SUITE ---")
    patient_id, doctor_id, unauth_doctor_id = setup_test_data()

    # 1. Login Patient
    print("1. Logging in Patient...")
    patient_login = client.post("/api/v1/auth/verify-firebase-otp", json={
        "id_token": "mock_token_+919999900001"
    })
    assert patient_login.status_code == 200, "Patient login failed"
    patient_token = patient_login.json()["access_token"]
    patient_headers = {"Authorization": f"Bearer {patient_token}"}
    print("   [PASS] Patient logged in successfully.")

    # 2. Login Doctor
    print("2. Logging in Authorized Doctor...")
    doctor_login = client.post("/api/v1/auth/verify-firebase-otp", json={
        "id_token": "mock_token_+919999900002"
    })
    assert doctor_login.status_code == 200, "Doctor login failed"
    doctor_token = doctor_login.json()["access_token"]
    doctor_headers = {"Authorization": f"Bearer {doctor_token}"}
    print("   [PASS] Doctor logged in successfully.")

    # 3. Login Unauthorized Doctor
    print("3. Logging in Unauthorized Doctor...")
    unauth_doctor_login = client.post("/api/v1/auth/verify-firebase-otp", json={
        "id_token": "mock_token_+919999900003"
    })
    assert unauth_doctor_login.status_code == 200, "Unauthorized doctor login failed"
    unauth_doctor_token = unauth_doctor_login.json()["access_token"]
    unauth_doctor_headers = {"Authorization": f"Bearer {unauth_doctor_token}"}
    print("   [PASS] Unauthorized doctor logged in successfully.")


    # 4. Patient attempts doctor dashboard -> 403
    print("4. Testing Patient accessing doctor dashboard (expects 403)...")
    dashboard_res = client.get("/api/v1/doctor/dashboard", headers=patient_headers)
    assert dashboard_res.status_code == 403, f"Expected 403, got {dashboard_res.status_code}"
    print("   [PASS] Patient access forbidden successfully.")

    # 5. Doctor accesses doctor dashboard -> 200
    print("5. Testing Doctor accessing doctor dashboard (expects 200)...")
    dashboard_res = client.get("/api/v1/doctor/dashboard", headers=doctor_headers)
    assert dashboard_res.status_code == 200, f"Expected 200, got {dashboard_res.status_code}"
    print("   [PASS] Doctor dashboard retrieved successfully.")

    # 6. Unauthorized doctor accesses patient profile -> 403
    print("6. Testing Unauthorized Doctor accessing patient profile (expects 403)...")
    profile_res = client.get(f"/api/v1/doctor/patients/{patient_id}/profile", headers=unauth_doctor_headers)
    assert profile_res.status_code == 403, f"Expected 403, got {profile_res.status_code}"
    print("   [PASS] Unauthorized patient access rejected successfully.")

    # 7. Doctor searches patient -> returns basic matching detail
    print("7. Testing Doctor searching for patient by phone number...")
    search_res = client.get("/api/v1/doctor/patients/search?query=+919999900001", headers=doctor_headers)
    assert search_res.status_code == 200
    results = search_res.json()
    assert len(results) > 0
    patient_match = next((r for r in results if r["patient_id"] == patient_id), None)
    assert patient_match is not None, "Test Patient not found in search results"
    assert patient_match["full_name"] == "Test Patient"
    assert patient_match["has_access"] is False, "Doctor should not have full access yet"
    print("   [PASS] Search returned basic info without full access.")


    # 8. Grant access to doctor (consent type)
    print("8. Granting DoctorPatientAccess to Authorized Doctor...")
    db = SessionLocal()
    access = DoctorPatientAccess(
        doctor_id=doctor_id,
        patient_id=patient_id,
        access_type="consent",
        is_active=True
    )
    db.add(access)
    db.commit()
    db.close()
    print("   [PASS] DoctorPatientAccess granted.")

    # 9. Doctor accesses profile with active access -> 200
    print("9. Testing Authorized Doctor accessing patient profile (expects 200)...")
    profile_res = client.get(f"/api/v1/doctor/patients/{patient_id}/profile", headers=doctor_headers)
    assert profile_res.status_code == 200, f"Expected 200, got {profile_res.status_code}"
    assert profile_res.json()["blood_group"] == "O+"
    print("   [PASS] Authorized doctor fetched patient details successfully.")

    # 10. Doctor accesses timeline -> 200
    print("10. Testing Authorized Doctor accessing patient medical timeline...")
    timeline_res = client.get(f"/api/v1/doctor/patients/{patient_id}/timeline", headers=doctor_headers)
    assert timeline_res.status_code == 200
    print("    [PASS] Timeline retrieved successfully.")

    # 11. Test Expired access -> 403
    print("11. Testing expired DoctorPatientAccess rejection...")
    db = SessionLocal()
    db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.doctor_id == doctor_id,
        DoctorPatientAccess.patient_id == patient_id
    ).update({"expires_at": datetime.now(timezone.utc) - timedelta(hours=1)})
    db.commit()
    db.close()

    profile_res = client.get(f"/api/v1/doctor/patients/{patient_id}/profile", headers=doctor_headers)
    assert profile_res.status_code == 403
    print("    [PASS] Expired access rejected successfully.")

    # 12. Test Revoked access -> 403
    print("12. Testing revoked DoctorPatientAccess rejection...")
    db = SessionLocal()
    db.query(DoctorPatientAccess).filter(
        DoctorPatientAccess.doctor_id == doctor_id,
        DoctorPatientAccess.patient_id == patient_id
    ).update({
        "is_active": False,
        "revoked_at": datetime.now(timezone.utc),
        "expires_at": None
    })
    db.commit()
    db.close()

    profile_res = client.get(f"/api/v1/doctor/patients/{patient_id}/profile", headers=doctor_headers)
    assert profile_res.status_code == 403
    print("    [PASS] Revoked access rejected successfully.")

    # 13. Emergency QR code verification access -> 200
    print("13. Testing temporary Emergency QR Access creation...")
    emergency_res = client.post("/api/v1/doctor/emergency-access", json={
        "qr_token": "test_qr_token_xyz_123"
    }, headers=doctor_headers)
    assert emergency_res.status_code == 200
    data = emergency_res.json()
    assert data["patient_name"] == "Test Patient"
    assert data["blood_group"] == "O+"
    print("    [PASS] Temporary emergency access established successfully.")

    # Check that audit log was created for emergency access
    db = SessionLocal()
    audit = db.query(AuditLog).filter(
        AuditLog.user_id == doctor_id,
        AuditLog.action == "EMERGENCY_QR_DECRYPT"
    ).first()
    assert audit is not None, "Emergency QR access must create an audit log"
    db.close()
    print("    [PASS] Audit log for emergency QR access created successfully.")

    # 14. Doctor writes a prescription -> transaction & audit log
    print("14. Testing Doctor creating a Prescription...")
    prescription_res = client.post("/api/v1/doctor/prescriptions", json={
        "patient_id": patient_id,
        "diagnosis": "Seasonal Allergies",
        "notes": "Avoid allergens.",
        "items": [
            {"medicine_name": "Cetirizine 10mg", "dosage": "1 Tablet", "instruction": "0-0-1 Before Sleep"}
        ]
    }, headers=doctor_headers)
    assert prescription_res.status_code == 200
    print("    [PASS] Prescription created successfully.")

    # Verify audit log and DB items
    db = SessionLocal()
    audit_pres = db.query(AuditLog).filter(
        AuditLog.user_id == doctor_id,
        AuditLog.action == "CREATE_PRESCRIPTION"
    ).first()
    assert audit_pres is not None, "Creating prescription must write an audit log"
    
    prescription_db = db.query(Prescription).filter(Prescription.user_id == patient_id).first()
    assert prescription_db is not None
    assert len(prescription_db.items) == 1
    db.close()
    print("    [PASS] Verified prescription items and audit logging in DB.")

    # 15. AI Copilot test sandbox responses
    print("15. Testing AI Doctor Copilot response fallback...")
    copilot_res = client.post("/api/v1/doctor/ai/copilot", json={
        "patient_id": patient_id,
        "prompt": "Analyze allergies and cetirizine dosage",
        "type": "summary"
    }, headers=doctor_headers)
    assert copilot_res.status_code == 200
    insight = copilot_res.json()["data"]["insight"]
    assert "AI-generated clinical assistance" in insight
    assert "Cetirizine" in insight or "Medication Analysis" in insight
    print("    [PASS] AI Copilot sandbox response verification complete.")

    # 16. Testing Doctor appointments retrieval
    print("16. Testing Doctor appointments endpoint...")
    appointments_res = client.get("/api/v1/doctor/appointments", headers=doctor_headers)
    assert appointments_res.status_code == 200
    appts = appointments_res.json()["data"]
    assert len(appts) >= 1
    assert appts[0]["patient_name"] == "Test Patient"
    assert appts[0]["status"] == "Upcoming"
    print("    [PASS] Doctor appointments fetched and verified successfully.")

    # 17. Testing Doctor appointment status update
    print("17. Testing Doctor appointment status update...")
    appt_id = appts[0]["id"]
    status_res = client.patch(f"/api/v1/doctor/appointments/{appt_id}/status?status=Completed", headers=doctor_headers)
    assert status_res.status_code == 200
    assert status_res.json()["data"]["status"] == "Completed"
    print("    [PASS] Doctor updated appointment status successfully.")

    # 18. Testing Doctor notifications endpoints
    print("18. Testing Doctor notifications endpoints...")
    notif_res = client.get("/api/v1/notifications", headers=doctor_headers)
    assert notif_res.status_code == 200
    doctor_notifs = notif_res.json()
    assert len(doctor_notifs) >= 1
    assert "Emergency Access" in doctor_notifs[0]["title"]

    # Verify read all endpoint for doctor
    read_all_res = client.post("/api/v1/notifications/read-all", headers=doctor_headers)
    assert read_all_res.status_code == 200

    # Verify they are now read
    notif_res = client.get("/api/v1/notifications", headers=doctor_headers)
    for n in notif_res.json():
        assert n["is_read"] == True
    print("    [PASS] Doctor notifications retrieval and read-all verified successfully.")

    # Clean up test accounts
    db = SessionLocal()
    db.query(Notification).delete()
    db.query(Appointment).delete()
    db.query(DoctorPatientAccess).delete()
    db.query(PrescriptionItem).delete()
    db.query(Prescription).delete()
    db.query(DoctorProfile).delete()
    db.query(QRToken).delete()
    db.query(Profile).delete()
    db.query(AuditLog).delete()
    db.query(User).filter(User.email.in_(["test_patient@aarogyavault.com", "test_doctor@aarogyavault.com", "unauth_doctor@aarogyavault.com"])).delete()
    db.commit()
    db.close()

if __name__ == "__main__":
    test_doctor_app_workflows()
    print("\n--- ALL DOCTOR BACKEND TEST WORKFLOWS PASSED ---")

