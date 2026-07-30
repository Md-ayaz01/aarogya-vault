import os
import sys

# Force development environment for testing
os.environ["ENVIRONMENT"] = "development"

from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.models import User, Profile, DoctorProfile

client = TestClient(app)

def test_hospital_backend_suite():
    print("\n--- STARTING HOSPITAL BACKEND TEST SUITE ---")
    db = SessionLocal()
    try:
        # 1. Login or create Hospital Admin user
        admin_user = db.query(User).filter(User.phone == "+919999988888").first()
        if not admin_user:
            admin_user = User(phone="+919999988888", role="hospital_admin")
            db.add(admin_user)
            db.commit()
            db.refresh(admin_user)
            profile = Profile(user_id=admin_user.id, full_name="Admin Chief")
            db.add(profile)
            db.commit()

        # Login via OTP verification endpoint to get admin token
        res_login = client.post("/api/v1/auth/verify-firebase-otp", json={"id_token": "mock_token_+919999988888"})
        assert res_login.status_code == 200
        admin_token = res_login.json()["access_token"]
        headers = {"Authorization": f"Bearer {admin_token}"}
        print("1. [PASS] Hospital Admin logged in successfully.")

        # 2. Test Dashboard Overview
        res_dash = client.get("/api/v1/hospital/dashboard/overview", headers=headers)
        assert res_dash.status_code == 200
        dash_data = res_dash.json()["data"]
        assert "total_patients" in dash_data
        assert "active_admissions" in dash_data
        print("2. [PASS] Hospital Dashboard Overview endpoint verified.")

        # 3. Test Patients Listing
        res_pts = client.get("/api/v1/hospital/patients", headers=headers)
        assert res_pts.status_code == 200
        print("3. [PASS] Hospital Patients list endpoint verified.")

        # 4. Test Doctors Listing
        res_docs = client.get("/api/v1/hospital/doctors", headers=headers)
        assert res_docs.status_code == 200
        print("4. [PASS] Hospital Doctors list endpoint verified.")

        # 5. Test Departments List & Create
        res_dept_list = client.get("/api/v1/hospital/departments", headers=headers)
        assert res_dept_list.status_code == 200
        res_dept_create = client.post("/api/v1/hospital/departments", json={"name": "Cardiology", "code": "CARD-01"}, headers=headers)
        assert res_dept_create.status_code in [200, 400]
        print("5. [PASS] Department Management endpoints verified.")

        # 6. Test Admissions & Beds
        res_adm = client.get("/api/v1/hospital/admissions", headers=headers)
        assert res_adm.status_code == 200
        res_beds = client.get("/api/v1/hospital/beds", headers=headers)
        assert res_beds.status_code == 200
        print("6. [PASS] Admissions & Ward Beds endpoints verified.")

        # 7. Test Laboratory & Radiology
        res_lab = client.get("/api/v1/hospital/laboratory", headers=headers)
        assert res_lab.status_code == 200
        res_rad = client.get("/api/v1/hospital/radiology", headers=headers)
        assert res_rad.status_code == 200
        print("7. [PASS] Lab and Radiology endpoints verified.")

        # 8. Test Pharmacy Inventory
        res_pharm = client.get("/api/v1/hospital/pharmacy/inventory", headers=headers)
        assert res_pharm.status_code == 200
        print("8. [PASS] Pharmacy Inventory endpoint verified.")

        # 9. Test Emergency Cases
        res_emerg = client.get("/api/v1/hospital/emergency", headers=headers)
        assert res_emerg.status_code == 200
        print("9. [PASS] Emergency cases endpoint verified.")

        # 10. Test AI Analytics & Risk Insights
        res_ai = client.get("/api/v1/hospital/analytics/ai-insights", headers=headers)
        assert res_ai.status_code == 200
        assert "risk_analysis" in res_ai.json()["data"]
        print("10. [PASS] AI Hospital Analytics endpoint verified.")

        # 11. Test Reports
        res_rep = client.get("/api/v1/hospital/reports/patients", headers=headers)
        assert res_rep.status_code == 200
        print("11. [PASS] Operational Reports endpoints verified.")

        # 12. Test Audit Logs
        res_audit = client.get("/api/v1/hospital/settings/audit-logs", headers=headers)
        assert res_audit.status_code == 200
        print("12. [PASS] Security Audit Logs endpoint verified.")

        print("--- ALL HOSPITAL BACKEND TEST ASSERTIONS PASSED SUCCESSFULLY ---")
    finally:
        db.close()

if __name__ == "__main__":
    test_hospital_backend_suite()
