from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=["bcrypt"], 
    deprecated="auto",
    bcrypt__truncate_error=False
)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against hashed password."""
    if not hashed_password or not plain_password:
        return False
    try:
        return pwd_context.verify(plain_password[:50], hashed_password)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    """Hashes a plain password using bcrypt."""
    if not password:
        return ""
    try:
        return pwd_context.hash(password[:50])
    except Exception:
        safe_pwd = (password or "")[:32]
        return pwd_context.hash(safe_pwd)
