import jwt
import uuid
from datetime import datetime, timedelta, timezone
from typing import Union, Any, Optional
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models.models import RefreshToken

def get_utc_now():
    return datetime.now(timezone.utc)

def create_access_token(subject: Union[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    """Creates a JWT access token for a subject."""
    if expires_delta:
        expire = get_utc_now() + expires_delta
    else:
        expire = get_utc_now() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode = {
        "exp": expire.timestamp(),
        "iat": get_utc_now().timestamp(),
        "sub": str(subject),
        "type": "access"
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def verify_token(token: str) -> Union[str, None]:
    """Decodes and verifies a JWT access token, returning the subject."""
    try:
        decoded_token = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if decoded_token.get("type") != "access":
            return None
        return decoded_token.get("sub")
    except jwt.PyJWTError:
        return None

def create_refresh_token(subject: Union[str, Any], db: Session) -> str:
    """Creates a new JWT refresh token, stores it in the database (revoking older tokens for user)."""
    # Revoke all existing active refresh tokens for the user (Refresh Token Rotation)
    user_id = int(subject)
    db.query(RefreshToken).filter(
        RefreshToken.user_id == user_id,
        RefreshToken.is_revoked == False
    ).update({"is_revoked": True})
    db.commit()

    expire = get_utc_now() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    token_id = str(uuid.uuid4())
    
    to_encode = {
        "exp": expire.timestamp(),
        "iat": get_utc_now().timestamp(),
        "sub": str(subject),
        "jti": token_id,
        "type": "refresh"
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    
    db_refresh = RefreshToken(
        user_id=user_id,
        token=encoded_jwt,
        expires_at=expire,
        is_revoked=False
    )
    db.add(db_refresh)
    db.commit()
    return encoded_jwt

def verify_refresh_token(token: str, db: Session) -> Union[str, None]:
    """Verifies a JWT refresh token against expiration, signature, and database revocation status."""
    try:
        decoded_token = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        if decoded_token.get("type") != "refresh":
            return None
        
        # Check database revocation status
        db_token = db.query(RefreshToken).filter(RefreshToken.token == token).first()
        if not db_token or db_token.is_revoked or db_token.expires_at.replace(tzinfo=timezone.utc) < get_utc_now():
            return None
            
        return decoded_token.get("sub")
    except jwt.PyJWTError:
        return None

def revoke_refresh_token(token: str, db: Session) -> bool:
    """Revokes a refresh token in the database."""
    db_token = db.query(RefreshToken).filter(RefreshToken.token == token).first()
    if db_token:
        db_token.is_revoked = True
        db.commit()
        return True
    return False
