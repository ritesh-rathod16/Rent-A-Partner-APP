from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class WalletTransaction(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    user_id: str
    type: str # deposit, booking, verification, earning, withdrawal, refund
    amount: float
    status: str # PENDING, SUCCESS, FAILED, APPROVED, REJECTED, PAID
    reference: str # Razorpay ID, Booking ID, etc.
    description: str
    created_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
