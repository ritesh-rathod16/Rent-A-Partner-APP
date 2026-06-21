from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class Review(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    booking_id: str
    reviewer_id: str
    reviewee_id: str
    rating: float
    written_review: str
    
    # Specific scores
    safety_score: Optional[float] = None
    communication_score: Optional[float] = None
    punctuality_score: Optional[float] = None
    
    created_at: datetime = Field(default_factory=datetime.utcnow)
