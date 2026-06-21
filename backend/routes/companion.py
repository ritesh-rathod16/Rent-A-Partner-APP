import shutil
import os
from fastapi import APIRouter, HTTPException, Depends, Body, File, UploadFile
from database import db
from models.companion import CompanionApplication, Companion
from typing import List, Dict, Any
from bson import ObjectId
from routes.auth import get_current_user
from datetime import datetime
from utils.serializers import serialize_doc, serialize_docs

router = APIRouter(prefix="/companions", tags=["companions"])

@router.patch("/profile")
async def update_companion_profile(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    # Restrict keys that can be updated directly
    allowed_keys = ["bio", "interests", "service_categories", "languages", "city", "hourly_rate", "availability_hours", "photos"]
    update_data = {k: v for k, v in data.items() if k in allowed_keys}
    
    if not update_data:
        raise HTTPException(status_code=400, detail="No valid fields to update")
        
    await db.companions.update_one(
        {"user_id": current_user["id"]},
        {"$set": update_data}
    )
    return {"message": "Profile updated successfully"}

@router.post("/upload-photo")
async def upload_companion_photo(file: UploadFile = File(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    try:
        os.makedirs("uploads/companion", exist_ok=True)
        file_extension = file.filename.split(".")[-1]
        file_name = f"comp_{current_user['id']}_{int(datetime.utcnow().timestamp())}.{file_extension}"
        file_path = f"uploads/companion/{file_name}"
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Store relative path
        relative_url = f"companion/{file_name}"
        # Update first photo in list as main profile photo for companion
        await db.companions.update_one(
            {"user_id": current_user["id"]},
            {"$push": {"photos": {"$each": [relative_url], "$position": 0}}}
        )
        return {"photo_url": relative_url}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/upload-gallery")
async def upload_gallery_photos(files: List[UploadFile] = File(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    os.makedirs("uploads/gallery", exist_ok=True)
    urls = []
    for file in files:
        file_extension = file.filename.split(".")[-1]
        file_name = f"gal_{current_user['id']}_{int(datetime.utcnow().timestamp())}_{len(urls)}.{file_extension}"
        file_path = f"uploads/gallery/{file_name}"
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        urls.append(f"gallery/{file_name}")
        
    await db.companions.update_one(
        {"user_id": current_user["id"]},
        {"$push": {"photos": {"$each": urls}}}
    )
    return {"urls": urls}

@router.delete("/gallery")
async def delete_gallery_photo(url: str = Body(..., embed=True), current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.companions.update_one(
        {"user_id": current_user["id"]},
        {"$pull": {"photos": url}}
    )
    return {"message": "Photo removed"}

@router.post("/apply")
async def apply_as_companion(application: CompanionApplication):
    existing = await db.companions.find_one({"user_id": application.user_id})
    if existing:
        if existing["status"] == "approved":
            raise HTTPException(status_code=400, detail="You are already a verified companion")
        if existing["status"] == "pending":
            raise HTTPException(status_code=400, detail="Your application is already under review. Please wait.")
        
        # If rejected, delete to allow updated re-application
        await db.companions.delete_one({"user_id": application.user_id})
    
    app_dict = application.model_dump(by_alias=True)
    if "_id" in app_dict:
        app_dict.pop("_id")
    
    app_dict["status"] = "pending"
    app_dict["created_at"] = datetime.utcnow()

    result = await db.companions.insert_one(app_dict)
    return {"success": True, "application_id": str(result.inserted_id)}

@router.get("/list") # Removed type hint to allow joined data
async def list_verified_companions(city: str = None, category: str = None):
    try:
        pipeline = [
            {"$match": {"status": "approved"}}
        ]
        
        if city:
            pipeline.append({"$match": {"available_cities": {"$regex": city, "$options": "i"}}})
        if category:
            pipeline.append({"$match": {"service_categories": category}})

        # Join with users to get account_type (verified badge)
        # We need to handle string user_id -> ObjectId transition
        pipeline.append({
            "$addFields": {
                "user_oid": {"$toObjectId": "$user_id"}
            }
        })
        
        pipeline.append({
            "$lookup": {
                "from": "users",
                "localField": "user_oid",
                "foreignField": "_id",
                "as": "user_info"
            }
        })
        
        pipeline.append({"$unwind": {"path": "$user_info", "preserveNullAndEmptyArrays": True}})

        # Sorting: Verified first, then rating
        pipeline.append({
            "$sort": {
                "user_info.account_type": -1, # verified (v) > standard (s)
                "rating": -1
            }
        })

        companions = await db.companions.aggregate(pipeline).to_list(100)
        
        # Enrich and serialize
        for c in companions:
            c["account_type"] = c.get("user_info", {}).get("account_type", "standard")
            # Force string ID for frontend consistency
            c["_id"] = str(c["_id"])
            
            completed_bookings = await db.bookings.count_documents({"companion_id": str(c["_id"]), "status": "completed"})
            c["total_bookings"] = completed_bookings
            
            # Simple Trust Score
            reports_count = await db.reports.count_documents({"reported_user_id": c["user_id"]})
            trust_score = (completed_bookings * 10) + (c.get("rating", 0) * 20) - (reports_count * 50)
            c["trust_score"] = max(0, min(100, trust_score)) # Clamp between 0-100

            c.pop("user_info", None)
            c.pop("user_oid", None)

        return serialize_docs(companions)
    except Exception as e:
        print(f"LIST_COMPANIONS_ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/profile/{id}")
async def get_companion_details(id: str):
    if not ObjectId.is_valid(id):
        raise HTTPException(status_code=400, detail="Invalid companion ID")
        
    companion = await db.companions.find_one({"_id": ObjectId(id)})
    if not companion:
        raise HTTPException(status_code=404, detail="Companion not found")
        
    # Get user info for account_type
    user_id = companion["user_id"]
    user = await db.users.find_one({"_id": ObjectId(user_id) if len(user_id) == 24 else user_id})
    if user:
        companion["account_type"] = user.get("account_type", "standard")
    
    return serialize_doc(companion)

@router.get("/my-profile")
async def get_my_companion_profile(current_user: Dict[str, Any] = Depends(get_current_user)):
    companion = await db.companions.find_one({"user_id": current_user["id"]})
    if not companion:
        raise HTTPException(status_code=404, detail="Companion profile not found")
    return serialize_doc(companion)

@router.get("/stats")
async def get_my_companion_stats(current_user: Dict[str, Any] = Depends(get_current_user)):
    companion = await db.companions.find_one({"user_id": current_user["id"]})
    if not companion:
        return {
            "total_earnings": 0, "weekly_earnings": 0, "total_bookings": 0,
            "rating": 0.0, "profile_visits": 0, "response_rate": 0,
            "completion_rate": 0, "total_hours": 0, "is_online": False
        }
    
    total_bookings = await db.bookings.count_documents({"companion_id": str(companion["_id"]), "status": "completed"})
    
    return {
        "user_id": companion["user_id"],
        "total_earnings": companion.get("total_earnings", 0),
        "weekly_earnings": companion.get("weekly_earnings", 0),
        "total_bookings": total_bookings,
        "rating": companion.get("rating", 0.0),
        "profile_visits": companion.get("profile_visits", 0),
        "response_rate": companion.get("response_rate", 100),
        "completion_rate": companion.get("completion_rate", 100),
        "total_hours": companion.get("total_hours", 0),
        "is_online": companion.get("is_online", False)
    }

@router.post("/update-rates")
async def update_rates(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.companions.update_one({"user_id": current_user["id"]}, {"$set": {"hourly_rate": data["hourly_rate"]}})
    return {"message": "Rates updated"}

@router.post("/update-availability")
async def update_availability(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.companions.update_one({"user_id": current_user["id"]}, {"$set": {"availability_hours": data["availability_hours"]}})
    return {"message": "Availability updated"}

@router.post("/toggle-availability")
async def toggle_availability(current_user: Dict[str, Any] = Depends(get_current_user)):
    companion = await db.companions.find_one({"user_id": current_user["id"]})
    if not companion:
        raise HTTPException(status_code=404, detail="Companion profile not found")
    
    new_status = not companion.get("is_online", False)
    await db.companions.update_one(
        {"user_id": current_user["id"]},
        {"$set": {"is_online": new_status}}
    )
    return {"is_online": new_status}

@router.post("/update-settings")
async def update_settings(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    # General settings for companion
    await db.companions.update_one(
        {"user_id": current_user["id"]},
        {"$set": {"settings": data}}
    )
    return {"message": "Settings updated"}
