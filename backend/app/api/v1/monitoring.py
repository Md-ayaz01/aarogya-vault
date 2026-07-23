from fastapi import APIRouter, Depends, status, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
import logging

from app.core.database import get_db
from app.storage.supabase import supabase_storage
from app.core.config import settings

logger = logging.getLogger("aarogya_vault_monitoring")
router = APIRouter(tags=["monitoring"])

@router.get("/health")
def health_check(db: Session = Depends(get_db)):
    """Detailed diagnostic health endpoint verifying database, supabase, and gemini status."""
    health_status = {
        "status": "healthy",
        "database": "connected",
        "supabase": "initialized" if supabase_storage.initialized else "unconfigured",
        "gemini": "configured" if settings.GEMINI_API_KEY else "unconfigured"
    }
    
    # Verify Database connectivity
    try:
        db.execute(text("SELECT 1")).scalar()
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        health_status["status"] = "unhealthy"
        health_status["database"] = "disconnected"
        
    return health_status

@router.get("/ready")
def readiness_probe(db: Session = Depends(get_db)):
    """Readiness probe indicating if the service is fully prepared to handle requests."""
    try:
        db.execute(text("SELECT 1")).scalar()
        return {"status": "ready"}
    except Exception:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Database is unavailable")

@router.get("/live")
def liveness_probe():
    """Simple container liveness probe."""
    return {"status": "live"}
