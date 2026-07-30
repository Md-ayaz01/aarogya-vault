import os
os.environ["ENVIRONMENT"] = "development"

import unittest
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models.models import User, Profile

class TestSuperAdminAPIs(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = TestClient(app)
        db = SessionLocal()
        try:
            admin_user = db.query(User).filter(User.phone == "+919999999999").first()
            if not admin_user:
                admin_user = User(phone="+919999999999", role="super_admin")
                db.add(admin_user)
                db.commit()
                db.refresh(admin_user)
                profile = Profile(user_id=admin_user.id, full_name="Super Admin")
                db.add(profile)
                db.commit()
        finally:
            db.close()

        res = cls.client.post(
            "/api/v1/auth/verify-firebase-otp",
            json={"id_token": "mock_token_+919999999999"}
        )
        assert res.status_code == 200, f"Failed mock login: {res.text}"
        cls.token = res.json()["access_token"]
        cls.headers = {"Authorization": f"Bearer {cls.token}"}

    def test_dashboard(self):
        res = self.client.get("/api/v1/super_admin/dashboard/overview", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        data = res.json()
        self.assertIn("total_hospitals", data)

    def test_hospitals(self):
        res = self.client.get("/api/v1/super_admin/hospitals", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

    def test_doctors(self):
        res = self.client.get("/api/v1/super_admin/doctors", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

    def test_patients(self):
        res = self.client.get("/api/v1/super_admin/patients", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

    def test_users(self):
        res = self.client.get("/api/v1/super_admin/users", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

    def test_ai_control(self):
        res = self.client.get("/api/v1/super_admin/ai-control", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

    def test_ayushman(self):
        res = self.client.get("/api/v1/super_admin/ayushman", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIn("total_pmjay_hospitals", res.json())

    def test_audit(self):
        res = self.client.get("/api/v1/super_admin/audit", headers=self.headers)
        self.assertEqual(res.status_code, 200)
        self.assertIsInstance(res.json(), list)

if __name__ == "__main__":
    unittest.main()
