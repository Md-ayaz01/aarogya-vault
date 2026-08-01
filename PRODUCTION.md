# Aarogya Vault - Production Migration Guide

Version: 1.0
Status: Ready for Implementation

---

# Objective

Convert the current mock/demo application into a complete production-ready healthcare platform WITHOUT changing any Flutter UI.

The UI is considered FINAL.

Only backend, APIs, authentication, cloud storage, AI integration, and deployment should be implemented.

---

# Current Project Status

## Flutter UI

All UI screens are complete.

- Splash Screen
- Onboarding
- Login
- Registration
- Dashboard
- Profile
- Medical History
- Reports
- Prescriptions
- Emergency QR
- Emergency Access
- AI Health Assistant
- Police Access
- Medicine Reminder
- Settings

DO NOT redesign or modify the UI.

---

# Current Backend Status

Current backend is only a mock implementation.

Current Stack

- Flask
- SQLite
- Mock OTP
- Mock AI
- Static QR
- Local Storage

Everything below must replace the mock layer.

---

# New Production Stack

Backend
- FastAPI
- Python 3.12+

Database
- PostgreSQL

ORM
- SQLAlchemy
- Alembic

Authentication
- JWT Access Token
- JWT Refresh Token
- Token Revocation

OTP
- Firebase Phone Auth / local fallback

AI
- Google Gemini API

Storage
- AWS S3

Deployment
- Render

Database Hosting
- Neon PostgreSQL

API Documentation
- FastAPI Swagger

---

# DO NOT CHANGE

Do NOT modify:

Flutter UI

Fonts

Layouts

Navigation

Theme

Colors

Animations

Existing Screen Flow

Replace only backend implementations.

---

# Environment Variables

Backend must use .env.

Required Variables

SECRET_KEY=

DATABASE_URL=

GEMINI_API_KEY=

FIREBASE_PROJECT_ID=

FIREBASE_STORAGE_BUCKET=

FIREBASE_CREDENTIALS_PATH=

STORAGE_PROVIDER=s3

STORAGE_BUCKET_NAME=

AWS_ACCESS_KEY_ID=

AWS_SECRET_ACCESS_KEY=

AWS_REGION=

API_BASE_URL=

Never hardcode secrets.

---

# Database

Use PostgreSQL.

Suggested Provider:

Neon

Do NOT use SQLite.

---

# Required Database Tables

users

profiles

medical_records

prescriptions

reports

medicine_reminders

emergency_contacts

qr_tokens

otp_sessions

refresh_tokens

audit_logs

---

# Authentication

Implement

User Registration

User Login

Logout

Refresh Token

Password Reset (future-ready)

Phone OTP Verification

JWT Authentication

Protected Routes

Role Support

User

Doctor

Police

Admin

---

# OTP

Use Firebase Phone Auth as the production OTP provider. Legacy backend OTP endpoints may still be used only for local development and test fallback.

---

# AI Assistant

Connect Google Gemini.

Capabilities

Medical explanation

Medicine information

Lifestyle suggestions

Report explanation

Emergency guidance

The AI must never replace professional medical advice.

---

# Reports

Upload

PDF

JPG

PNG

Storage

AWS S3

Save only file URLs inside PostgreSQL.

Do NOT store files inside database.

---

# QR System

Replace static QR.

Every user receives

UUID-based QR Token

Store token in database.

QR should contain

https://<backend-domain>/emergency/{qr_token}

When scanned

Backend fetches patient

Returns only emergency-safe information.

Never expose complete medical history publicly.

---

# Emergency Access

Public access should display only

Name

Age

Blood Group

Allergies

Emergency Contacts

Current Medications

Medical Conditions (optional)

No login required.

Everything else requires authentication.

---

# Medicine Reminder

Backend CRUD

Schedule

Notifications (future)

---

# APIs

Implement REST APIs.

Authentication

POST /auth/register

POST /auth/login

POST /auth/logout

POST /auth/refresh

POST /auth/send-otp

POST /auth/verify-otp

User

GET /profile

PUT /profile

Medical

GET /medical-history

POST /medical-history

PUT /medical-history/{id}

DELETE /medical-history/{id}

Reports

POST /reports/upload

GET /reports

DELETE /reports/{id}

Prescriptions

GET /prescriptions

POST /prescriptions

Reminder

GET /reminders

POST /reminders

PUT /reminders/{id}

DELETE /reminders/{id}

QR

GET /qr

GET /emergency/{qr_token}

AI

POST /ai/chat

Police

POST /police/access

---

# API Standards

JSON only

HTTP Status Codes

Validation

Pagination

Filtering

Swagger Documentation

OpenAPI

---

# Security

HTTPS only

JWT Authentication

Password Hashing

bcrypt

Input Validation

SQL Injection Protection

Rate Limiting

CORS

Secure Headers

Environment Variables

No secrets inside source code.

---

# Logging

Log

Authentication

Uploads

QR Access

Errors

AI Requests

Audit Trail

---

# Deployment

Backend

Render

Database

Neon PostgreSQL

Storage

AWS S3

HTTPS

Enabled

---

# Flutter Changes

Only replace

Mock API calls

Mock Authentication

Mock AI

Mock QR

Mock Upload

Use API_BASE_URL from environment.

No UI changes.

---

# Future Scope (Do NOT Implement Now)

Wearable Integration

Voice Assistant

Offline Emergency Access

Insurance Integration

Government Hospital Integration

National Health ID

Aadhaar Verification

Family Health Records

These should remain modular for future implementation.

---

# Implementation Order

Phase 1

FastAPI Project Structure

Database Models

PostgreSQL

Alembic

Authentication

JWT

Twilio OTP

Phase 2

Medical Records

Reports

S3 Upload

Profile

Reminders

Phase 3

Gemini AI

Dynamic QR

Emergency APIs

Police Access

Phase 4

Deployment

Render

Neon

Environment Variables

Swagger

Production Testing

---

# Definition of Done

Project is complete when

✓ No mock APIs remain

✓ No SQLite remains

✓ No local file storage remains

✓ Real PostgreSQL connected

✓ Real Twilio OTP working

✓ Real Gemini AI working

✓ Reports upload to AWS S3

✓ Dynamic QR working

✓ JWT Authentication working

✓ Render deployment completed

✓ HTTPS enabled

✓ Flutter communicates only with production APIs

---

END OF DOCUMENT