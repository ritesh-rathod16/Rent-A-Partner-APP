from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class Booking(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    
    # Relationships
    customer_id: str # User ID of the customer
    customer_user_id: Optional[str] = None # Redundant but for consistency
    
    companion_id: str # Companion collection ID
    companion_user_id: Optional[str] = None # User ID of the companion
    
    # Display Data (Populated on creation)
    customer_name: Optional[str] = None
    customer_email: Optional[str] = None
    
    companion_name: Optional[str] = None
    companion_email: Optional[str] = None
    companion_photo: Optional[str] = ""
    
    date: str
    time: str
    duration_hours: int
    activity_type: str
    total_amount: float
    status: str = "pending" # pending, confirmed, active, completed, cancelled
    
    # Location & Safety
    companion_lat: Optional[float] = None
    companion_lng: Optional[float] = None
    customer_lat: Optional[float] = None
    customer_lng: Optional[float] = None
    
    start_otp: Optional[str] = None
    end_otp: Optional[str] = None
    
    payment_id: Optional[str] = None
    razorpay_order_id: Optional[str] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
