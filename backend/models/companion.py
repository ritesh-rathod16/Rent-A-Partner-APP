from datetime import datetime
from typing import Optional, List, Dict
from pydantic import BaseModel, EmailStr, Field

class CompanionApplication(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    
    # Personal Information
    full_name: str
    dob: Optional[str] = None
    age: Optional[int] = 0
    gender: Optional[str] = "Not Specified"
    height: Optional[str] = None
    phone_number: Optional[str] = None
    email: EmailStr
    instagram_id: Optional[str] = None
    occupation: Optional[str] = "Not Provided"
    languages: List[str] = []
    
    # Location
    current_address: Optional[str] = None
    permanent_address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = "Not Provided"
    
    # Profile Details
    bio: Optional[str] = ""
    interests: List[str] = []
    hobbies: List[str] = []
    photos: List[str] = []
    
    # Professional Details
    hourly_rate: Optional[float] = 0.0
    available_cities: List[str] = []
    service_categories: List[str] = []
    availability_hours: Optional[str] = ""
    
    # Documents
    id_type: str = "Aadhaar" 
    id_url: Optional[str] = ""
    id_back_url: Optional[str] = ""
    live_selfie_url: Optional[str] = ""
    payment_qr_url: Optional[str] = None
    upi_id: Optional[str] = None
    
    # Verification Status
    status: str = "pending"
    is_identity_verified: bool = False
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class Companion(CompanionApplication):
    # This is the active companion profile
    rating: float = 5.0 # Initial rating set to 5.0
    review_count: int = 0
    total_bookings: int = 0
    account_type: str = "standard"
    is_online: bool = False
    last_location: Optional[Dict] = None
    
    class Config:
        populate_by_name = True
