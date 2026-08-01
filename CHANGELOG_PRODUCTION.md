# Changelog — Production Release Hardening

All notable changes made during the Aarogya Vault v1.0.0-RC production readiness hardening phase.

---

## [1.0.0-RC] - 2026-08-01

### Added
- **Platform-Specific Firebase Options**: Added `firebase_options.dart` to both `aarogya_vault_app` and `apps/doctor_app`, enabling safe default initialization across Web, Android, and iOS.
- **Biometric Security Engine**: Implemented cryptographically secure 256-bit random token generation via `Random.secure()` in `settings_screen.dart` for biometric enrollments, replacing hardcoded strings.
- **Twilio SMS Provider Integration**: Added `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, and `TWILIO_VERIFY_SERVICE_SID` configurations on the FastAPI backend settings, allowing Twilio Verify OTP delivery in production environments.
- **Document Launching Support**: Added automatic medical report document launching in `medical_history_item.dart` via `url_launcher`.

### Fixed
- **Firebase Core Options Assert Crash**: Fixed Web initialization crash by passing `DefaultFirebaseOptions.currentPlatform` to `Firebase.initializeApp()`.
- **Firebase Initialization in Doctor App**: Initialized Firebase Core on startup in the Doctor App to resolve crashes during Phone OTP flows.
- **Biometric Session Token Sync**: Updated `loginWithBiometrics` in `AuthRepositoryImpl` to parse and store the access token and user ID in local secure storage, preventing auth session drops.
- **Multipart Form Upload 422 Error**: Wrapped `title`, `date`, and `report_type` parameters in `Form(...)` annotations in `reports.py` and `v1/reports.py` on the FastAPI backend, aligning with multipart form-data requests from Dio client.
- **Test Pollution Fix**: Cleaned up residual test user data (`ayaz_long_test@aarogyavault.com`) in `test_onboard.py` to prevent database uniqueness violations and ensure reproducible pytest runs.
- **Admin App Mock Data Catch Fallbacks**: Modified 24 screens in `super_admin` and `hospital_admin` apps to clear lists and trigger SnackBar error alerts on network exception instead of showing local mock data.

### Removed
- **Biometric Mock Key Bypasses**: Removed hardcoded `"mock_bio_token_for_device_2026"` bypasses.
- **Developer Bypasses in Production**: Restrained the development `/send-otp` bypass from operating in production environments.
