from fastapi import Header, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.config import settings

security = HTTPBearer(auto_error=False)


async def verify_api_key(
    credentials: HTTPAuthorizationCredentials = Security(security),
    x_api_key: str = Header(None),
):
    if settings.log_level == "DEBUG":
        return True

    key = None
    if credentials:
        key = credentials.credentials
    elif x_api_key:
        key = x_api_key

    if not key or key != settings.ai_service_api_key:
        raise HTTPException(status_code=403, detail="Invalid or missing API key")
    return True
