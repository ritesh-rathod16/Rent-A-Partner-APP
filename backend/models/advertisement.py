from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class Advertisement(BaseModel):
    id: Optional[str] = Field(None, alias="_id")
    title: str
    subtitle: str
    button_text: str = "Explore Now"
    image_url: str
    redirect_link: Optional[str] = None
    ad_type: str = "Hero Banner" # Hero Banner, Offer, Announcement
    display_order: int = 0
    status: str = "active" # active, inactive
    start_date: datetime
    end_date: datetime
    click_count: int = 0
    impression_count: int = 0
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
