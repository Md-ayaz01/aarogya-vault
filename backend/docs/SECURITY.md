# Security Standards and Practices

Aarogya Vault implements industry-standard healthcare data protection mechanisms:

## 1. Data Encryption at Rest
- Sensitive patient demographics and clinical reports stored in the database are encrypted at rest using AES-256-CBC.
- Keys and IV parameters are synchronized with the Flutter client's `SecurityHelper`:
  - **Key**: `aarogya_vault_super_secure_secur` (32 bytes UTF-8)
  - **IV**: `aarogya_vault_iv` (16 bytes UTF-8)

## 2. Authentication and Sessions
- Passwords are encrypted using the standard `bcrypt` hashing algorithm.
- Access tokens utilize short-lived JWT signatures.
- Refresh Token Rotation (RTR) is enforced: when a client requests a new access token, the current refresh token is invalidated, and a new one is issued.
- Refresh tokens can be explicitly revoked at `/api/v1/auth/logout`.
- Standard API endpoints verify active authentication headers, while the Emergency access endpoint is unauthenticated but locked to cryptographically secure tokens.

## 3. Secure Emergency QR Protocol
- predictible IDs (e.g. integer IDs or UUIDs) are never exposed.
- A 256-bit cryptographically secure token is generated when creating a QR card.
- The public emergency endpoint `/api/v1/emergency/access/{token}` validates that the token is active.
- Access to this endpoint returns only a minimal, restricted emergency dataset: Name, Age, Blood Group, Allergies, Medical Conditions, Emergency Contacts, and active Medications. Full prescriptions, uploaded PDFs, or chat histories are strictly omitted to protect user privacy.

## 4. HTTPS and Middleware
- In `production` environment, Strict-Transport-Security (HSTS) is enabled.
- Security response headers are appended:
  - `X-Content-Type-Options: nosniff`
  - `X-Frame-Options: DENY`
  - `X-XSS-Protection: 1; mode=block`
  - `Referrer-Policy: no-referrer`
- CORS origin validation is strictly enforced based on configurations.
