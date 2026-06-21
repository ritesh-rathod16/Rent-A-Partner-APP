from fastapi import APIRouter, HTTPException, Depends, Body
from database import db
from models.booking import Booking
import razorpay
from config import settings
import random
from typing import List, Any, Dict
from datetime import datetime
from bson import ObjectId
from routes.auth import get_current_user
from utils.serializers import serialize_doc, serialize_docs

router = APIRouter(prefix="/bookings", tags=["bookings"])

client = razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

@router.get("/my-bookings")
async def get_my_bookings(current_user: Dict[str, Any] = Depends(get_current_user)):
    user_id = current_user["id"]
    bookings = await db.bookings.find({
        "$or": [{"customer_id": user_id}, {"companion_user_id": user_id}]
    }).sort("created_at", -1).to_list(100)
    
    return serialize_docs(bookings)

@router.post("/create")
async def create_booking(booking_data: Booking):
    try:
        # 1. Fetch Actual User Data
        customer = await db.users.find_one({"_id": ObjectId(booking_data.customer_id)})
        if not customer:
            raise HTTPException(status_code=404, detail="Customer not found")
            
        companion = await db.companions.find_one({"_id": ObjectId(booking_data.companion_id)})
        if not companion:
            raise HTTPException(status_code=404, detail="Companion not found")
            
        # 2. Create Razorpay Order
        order_data = {
            "amount": int(booking_data.total_amount * 100), 
            "currency": "INR",
            "payment_capture": 1
        }
        razorpay_order = client.order.create(data=order_data)
        
        # 3. Prepare Data
        booking_dict = booking_data.model_dump(by_alias=True)
        if "_id" in booking_dict: booking_dict.pop("_id")
        
        booking_dict.update({
            "customer_user_id": str(customer["_id"]),
            "customer_name": customer.get("full_name"),
            "customer_email": customer.get("email"),
            "companion_user_id": str(companion["user_id"]),
            "companion_name": companion.get("full_name"),
            "companion_email": companion.get("email"),
            "companion_photo": companion["photos"][0] if companion.get("photos") else "",
            "razorpay_order_id": razorpay_order['id'],
            "status": "pending",
            "created_at": datetime.utcnow()
        })
        
        result = await db.bookings.insert_one(booking_dict)
        
        return {
            "success": True,
            "booking_id": str(result.inserted_id),
            "razorpay_order_id": razorpay_order['id'],
            "amount": booking_data.total_amount
        }
    except Exception as e:
        print(f"CREATE_BOOKING_ERROR: {e}")
        return {
            "success": False,
            "error_code": "BOOKING_FAILED",
            "message": str(e)
        }

@router.get("/active-session")
async def get_active_session(current_user: Dict[str, Any] = Depends(get_current_user)):
    user_id = current_user["id"]
    session = await db.bookings.find_one({
        "$or": [{"customer_id": user_id}, {"companion_user_id": user_id}],
        "status": {"$in": ["confirmed", "active"]}
    })
    
    if not session:
        return None
        
    return serialize_doc(session)

@router.post("/confirm")
async def confirm_booking(data: dict = Body(...)):
    booking_id = data.get("booking_id")
    payment_id = data.get("payment_id")
    
    start_otp = str(random.randint(1000, 9999))
    end_otp = str(random.randint(1000, 9999))
    
    await db.bookings.update_one(
        {"_id": ObjectId(booking_id)},
        {"$set": {
            "status": "confirmed",
            "payment_id": payment_id,
            "start_otp": start_otp,
            "end_otp": end_otp
        }}
    )
    
    return {"message": "Booking confirmed", "start_otp": start_otp}

# --- Migration / Backfill ---
@router.post("/migrate-bookings")
async def migrate_bookings():
    bookings = await db.bookings.find().to_list(None)
    count = 0
    for b in bookings:
        updates = {}
        # Resolve Companion
        if "companion_id" in b:
            comp = await db.companions.find_one({"_id": ObjectId(b["companion_id"])})
            if comp:
                updates["companion_user_id"] = str(comp["user_id"])
                updates["companion_name"] = comp.get("full_name")
                updates["companion_email"] = comp.get("email")
                if comp.get("photos"):
                    updates["companion_photo"] = comp["photos"][0]
        
        # Resolve Customer
        if "customer_id" in b:
            cust = await db.users.find_one({"_id": ObjectId(b["customer_id"])})
            if cust:
                updates["customer_user_id"] = str(cust["_id"])
                updates["customer_name"] = cust.get("full_name")
                updates["customer_email"] = cust.get("email")
        
        if updates:
            await db.bookings.update_one({"_id": b["_id"]}, {"$set": updates})
            count += 1
            
    return {"message": f"Migrated {count} bookings"}
