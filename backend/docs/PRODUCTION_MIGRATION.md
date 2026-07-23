# Aarogya Vault - Production Migration Plan (Final Enterprise Architecture)

Migrate Aarogya Vault backend to a robust, production-ready system utilizing FastAPI, Neon PostgreSQL, Alembic, Firebase Storage, Google Gemini, and Twilio Verify, without changing the Flutter UI design.

## User Review Required

> **API Versioning & Standardized Responses**: Prefixing all endpoints with `/api/v1`. Implements standard success/error responses with a response interceptor in Flutter's `api_client.dart` to preserve compatibility.
>
> **Request ID & Execution Timing Middleware**: Every API request will generate/propagate a correlation Request ID and log performance execution timing (logging target under 500ms).
>
> **Observability**: Structured JSON logging will be set up. Stack traces will never be exposed directly to API clients.
>
> **Comprehensive Enterprise Documentation**: We will generate dedicated docs under `docs/` folder: `API.md`, `DEPLOYMENT.md`, `DATABASE.md`, `ENVIRONMENT.md`, and `SECURITY.md`.
>
> **Clean Code Architecture**: Strictly decoupling logic: Routes -> Services -> Repositories -> Database (SOLID principles, Dependency Injection, Service Layer, Repository Pattern). Business logic will be kept out of route handlers.
>
> **Healthcare Data Privacy & Security (DPDP & ABDM Compliant)**:
> - Encrypt sensitive medical records/data at rest.
> - Strict TLS/HTTPS in production.
> - Never log OTPs, JWTs, credentials, or personally identifiable health information (PHI).
> - Restrict emergency access (`/api/v1/emergency/access/{token}`) strictly to emergency-safe parameters (Name, Age, Blood Group, Allergies, Emergency Contacts, Current Medications, and Medical Conditions).
> - Audit logging of all access requests to sensitive clinical profiles/reports.

## Open Questions

> 1. All datetime columns in PostgreSQL models will be standard UTC timestamps.
> 2. The Government Integration module will be initialized in `app/government` with structured provider classes (`provider.py`, `abdm_provider.py`, `pmjay_provider.py`, `abha_provider.py`, `nhfr_provider.py`, `hpr_provider.py`) returning "Not Configured" responses, allowing swap-in providers without altering core business logic.
> 3. Database operations will follow strict transaction management and utilize connection pooling for Neon PostgreSQL.

---

## Proposed Changes

### 1. Production Backend Structure & Configuration

Refactor files into the target folder layout.

#### [NEW] Target Folder Structure
```
app/
  api/            # API endpoints (v1 routes)
    v1/           # Version 1 endpoints (auth, profile, medical records, reports, emergency, government, monitoring)
  core/           # Config, Neon DB connection pooling, Structured Logger
  models/         # Database models (User, Profile, etc.)
  schemas/        # Pydantic schemas for request/response validation
  services/       # Business logic (e.g. profile, records)
  repositories/   # Database access layer
  middleware/     # Rate limiting, Audit logs, Secure headers, CORS, Correlation ID, Request Timing
  security/       # Password hashing, AES encryption/decryption, JWT
  storage/        # Firebase storage client
  notifications/  # Notification services (SMS, Push, Email)
  government/     # Pluggable ABDM/PMJAY/ABHA/NHFR/HPR provider abstraction module
  utils/          # Helper utilities (filename sanitization, SHA-256)
docs/             # Enterprise Documentation
  API.md          # API endpoints and request/response specifications
  DEPLOYMENT.md   # Deployment configuration and Render settings
  DATABASE.md     # Schema description and index configurations
  ENVIRONMENT.md  # Detailed environment variables explanation
  SECURITY.md     # Security policies and guidelines
```

#### [MODIFY] `requirements.txt`
- Add missing dependencies: `SQLAlchemy==2.0.28`, `alembic==1.13.1`, `python-dotenv==1.0.1`, `twilio==9.0.4`, `firebase-admin==6.5.0`, `slowapi==0.1.9`.

---

### 2. Database Models & Schema Migration

Restructure tables to support token lifecycle, enhanced logs, and secure QR features.

