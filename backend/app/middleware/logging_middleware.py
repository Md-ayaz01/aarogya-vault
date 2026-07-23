import time
import uuid
import json
import logging
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.types import ASGIApp

# Setup basic logging configuration to output structured log lines
logger = logging.getLogger("aarogya_vault_access")
logger.setLevel(logging.INFO)
# Prevent duplicate logs if handler exists
if not logger.handlers:
    handler = logging.StreamHandler()
    formatter = logging.Formatter('%(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)

class LoggingMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp):
        super().__init__(app)

    async def dispatch(self, request: Request, call_next) -> Response:
        # 1. Generate or extract X-Request-ID (Correlation ID)
        request_id = request.headers.get("X-Request-ID")
        if not request_id:
            request_id = str(uuid.uuid4())
            
        # Attach request id to request state for access in endpoints
        request.state.request_id = request_id
        
        start_time = time.time()
        
        # 2. Call next middleware/endpoint
        try:
            response = await call_next(request)
        except Exception as e:
            # Prevent exposing stack traces in production
            duration = (time.time() - start_time) * 1000
            error_log = {
                "request_id": request_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": 500,
                "duration_ms": round(duration, 2),
                "client_ip": request.client.host if request.client else "unknown",
                "user_agent": request.headers.get("user-agent", ""),
                "error": str(e)
            }
            logger.error(json.dumps(error_log))
            
            # Return standardized error format
            return Response(
                content=json.dumps({
                    "success": False,
                    "error": {
                        "code": "INTERNAL_SERVER_ERROR",
                        "message": "An unexpected error occurred. Reference ID: " + request_id
                    }
                }),
                status_code=500,
                media_type="application/json"
            )
            
        # 3. Calculate performance timing
        duration_ms = (time.time() - start_time) * 1000
        
        # 4. Write structured JSON log (excluding sensitive params)
        log_data = {
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
            "status_code": response.status_code,
            "duration_ms": round(duration_ms, 2),
            "client_ip": request.client.host if request.client else "unknown",
            "user_agent": request.headers.get("user-agent", "")
        }
        
        logger.info(json.dumps(log_data))
        
        # 5. Propagate Correlation ID back to client in response headers
        response.headers["X-Request-ID"] = request_id
        return response
