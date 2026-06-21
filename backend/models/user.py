from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, EmailStr, Field

class User(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    full_name: str
    email: EmailStr
    phone_number: Optional[str] = None
    city: str
    dob: Optional[str] = None
    gender: Optional[str] = None
    password: Optional[str] = None
    bio: Optional[str] = None
    is_verified: bool = False # Identity Verification
    account_type: str = "standard" # standard, verified (Badge)
    status: str = "active" # active, suspended, banned
    wallet_balance: float = 0.0
    photo_url: Optional[str] = None
    is_companion: bool = False
    companion_id: Optional[str] = None
    privacy_settings: Dict[str, bool] = Field(default_factory=lambda: {
        "public_profile": True,
        "show_active_status": True,
        "two_factor_auth": False
    })
    favorites: List[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True

class OTPLog(BaseModel):
    email: EmailStr
    otp: str
    expires_at: datetime
    created_at: datetime = Field(default_factory=datetime.utcnow)
    is_used: bool = False
