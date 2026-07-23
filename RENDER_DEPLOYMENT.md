# Aarogya Vault — Render Deployment Guide

This guide describes how to deploy the **Aarogya Vault FastAPI Backend** to **Render** using the provided `render.yaml` Blueprint or manually as a Web Service.

---

## 1. Prerequisites

Before deploying, ensure you have:
1. **GitHub Repository**: Pushed latest code to `https://github.com/Md-ayaz01/aarogya-vault` (or your repository URL).
2. **Neon PostgreSQL Database**: Connection string with password (`DATABASE_URL`).
3. **Firebase Project**: `FIREBASE_PROJECT_ID` and Service Account JSON credentials.
4. **Supabase Storage**: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and private bucket (`SUPABASE_STORAGE_BUCKET=medical-files`).
5. **Google Gemini API**: `GEMINI_API_KEY`.

---

## 2. Option A: Blueprint Deployment (Recommended)

Render can automatically detect `render.yaml` at the root of the repository.

1. Go to [Render Dashboard](https://dashboard.render.com/).
2. Click **New +** → **Blueprints**.
3. Connect your GitHub repository: `Md-ayaz01/aarogya-vault`.
4. Render will read `render.yaml` and prompt you for the Environment Variables.
5. Fill in the required environment variables:
   - `DATABASE_URL`
   - `SECRET_KEY`
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CREDENTIALS_PATH` (or paste JSON as Secret File)
   - `SUPABASE_URL`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_STORAGE_BUCKET`
   - `GEMINI_API_KEY`
   - `CORS_ALLOWED_ORIGINS`
6. Click **Apply**. Render will automatically run `pip install -r requirements.txt`, execute `alembic upgrade head`, and start `uvicorn app.main:app --host 0.0.0.0 --port $PORT`.

---

## 3. Option B: Manual Web Service Deployment

If creating a Web Service manually:

1. Click **New +** → **Web Service**.
2. Connect your GitHub Repository.
3. Configure the following settings:
   - **Name**: `aarogya-vault-api`
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port $PORT`
4. Under **Advanced** -> **Health Check Path**, enter:
   ```text
   /health
   ```
5. Add the **Environment Variables** listed in Section 4.

---

## 4. Required Environment Variables

Set the following variables in Render Dashboard (**Environment** section):

| Variable | Example / Purpose |
| :--- | :--- |
| `ENVIRONMENT` | `production` |
| `SECRET_KEY` | Long random secret string for local JWT signatures |
| `DATABASE_URL` | `postgresql+psycopg://neondb_owner:PASSWORD@HOST.neon.tech/neondb?sslmode=require` |
| `API_BASE_URL` | `https://aarogya-vault-api.onrender.com/api/v1` |
| `FIREBASE_PROJECT_ID` | `aarogya-vault` |
| `FIREBASE_CREDENTIALS_PATH` | `./firebase-service-account.json` (or path to Secret File) |
| `SUPABASE_URL` | `https://YOUR_PROJECT.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | `YOUR_BACKEND_ONLY_SERVICE_ROLE_KEY` |
| `SUPABASE_STORAGE_BUCKET` | `medical-files` |
| `GEMINI_API_KEY` | `YOUR_GEMINI_API_KEY` |
| `CORS_ALLOWED_ORIGINS` | `https://patient.example.com,https://doctor.example.com` |

---

## 5. Firebase Admin Secret File Setup

Render allows uploading Secret Files:

1. In your Render Web Service dashboard, navigate to **Secret Files**.
2. Click **Add Secret File**.
3. Set **Filename**: `firebase-service-account.json` (or `/etc/secrets/firebase-service-account.json`).
4. Paste the JSON contents of your service account key file.
5. In Environment Variables, set:
   ```env
   FIREBASE_CREDENTIALS_PATH=./firebase-service-account.json
   ```

---

## 6. Verifying Deployment

Once deployed, test your API endpoints:

1. **Health check**:
   ```bash
   curl https://aarogya-vault-api.onrender.com/health
   # Expected output: {"status":"ok"}
   ```
2. **Detailed Diagnostic check**:
   ```bash
   curl https://aarogya-vault-api.onrender.com/api/v1/health
   # Expected output: {"status":"healthy","database":"connected","supabase":"initialized","gemini":"configured"}
   ```
3. **API Documentation**:
   Navigate to `https://aarogya-vault-api.onrender.com/docs` in your browser.

---

## 7. Connecting Mobile Apps to Production API

Build the Patient App and Doctor App with your live Render URL:

```bash
# Patient App
cd aarogya_vault_app
flutter build apk --release --dart-define=API_BASE_URL=https://aarogya-vault-api.onrender.com/api/v1
flutter build appbundle --release --dart-define=API_BASE_URL=https://aarogya-vault-api.onrender.com/api/v1

# Doctor App
cd apps/doctor_app
flutter build apk --release --dart-define=API_BASE_URL=https://aarogya-vault-api.onrender.com/api/v1
flutter build appbundle --release --dart-define=API_BASE_URL=https://aarogya-vault-api.onrender.com/api/v1
```
