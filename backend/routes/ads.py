from fastapi import APIRouter, HTTPException, Body
from database import db
from models.advertisement import Advertisement
from typing import List
from datetime import datetime
from bson import ObjectId
from utils.serializers import serialize_docs, serialize_doc

router = APIRouter(prefix="/ads", tags=["advertisements"])

@router.get("/active", response_model=List[Advertisement])
async def get_active_ads():
    now = datetime.utcnow()
    query = {
        "status": "active",
        "start_date": {"$lte": now},
        "end_date": {"$gte": now}
    }
    ads = await db.advertisements.find(query).sort("display_order", 1).to_list(10)
    return serialize_docs(ads)

@router.post("/click/{ad_id}")
async def track_click(ad_id: str):
    await db.advertisements.update_one(
        {"_id": ObjectId(ad_id)},
        {"$inc": {"click_count": 1}}
    )
    return {"status": "success"}

# Admin routes
@router.get("/all")
async def get_all_ads():
    ads = await db.advertisements.find().to_list(100)
    return serialize_docs(ads)

@router.post("/create")
async def create_ad(ad: Advertisement):
    ad_dict = ad.model_dump(by_alias=True)
    if "_id" in ad_dict:
        ad_dict.pop("_id")
    result = await db.advertisements.insert_one(ad_dict)
    return {"id": str(result.inserted_id)}

@router.delete("/{ad_id}")
async def delete_ad(ad_id: str):
    await db.advertisements.delete_one({"_id": ObjectId(ad_id)})
    return {"status": "deleted"}
