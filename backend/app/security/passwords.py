import hashlib
import logging
import bcrypt

logger = logging.getLogger(__name__)


def _preprocess_password(password: str) -> str:
    """Pre-hash any password to a fixed 64-char hex string via SHA-256.
    This ensures the input to bcrypt is always under 72 bytes,
    regardless of the original password length or encoding."""
    if not password:
        return ""
    if isinstance(password, bytes):
        password = password.decode('utf-8', errors='ignore')
    elif not isinstance(password, str):
        password = str(password)
    return hashlib.sha256(password.encode('utf-8')).hexdigest()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifies plain password against hashed password."""
    if not hashed_password or not plain_password:
        return False
    if isinstance(plain_password, bytes):
        plain_password = plain_password.decode('utf-8', errors='ignore')
    elif not isinstance(plain_password, str):
        plain_password = str(plain_password)

    preprocessed = _preprocess_password(plain_password)
    logger.info(f"[SECURITY] Verifying password, preprocessed length {len(preprocessed)} chars")
    try:
        return bcrypt.checkpw(
            preprocessed.encode('utf-8'),
            hashed_password.encode('utf-8') if isinstance(hashed_password, str) else hashed_password
        )
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """Hashes a plain password using bcrypt (directly, without passlib)."""
    if not password:
        return ""
    if isinstance(password, bytes):
        password = password.decode('utf-8', errors='ignore')
    elif not isinstance(password, str):
        password = str(password)

    preprocessed = _preprocess_password(password)
    logger.info(f"[SECURITY] Hashing password, preprocessed length {len(preprocessed)} chars")
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(preprocessed.encode('utf-8'), salt)
    return hashed.decode('utf-8')
