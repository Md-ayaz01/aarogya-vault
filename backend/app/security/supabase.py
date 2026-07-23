from typing import Any, Dict, Optional

import jwt
from fastapi import HTTPException, status

from app.core.config import settings


def verify_supabase_jwt(token: str) -> Dict[str, Any]:
    """Verify a Supabase access token and return its claims."""
    if not settings.SUPABASE_JWKS_URL and not settings.SUPABASE_JWT_SECRET:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Supabase JWT verification is not configured.",
        )

    try:
        if settings.SUPABASE_JWKS_URL:
            # Asymmetric signature verification using JWKS URL
            jwks_client = jwt.PyJWKClient(settings.SUPABASE_JWKS_URL)
            signing_key = jwks_client.get_signing_key_from_jwt(token)
            try:
                claims = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=["RS256"],
                    audience=settings.SUPABASE_JWT_AUDIENCE,
                    options={"require": ["exp", "sub"]},
                )
            except jwt.InvalidAudienceError:
                claims = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=["RS256"],
                    options={"require": ["exp", "sub"], "verify_aud": False},
                )
        else:
            # Symmetric signature verification using shared secret
            try:
                claims = jwt.decode(
                    token,
                    settings.SUPABASE_JWT_SECRET,
                    algorithms=["HS256"],
                    audience=settings.SUPABASE_JWT_AUDIENCE,
                    options={"require": ["exp", "sub"]},
                )
            except jwt.InvalidAudienceError:
                claims = jwt.decode(
                    token,
                    settings.SUPABASE_JWT_SECRET,
                    algorithms=["HS256"],
                    options={"require": ["exp", "sub"], "verify_aud": False},
                )
    except jwt.PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Supabase session token: {str(exc)}",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if claims.get("role") not in (None, "authenticated"):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Supabase token is not an authenticated user session.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return claims


def phone_from_supabase_claims(claims: Dict[str, Any]) -> Optional[str]:
    phone = claims.get("phone")
    if phone:
        return str(phone)
    user_metadata = claims.get("user_metadata") or {}
    phone = user_metadata.get("phone") or user_metadata.get("phone_number")
    return str(phone) if phone else None


def email_from_supabase_claims(claims: Dict[str, Any]) -> Optional[str]:
    email = claims.get("email")
    if email:
        return str(email)
    user_metadata = claims.get("user_metadata") or {}
    email = user_metadata.get("email")
    return str(email) if email else None
