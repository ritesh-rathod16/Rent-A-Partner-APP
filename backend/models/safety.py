from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

class SOSAlert(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    booking_id: str
    status: str = "active" # active, resolved
    triggered_at: datetime = Field(default_factory=datetime.utcnow)
    resolved_at: Optional[datetime] = None
    location: dict = {"lat": 0.0, "lng": 0.0}

class UserReport(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    reporter_id: Optional[str] = None
    reported_user_id: str
    booking_id: Optional[str] = None
    reason: str
    description: str
    evidence_urls: List[str] = []
    status: str = "pending" # pending, investigating, resolved, closed
    admin_notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

class TrustedContact(BaseModel):
    name: str
    phone: str
    relation: str # Mother, Father, Friend, Spouse
