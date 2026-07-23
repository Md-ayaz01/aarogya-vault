# API Documentation

Aarogya Vault API is completely documented via Swagger UI and ReDoc.

## Interactive Documentation Interfaces
- **Swagger UI**: `{API_BASE_URL}/docs`
- **ReDoc**: `{API_BASE_URL}/redoc`

## Standard Response Envelopes

### Success Envelope
```json
{
  "success": true,
  "data": { ... },
  "message": "Success"
}
```

### Error Envelope
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Reason details"
  }
}
```

## Major Endpoints

### Authentication (`/api/v1/auth`)
- `POST /auth/send-otp`: Sends verification SMS code.
- `POST /auth/verify-otp`: Validates SMS code, logs patient in, returns Access/Refresh tokens.
- `POST /auth/refresh`: Rotates active refresh tokens (RTR).
- `POST /auth/logout`: Revokes active refresh token.

### Clinical & Vitals (`/api/v1/profile`, `/api/v1/reports`, `/api/v1/prescriptions`, `/api/v1/reminders`)
- `GET /profile`: Profile demographics.
- `GET /medical-history`: Allergies and conditions.
- `POST /reports/upload`: Multi-part report file upload (PDF/PNG/JPG). Enforces 20MB limit and SHA-256 deduplication.

### Emergency QR Protocol
- `GET /api/v1/qr`: Fetch active emergency URL and token.
- `POST /api/v1/qr/regenerate`: Invalidates older QR tokens, generates new secure token.
- `GET /api/v1/emergency/access/{token}`: Public, unauthenticated clinical summary. Returns restricted demographic and vitals data.
