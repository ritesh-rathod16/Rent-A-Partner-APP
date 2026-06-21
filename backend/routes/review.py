from fastapi import APIRouter, HTTPException, Depends
from database import db
from models.review import Review
from typing import List
from datetime import datetime

router = APIRouter(prefix="/reviews", tags=["reviews"])

@router.post("/submit")
async def submit_review(review: Review):
    result = await db.reviews.insert_one(review.model_dump(by_alias=True))
    
    # Update companion stats
    await db.companions.update_one(
        {"_id": review.reviewee_id},
        {
            "$inc": {"review_count": 1},
            "$set": {"last_review_at": datetime.utcnow()}
        }
    )

    return {"message": "Review submitted", "id": str(result.inserted_id)}

@router.get("/companion/{companion_id}", response_model=List[Review])
async def get_companion_reviews(companion_id: str):
    return await db.reviews.find({"reviewee_id": companion_id}).to_list(100)
