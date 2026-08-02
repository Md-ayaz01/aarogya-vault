import os
from typing import List, Optional
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Settings:
    PROJECT_NAME: str = "Aarogya Vault Backend"
    API_V1_STR: str = "/api/v1"
    
    # Environment Configurations
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development").lower()
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO").upper()
    
    # Secret Key for legacy backend-issued JWTs. Production auth uses Supabase JWTs.
    DEFAULT_DEV_SECRET_KEY: str = "aarogya_vault_dev_secret_change_me"
    SECRET_KEY: str = os.getenv("SECRET_KEY", DEFAULT_DEV_SECRET_KEY)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # AES-256 Encryption credentials matching client SecurityHelper
    AES_ENCRYPTION_KEY: bytes = os.getenv("AES_ENCRYPTION_KEY", "aarogya_vault_super_secure_secur").encode("utf-8")
    AES_ENCRYPTION_IV: bytes = os.getenv("AES_ENCRYPTION_IV", "aarogya_vault_iv").encode("utf-8")
    
    # Neon PostgreSQL Database URL. SQLite is permitted only for local development/tests.
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./aarogya_vault.db")

    # Supabase Auth configuration. SUPABASE_JWT_SECRET supports HS256 projects.
    # SUPABASE_JWKS_URL is documented for asymmetric JWT projects and should be
    # verified by infrastructure before production rollout.
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_ANON_KEY: str = os.getenv("SUPABASE_ANON_KEY", "")
    SUPABASE_JWT_SECRET: str = os.getenv("SUPABASE_JWT_SECRET", "")
    SUPABASE_JWT_AUDIENCE: str = os.getenv("SUPABASE_JWT_AUDIENCE", "authenticated")
    SUPABASE_JWKS_URL: str = os.getenv("SUPABASE_JWKS_URL", "")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
    SUPABASE_STORAGE_BUCKET: str = os.getenv("SUPABASE_STORAGE_BUCKET", "medical-files")
    
    # Firebase Cloud Storage Credentials
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "")
    FIREBASE_STORAGE_BUCKET: str = os.getenv("FIREBASE_STORAGE_BUCKET", "")
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    
    # Google Gemini API Key
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    
    # Domain / API configuration
    API_BASE_URL: str = os.getenv("API_BASE_URL", "https://aarogya-vault.onrender.com/api/v1")
    ENABLE_LOCAL_UPLOADS: bool = os.getenv("ENABLE_LOCAL_UPLOADS", "false").lower() == "true"
    
    # File upload limits
    MAX_UPLOAD_SIZE_MB: int = int(os.getenv("MAX_UPLOAD_SIZE_MB", "20"))
    
    # CORS Origin Allowlist
    @property
    def cors_origins(self) -> List[str]:
        origins_str = os.getenv("CORS_ALLOWED_ORIGINS", "") or os.getenv("CORS_ORIGINS", "")
        if not origins_str:
            return ["*"] if self.ENVIRONMENT != "production" else []
        return [origin.strip() for origin in origins_str.split(",") if origin.strip()]

    def validate_startup(self) -> None:
        if self.ENVIRONMENT == "production":
            if self.DATABASE_URL.startswith("sqlite"):
                raise RuntimeError("Production requires Neon/PostgreSQL DATABASE_URL; SQLite is not allowed.")
            if not self.SECRET_KEY or self.SECRET_KEY == self.DEFAULT_DEV_SECRET_KEY:
                raise RuntimeError("Production requires a non-default SECRET_KEY for legacy token validation/rotation.")
            if not self.SUPABASE_URL:
                raise RuntimeError("Production requires SUPABASE_URL.")
            if not self.FIREBASE_PROJECT_ID:
                raise RuntimeError("Production requires FIREBASE_PROJECT_ID.")
            if not self.FIREBASE_CREDENTIALS_PATH:
                raise RuntimeError("Production requires FIREBASE_CREDENTIALS_PATH.")
            if not self.cors_origins:
                raise RuntimeError("Production requires explicit CORS_ALLOWED_ORIGINS.")

settings = Settings()
