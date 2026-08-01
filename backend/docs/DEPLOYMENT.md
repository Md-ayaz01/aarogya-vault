# Deployment Guide (Render)

Aarogya Vault is designed for containerized deployment on Render.

## Render Configuration

To deploy on Render, create a new **Web Service** pointing to the repository:

1. **Environment**: `Docker`
2. **Build Command**: Automatically handled by the Dockerfile.
3. **Start Command**: Automatically handled by the Dockerfile.

## Required Environment Variables on Render
Set the following variables in the Render Dashboard settings:
- `SECRET_KEY`: *Cryptographic signing secret*
- `DATABASE_URL`: *Neon connection string*
- `API_BASE_URL`: *Web service public URL (e.g. https://aarogya-vault.onrender.com/api/v1)*
- `GEMINI_API_KEY`: *Google Generative AI key*
- `FIREBASE_PROJECT_ID`: *Firebase Project ID*
- `FIREBASE_STORAGE_BUCKET`: *Firebase Bucket name*
- `FIREBASE_CREDENTIALS_PATH`: *Path to uploaded Firebase JSON credentials*
- `ENVIRONMENT`: `production`

## Backup & Recovery
- Neon provides automatic daily backups and point-in-time recovery.
- Firebase Storage bucket files are replicated across Google Cloud regions.
- Alembic database migration rollbacks can be performed using:
  ```bash
  alembic downgrade -1
  ```
