# Environment Variables Documentation

This document lists and explains all configuration variables required by the Aarogya Vault backend.

## Variables

### Core Configuration
- `ENVIRONMENT`: Options: `development` | `staging` | `production`. Adjusts logging level, CORS checks, and enforces HTTPS.
- `SECRET_KEY`: Long, secure, cryptographically random key used for signing JWT Access and Refresh tokens.
- `DATABASE_URL`: Connection string for the Neon PostgreSQL database (e.g. `postgresql://user:pass@host/db`). Falls back to SQLite for local development if unset.
- `API_BASE_URL`: The fully qualified public root endpoint of the backend (e.g. `https://aarogya-vault.onrender.com/api/v1`). Used for generating public URLs for emergency access and fallback local uploads.

### Services Integrations

#### Google Gemini API
- `GEMINI_API_KEY`: API key for accessing Google's Gemini LLMs. Uses model `gemini-1.5-flash` with strict clinical guidelines.

#### Firebase Cloud Storage
- `FIREBASE_PROJECT_ID`: ID of the Firebase Project.
- `FIREBASE_STORAGE_BUCKET`: Storage bucket hostname (e.g. `aarogya-vault.appspot.com`).
- `FIREBASE_CREDENTIALS_PATH`: Absolute or relative path to the Firebase Service Account JSON file.

### Limits
- `MAX_UPLOAD_SIZE_MB`: Maximum file size permitted for reports upload (Default: `20`).
- `LOG_LEVEL`: Logging verbosity (`DEBUG`, `INFO`, `WARNING`, `ERROR`).
- `CORS_ALLOWED_ORIGINS`: Comma-separated list of allowed origins (e.g. `http://localhost:3000,http://127.0.0.1:8000`). Defaults to `*` if empty.
