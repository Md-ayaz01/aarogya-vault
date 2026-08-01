import hashlib
import logging
from passlib.context import CryptContext

logger = logging.getLogger(__name__)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _preprocess_password(password: str) -> str:
    if not password:
        return ""
    if isinstance(password, bytes):
        password = password.decode('utf-8', errors='ignore')
    elif not isinstance(password, str):
        password = str(password)
    return hashlib.sha256(password.encode('utf-8')).hexdigest()[:32]

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against hashed password."""
    if not hashed_password or not plain_password:
        return False
    if isinstance(plain_password, bytes):
        plain_password = plain_password.decode('utf-8', errors='ignore')
    elif not isinstance(plain_password, str):
        plain_password = str(plain_password)
        
    logger.info(f"[SECURITY] Verifying password object of type {type(plain_password).__name__}, length {len(plain_password)} chars")
    try:
        if pwd_context.verify(_preprocess_password(plain_password), hashed_password):
            return True
    except Exception:
        pass
    try:
        return pwd_context.verify(plain_password[:50], hashed_password)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    """Hashes a plain password using bcrypt."""
    if not password:
        return ""
    if isinstance(password, bytes):
        password = password.decode('utf-8', errors='ignore')
    elif not isinstance(password, str):
        password = str(password)
        
    logger.info(f"[SECURITY] Hashing password object of type {type(password).__name__}, length {len(password)} chars")
    return pwd_context.hash(_preprocess_password(password))

