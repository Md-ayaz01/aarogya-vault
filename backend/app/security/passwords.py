import hashlib
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def _preprocess_password(password: str) -> str:
    if not password:
        return ""
    return hashlib.sha256(password.encode('utf-8')).hexdigest()

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against hashed password."""
    if not hashed_password or not plain_password:
        return False
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
    return pwd_context.hash(_preprocess_password(password))
