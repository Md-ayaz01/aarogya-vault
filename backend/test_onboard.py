import sys
import os
import json
from datetime import datetime, timedelta, timezone
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal, Base, engine
from app.models.models import User, Profile, DoctorProfile, AuditLog, ConsentSetting
from app.core.security import get_password_hash

TEST_EMAILS = [
    "test_patient_reg@aarogyavault.com",
    "test_patient_reg_dup@aarogyavault.com",
    "test_doctor_onb@aarogyavault.com",
    "test_doctor_onb_jwt@aarogyavault.com",
    "admin_onboarder@aarogyavault.com"
]

client = TestClient(app)

def setup_test_data():
    db = SessionLocal()
    # Identify test user IDs to selectively clean up
    test_users = db.query(User).filter(User.email.in_(TEST_EMAILS)).all()
    test_user_ids = [u.id for u in test_users]

    if test_user_ids:
        db.query(DoctorProfile).filter(DoctorProfile.user_id.in_(test_user_ids)).delete(synchronize_session=False)
        db.query(Profile).filter(Profile.user_id.in_(test_user_ids)).delete(synchronize_session=False)
        db.query(ConsentSetting).filter(ConsentSetting.user_id.in_(test_user_ids)).delete(synchronize_session=False)
        db.query(AuditLog).filter(AuditLog.user_id.in_(test_user_ids)).delete(synchronize_session=False)
        db.query(User).filter(User.id.in_(test_user_ids)).delete(synchronize_session=False)

    db.commit()
    db.close()


def test_patient_registration():
    print("--- TESTING PATIENT REGISTRATION / SIGN UP ---")
    setup_test_data()
    
    # 1. Register a Patient
    print("1. Registering new Patient...")
    reg_response = client.post("/api/v1/auth/register", json={
        "email": "test_patient_reg@aarogyavault.com",
        "phone": "+919999900010",
        "password": "Password123"
    })
    assert reg_response.status_code == 200, f"Expected 200, got {reg_response.status_code}: {reg_response.text}"
    reg_data = reg_response.json()
    assert "access_token" in reg_data
    assert "refresh_token" in reg_data
    assert reg_data["role"] == "patient"
    patient_id = reg_data["user_id"]
    print("   [PASS] Patient registered and JWT token returned.")

    # 2. Check Database records created
    print("2. Verifying Patient database records...")
    db = SessionLocal()
    patient_user = db.query(User).filter(User.id == patient_id).first()
    assert patient_user is not None
    assert patient_user.email == "test_patient_reg@aarogyavault.com"
    assert patient_user.phone == "+919999900010"
    assert patient_user.role == "patient"
    
    # Verify profile skeleton
    pat_profile = db.query(Profile).filter(Profile.user_id == patient_id).first()
    assert pat_profile is not None
    assert pat_profile.full_name == "New Patient"
    
    # Verify consent setting
    pat_consent = db.query(ConsentSetting).filter(ConsentSetting.user_id == patient_id).first()
    assert pat_consent is not None
    
    # Verify audit log
    pat_audit = db.query(AuditLog).filter(AuditLog.user_id == patient_id, AuditLog.action == "REGISTER").first()
    assert pat_audit is not None
    db.close()
    print("   [PASS] DB User, Profile, Consent, and Audit Log verified successfully.")

    # 3. Test duplicate email prevention
    print("3. Testing duplicate email prevention...")
    dup_email_res = client.post("/api/v1/auth/register", json={
        "email": "test_patient_reg@aarogyavault.com",
        "phone": "+919999900011",
        "password": "Password123"
    })
    assert dup_email_res.status_code == 400
    assert "Email already registered" in dup_email_res.json()["detail"]
    print("   [PASS] Duplicate email rejected.")

    # 4. Test duplicate phone prevention
    print("4. Testing duplicate phone prevention...")
    dup_phone_res = client.post("/api/v1/auth/register", json={
        "email": "test_patient_reg_dup@aarogyavault.com",
        "phone": "+919999900010",
        "password": "Password123"
    })
    assert dup_phone_res.status_code == 400
    assert "Phone already registered" in dup_phone_res.json()["detail"]
    print("   [PASS] Duplicate phone rejected.")

    # 5. Verify Password hashing via Login
    print("5. Verifying password hashing via successful login...")
    login_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient_reg@aarogyavault.com",
        "password": "Password123"
    })
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()
    
    # Invalid password login
    bad_login_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient_reg@aarogyavault.com",
        "password": "WrongPassword"
    })
    assert bad_login_res.status_code == 400
    print("   [PASS] Password hashing and login verified.")


