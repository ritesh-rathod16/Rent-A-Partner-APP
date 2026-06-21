from fastapi import APIRouter, Depends
from database import db
from datetime import datetime
from bson import ObjectId

from utils.serializers import serialize_docs

router = APIRouter(prefix="/tracking", tags=["tracking"])

@router.post("/update")
async def update_location(user_id: str, booking_id: str, lat: float, lng: float):
    location_data = {
        "user_id": user_id,
        "booking_id": booking_id,
        "lat": lat,
        "lng": lng,
        "timestamp": datetime.utcnow()
    }
    await db.live_tracking.insert_one(location_data)
    
    # Also update the booking record itself for quick access by Admin
    await db.bookings.update_one(
        {"_id": ObjectId(booking_id) if len(booking_id) == 24 else booking_id},
        {"$set": {"companion_lat": lat, "companion_lng": lng}}
    )
    
    return {"status": "success"}

@router.get("/booking/{booking_id}")
async def get_booking_path(booking_id: str):
    path = await db.live_tracking.find({"booking_id": booking_id}).sort("timestamp", 1).to_list(1000)
    return serialize_docs(path)