#### [NEW] `models.py`
- Rename table `medical_histories` to `medical_records`.
- Rename table `lab_reports` to `reports` and add `file_hash` (SHA-256) and `file_url` columns.
- Update `audit_logs` table: `id`, `user_id`, `action`, `ip_address`, `user_agent`, `endpoint`, `request_method`, `created_at`.
- Create `qr_tokens` table with indexes on `token`: `id`, `user_id`, `token` (256-bit cryptographically secure token), `is_active`, `expires_at`, `created_at`, `updated_at`.
- Create `otp_sessions` table: `id`, `phone`, `verification_sid`, `attempts_count`, `status`, `created_at`, `updated_at`.
- Create `refresh_tokens` table with index on `token`: `id`, `user_id`, `token`, `expires_at`, `is_revoked`, `created_at`.
- Create `emergency_contacts` table: `id`, `user_id`, `name`, `phone`, `relation`, `created_at`.

#### [NEW] `alembic migration scripts`
- Initialize Alembic environment via `alembic init migrations`.
- Configure `migrations/env.py` to read database configuration dynamically from environment variables and target `Base.metadata`.
- Autogenerate database schema migration with indexes on `email`, `phone`, `token` (QR and Refresh), `user_id`, and `created_at`.
- Support migration rollback procedures (`alembic downgrade`).

---

### 3. Authentication & API Endpoints (/api/v1)

Implement the versioned APIs under `/api/v1` with production-grade security logic.

#### [NEW] `auth.py`
- Connect Twilio Verify API client with Account SID, Auth Token, and Verify Service SID.
- Enforce maximum 3 verification attempts per OTP session (brute-force protection).
- Implement Refresh Token Rotation (RTR) and revocation.

#### [NEW] `emergency.py`
- `GET /qr`: Return active QR token URL.
- `POST /qr/regenerate`: Generate new 256-bit token, mark previous token as inactive, and return the new URL.
- `GET /emergency/access/{token}`: Public access endpoint returning restricted medical information without login.

#### [NEW] `reports.py`
- Limit uploads to 20MB. Validate MIME types (PDF, JPG, PNG).
- Compute SHA-256 file hashes to detect duplicate uploads.
- Upload reports securely to Firebase Storage.

#### [NEW] `government module`
- Create the abstraction layer in `government/provider.py`, `government/abdm_provider.py`, `government/pmjay_provider.py`, `government/abha_provider.py`, `government/nhfr_provider.py`, and `government/hpr_provider.py`.
- Pluggable interfaces: `hospital_service.py` and `doctor_service.py`.
- Mount `GET /government/hospitals`, `GET /government/hospitals/nearby`, and `GET /government/doctors` returning "Not Configured" placeholder messages.

#### [NEW] `notifications module`
- Set up separate handlers in `sms.py`, `email.py`, and `push.py` for notification scalability.

#### [NEW] `monitoring.py`
- Implement `GET /health` (status details), `GET /ready` (ready to accept connections), and `GET /live` (container liveness probe).

---

### 4. Containerization Support

Prepare files for Docker deployment.

#### [NEW] `Dockerfile`
- Multi-stage build for production-ready, lightweight container running FastAPI via Uvicorn.

#### [NEW] `docker-compose.yml`
- Development configuration mapping local volumes and setting up live reload.

---

### 5. Flutter Integration

Align connection variables in the Flutter client.

#### [MODIFY] `api_client.dart`
- Point base URL to `/api/v1` (e.g. `http://127.0.0.1:8000/api/v1` or env variable).
- Add response interceptor to intercept standardized responses, extraction `data` to handle compatibility with frozen UI models.

#### [MODIFY] `dashboard_provider.dart`
- Call `/api/v1/qr` to fetch the UUID token and store it.
- Correct profile, reminders, medical-history, and appointment API requests to include `/api/v1/`.

#### [MODIFY] `emergency_qr_screen.dart`
- Render the QR pointing to `/api/v1/emergency/access/{token}` when online.
- Maintain the offline encrypted fallback if offline.

---

## Verification Plan

### Automated Tests
Run the modified test suite verifying CRUD operations, AES helper functions, token validation, and mock API tests:
```bash
cd backend
python test_api.py
```

### Manual Verification
1. Run backend locally (`python run.py`) and inspect `/docs` Swagger API documentation page.
2. Verify endpoints in Swagger:
   - Request Twilio Verify SMS code via `/auth/send-otp`.
   - Validate code with `/auth/verify-otp`.
   - Verify JWT refresh token reissue via `/auth/refresh`.
   - Upload file to `/reports/upload` and confirm upload to Firebase Storage.
   - Verify AI Chat queries using a configured Gemini API key.
   - Retrieve QR token from `/qr` and fetch the restricted public data via `/emergency/access/{token}`.
