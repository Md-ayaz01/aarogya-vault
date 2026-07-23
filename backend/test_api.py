import sys
import os
import json
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.core.database import SessionLocal, engine, Base
from app.core.security import get_password_hash, verify_password, create_access_token, verify_token, encrypt_data, decrypt_data
from app.models import User, Profile, MedicalHistory, MedicineReminder

def generate_gemini_content(prompt: str) -> str:
    from app.services.ai import ai_service
    return ai_service.generate_health_insight(prompt)

def test_security_utilities():
    print("1. Testing AES Encryption / Decryption...")
    text = "Restricted Medical Record: Majid Shaikh, O+"
    encrypted = encrypt_data(text)
    assert encrypted != text, "Encryption failed to transform clear text"
    decrypted = decrypt_data(encrypted)
    assert decrypted == text, f"Decryption failed. Expected: '{text}', Got: '{decrypted}'"
    print("   [PASS] AES functions verified successfully.")

    print("2. Testing JWT Token Operations...")
    token = create_access_token(subject="999")
    sub = verify_token(token)
    assert sub == "999", f"Token verification failed. Expected sub: '999', Got: '{sub}'"
    print("   [PASS] JWT functions verified successfully.")

def test_database_and_models():
    print("3. Testing Database CRUD and Model Schemas...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    # Clean up existing test user if exists
    test_user = db.query(User).filter(User.email == "integration_test@aarogyavault.com").first()
    if test_user:
        db.query(Profile).filter(Profile.user_id == test_user.id).delete()
        db.query(MedicalHistory).filter(MedicalHistory.user_id == test_user.id).delete()
        db.query(MedicineReminder).filter(MedicineReminder.user_id == test_user.id).delete()
        db.delete(test_user)
        db.commit()

    # Create User
    pwd_hash = get_password_hash("TestPassword123")
    user = User(email="integration_test@aarogyavault.com", hashed_password=pwd_hash)
    db.add(user)
    db.commit()
    db.refresh(user)
    assert user.id > 0, "Failed to create User record"

    # Create Profile
    profile = Profile(
        user_id=user.id,
        full_name="Integration Patient",
        dob="1995-05-15",
        gender="Female",
        blood_group="AB-",
        address="Test Lab Environment",
        emergency_contact_name="Tester Contact",
        emergency_contact_phone="+91 88888 77777",
        aadhaar_number="XXXX XXXX 9999",
        health_score=95
    )
    db.add(profile)
    db.commit()
    db.refresh(profile)
    assert profile.full_name == "Integration Patient", "Profile mapping mismatch"

    # Create History
    history = MedicalHistory(
        user_id=user.id,
        type="allergy",
        title="Drug Allergy",
        description="Sulfa drugs",
        date_recorded="2026-07-15"
    )
    db.add(history)
    db.commit()
    db.refresh(history)
    assert history.description == "Sulfa drugs"

    # Clean up test user
    db.query(Profile).filter(Profile.user_id == user.id).delete()
    db.query(MedicalHistory).filter(MedicalHistory.user_id == user.id).delete()
    db.delete(user)
    db.commit()
    db.close()
    print("   [PASS] DB CRUD and Model validation complete.")

def test_ai_response():
    print("4. Testing AI Health Assistant Fallback Engine...")
    blood_prompt = "Explain my Fasting Glucose blood report values"
    response = generate_gemini_content(blood_prompt)
    assert "Glucose" in response or "glucose" in response, "AI response failed to provide glucose details"
    
    general_prompt = "What features do you support?"
    response2 = generate_gemini_content(general_prompt)
    assert "AI" in response2 or "Assistant" in response2, "AI fallback greeting failed"
    print("   [PASS] AI Assistant mock engine verified successfully.")

if __name__ == "__main__":
    print("--- STARTING BACKEND INTEGRATION TEST SUITE ---")
    test_security_utilities()
    print("")
    test_database_and_models()
    print("")
    test_ai_response()
    print("\n--- ALL BACKEND TEST ASSERTIONS PASSED SUCCESSFULLY ---")
