import os
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.database import engine, Base
from app.core.limiter import limiter
from app.api.v1 import api_v1_router
from app.middleware.logging_middleware import LoggingMiddleware
from app.middleware.security_middleware import SecurityHeadersMiddleware

settings.validate_startup()

# Create DB tables only for local developer convenience. Production deployments
# must use Alembic migrations against Neon PostgreSQL.
if settings.ENVIRONMENT != "production":
    Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Production-ready Backend API for Aarogya Vault Secure Medical Records & AI Assistant",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Register slowapi rate limiter configuration
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# 1. Register Logging Correlation ID Middleware (outermost)
app.add_middleware(LoggingMiddleware)

# 2. Register Security Headers Middleware
app.add_middleware(SecurityHeadersMiddleware)

# 3. Register CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if settings.ENABLE_LOCAL_UPLOADS and settings.ENVIRONMENT != "production":
    uploads_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "uploads")
    os.makedirs(uploads_dir, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

# Mount Consolidated Router under /api/v1 prefix
app.include_router(api_v1_router, prefix="/api/v1")

from fastapi.exceptions import RequestValidationError

# Standardized envelope formatting for validation error exception handler
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "error": {
                "code": "VALIDATION_ERROR",
                "message": str(exc.errors())
            }
        }
    )

@app.get("/")
def read_root():
    return {
        "status": "online",
        "app": settings.PROJECT_NAME,
        "api_docs": "/docs",
        "redoc": "/redoc",
        "health_check": "/api/v1/health"
    }

@app.get("/health")
def health():
    return {"status": "ok", "build": "v1.0.6-diag"}

@app.get("/live")
def live():
    return {"status": "live"}

@app.get("/ready")
def ready():
    return {"status": "ready"}

@app.get("/debug/hash-test")
def debug_hash_test():
    """Temporary endpoint to diagnose password hashing on Render. Remove after fixing."""
    import hashlib
    import bcrypt as bcrypt_lib
    from app.security.passwords import get_password_hash, _preprocess_password
    test_pw = "ayaz123"
    preprocessed = _preprocess_password(test_pw)
    result = {"test_password_len": len(test_pw), "preprocessed": preprocessed, "preprocessed_len": len(preprocessed), "preprocessed_bytes": len(preprocessed.encode('utf-8'))}
    try:
        hashed = get_password_hash(test_pw)
        result["hash_success"] = True
        result["hash_preview"] = hashed[:20] + "..."
    except Exception as e:
        result["hash_success"] = False
        result["hash_error"] = str(e)
    try:
        result["bcrypt_version"] = bcrypt_lib.__version__
    except Exception:
        result["bcrypt_version"] = "unknown"
    return result