def test_doctor_onboarding():
    print("\n--- TESTING DOCTOR ONBOARDING (CONTROLLED FLOW) ---")

    # 1. Access without authorization (expects 403)
    print("1. Testing onboarding doctor without credentials (expects 403)...")

    onboard_data = {
        "email": "test_doctor_onb@aarogyavault.com",
        "phone": "+919999900020",
        "password": "Password123",
        "full_name": "Dr. Onboarded Test",
        "registration_number": "D88889",
        "specialty": "Pediatrics",
        "hospital_name": "Onboard General Hospital"
    }
    res_unauth = client.post("/api/v1/auth/onboard-doctor", json=onboard_data)
    assert res_unauth.status_code == 403, f"Expected 403, got {res_unauth.status_code}"
    print("   [PASS] Unauthenticated access rejected.")

    # 2. Access using Patient JWT token (expects 403)
    print("2. Testing onboarding doctor with Patient token (expects 403)...")
    patient_login = client.post("/api/v1/auth/login", json={
        "email": "test_patient_reg@aarogyavault.com",
        "password": "Password123"
    })
    patient_token = patient_login.json()["access_token"]
    res_patient = client.post(
        "/api/v1/auth/onboard-doctor",
        json=onboard_data,
        headers={"Authorization": f"Bearer {patient_token}"}
    )
    assert res_patient.status_code == 403
    print("   [PASS] Patient access rejected.")

    # 3. Onboard Doctor using custom admin token header
    print("3. Onboarding doctor using custom X-Admin-Token header...")
    res_admin = client.post(
        "/api/v1/auth/onboard-doctor",
        json=onboard_data,
        headers={"X-Admin-Token": "aarogya_vault_admin_secret_2026"}
    )
    assert res_admin.status_code == 201, f"Expected 201, got {res_admin.status_code}: {res_admin.text}"
    onboard_res = res_admin.json()
    assert onboard_res["success"] is True
    doctor_id = onboard_res["data"]["doctor_id"]
    print("   [PASS] Doctor successfully onboarded via X-Admin-Token.")

    # 4. Verify Doctor database records
    print("4. Verifying Doctor database records...")
    db = SessionLocal()
    doc_user = db.query(User).filter(User.id == doctor_id).first()
    assert doc_user is not None
    assert doc_user.role == "doctor"
    
    doc_profile = db.query(DoctorProfile).filter(DoctorProfile.user_id == doctor_id).first()
    assert doc_profile is not None
    assert doc_profile.full_name == "Dr. Onboarded Test"
    assert doc_profile.registration_number == "D88889"
    assert doc_profile.specialty == "Pediatrics"
    assert doc_profile.is_verified is True
    
    doc_audit = db.query(AuditLog).filter(AuditLog.user_id == doctor_id, AuditLog.action == "ONBOARD_DOCTOR").first()
    assert doc_audit is not None
    db.close()
    print("   [PASS] Doctor User, DoctorProfile, and Audit Log verified in database.")

    # 5. Verify duplicate prevention (registration number, email, phone)
    print("5. Testing duplicate doctor onboarding prevention...")
    # Duplicate registration number
    res_dup_reg = client.post(
        "/api/v1/auth/onboard-doctor",
        json={
            "email": "test_doctor_onb2@aarogyavault.com",
            "phone": "+919999900021",
            "password": "Password123",
            "full_name": "Dr. Onboarded Test 2",
            "registration_number": "D88889", # Duplicate
            "specialty": "Pediatrics",
            "hospital_name": "Onboard General Hospital"
        },
        headers={"X-Admin-Token": "aarogya_vault_admin_secret_2026"}
    )
    assert res_dup_reg.status_code == 400
    assert "Doctor registration number already exists" in res_dup_reg.json()["detail"]
    print("   [PASS] Duplicate registration number rejected.")

    # 6. Test Authorized Admin User token onboarding
    print("6. Testing onboarding doctor using Admin role JWT...")
    # Create an admin user in DB
    db = SessionLocal()
    admin_user = User(
        email="admin_onboarder@aarogyavault.com",
        phone="+919999900030",
        hashed_password=get_password_hash("Password123"),
        role="admin"
    )
    db.add(admin_user)
    db.commit()
    db.close()
    
    # Login as admin to get JWT
    admin_login = client.post("/api/v1/auth/login", json={
        "email": "admin_onboarder@aarogyavault.com",
        "password": "Password123"
    })
    admin_token = admin_login.json()["access_token"]
    
    # Onboard doctor using Admin JWT
    res_admin_jwt = client.post(
        "/api/v1/auth/onboard-doctor",
        json={
            "email": "test_doctor_onb_jwt@aarogyavault.com",
            "phone": "+919999900040",
            "password": "Password123",
            "full_name": "Dr. Onboarded JWT",
            "registration_number": "D88890",
            "specialty": "Pediatrics",
            "hospital_name": "Onboard General Hospital"
        },
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    assert res_admin_jwt.status_code == 201
    print("   [PASS] Onboarded doctor successfully using admin JWT.")

    # 7. Doctor Login and Dashboard Access
    print("7. Testing onboarded Doctor login and dashboard access...")
    doc_login = client.post("/api/v1/auth/login", json={
        "email": "test_doctor_onb@aarogyavault.com",
        "password": "Password123"
    })
    assert doc_login.status_code == 200
    doc_token = doc_login.json()["access_token"]
    assert doc_login.json()["role"] == "doctor"
    
    # Access Doctor Dashboard
    doc_dash = client.get(
        "/api/v1/doctor/dashboard",
        headers={"Authorization": f"Bearer {doc_token}"}
    )
    assert doc_dash.status_code == 200
    assert doc_dash.json()["today_patients_count"] >= 0
    print("   [PASS] Doctor login and dashboard access verified.")


def test_register_ayaz123_and_validation():
    print("--- TESTING SPECIFIC PASSWORD AYAZ123 REGISTRATION AND VALIDATION ERRORS ---")
    # Clean test data
    db = SessionLocal()
    existing = db.query(User).filter(User.email == "ayaz_test@aarogyavault.com").first()
    if existing:
        db.query(Profile).filter(Profile.user_id == existing.id).delete()
        db.query(ConsentSetting).filter(ConsentSetting.user_id == existing.id).delete()
        db.query(AuditLog).filter(AuditLog.user_id == existing.id).delete()
        db.delete(existing)
        db.commit()
    db.close()

    # 1. Register with password = "ayaz123"
    reg_res = client.post("/api/v1/auth/register", json={
        "email": "ayaz_test@aarogyavault.com",
        "password": "ayaz123"
    })
    assert reg_res.status_code == 200, f"Expected 200, got {reg_res.status_code}: {reg_res.text}"
    reg_data = reg_res.json()
    assert "access_token" in reg_data
    assert reg_data["user_id"] > 0
    print("   [PASS] Registration succeeded with password = 'ayaz123'.")

    # 2. Login with password = "ayaz123"
    login_res = client.post("/api/v1/auth/login", json={
        "email": "ayaz_test@aarogyavault.com",
        "password": "ayaz123"
    })
    assert login_res.status_code == 200
    print("   [PASS] Login succeeded with password = 'ayaz123'.")

    # 3. Test HTTP 400 validation error (instead of 500) for > 72 bytes password
    long_pass = "x" * 100
    invalid_res = client.post("/api/v1/auth/register", json={
        "email": "ayaz_long_test@aarogyavault.com",
        "password": long_pass
    })
    assert invalid_res.status_code == 400, f"Expected 400, got {invalid_res.status_code}: {invalid_res.text}"
    assert "72 bytes" in invalid_res.json()["detail"]
    print("   [PASS] Long password returned HTTP 400 Validation Error instead of HTTP 500.")

    # Cleanup
    db = SessionLocal()
    user_to_del = db.query(User).filter(User.email == "ayaz_test@aarogyavault.com").first()
    if user_to_del:
        db.query(Profile).filter(Profile.user_id == user_to_del.id).delete()
        db.query(ConsentSetting).filter(ConsentSetting.user_id == user_to_del.id).delete()
        db.query(AuditLog).filter(AuditLog.user_id == user_to_del.id).delete()
        db.delete(user_to_del)
        db.commit()
    db.close()


if __name__ == "__main__":
    test_patient_registration()
    test_doctor_onboarding()
    test_register_ayaz123_and_validation()
    # Clean up test accounts after completion
    setup_test_data()
    print("\n--- ALL SIGN-UP AND DOCTOR ONBOARDING TESTS PASSED ---")
