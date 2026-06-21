import shutil
import os
from fastapi import APIRouter, HTTPException, Depends, Body, File, UploadFile, Request
from fastapi.responses import JSONResponse
from database import db
from models.safety import SOSAlert, UserReport, TrustedContact
from routes.auth import get_current_user
from typing import List, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId
from utils.serializers import serialize_doc, serialize_docs
from config import settings

router = APIRouter(prefix="/safety", tags=["Safety & SOS"])

# --- Helper to resolve companion ID to user ID ---
async def resolve_to_user_id(target_id: str):
    # Try finding in users first
    try:
        oid = ObjectId(target_id)
        user = await db.users.find_one({"_id": oid})
        if user:
            return str(user["_id"])
            
        # Try finding in companions
        companion = await db.companions.find_one({"_id": oid})
        if companion:
            return str(companion["user_id"])
    except:
        pass
    return target_id

@router.post("/sos/trigger")
async def trigger_sos(request: Request, data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    booking_id = data.get("booking_id")
    location = data.get("location", {"lat": 0.0, "lng": 0.0})
    
    user_ip = request.client.host if request.client else "Unknown"
    
    alert = {
        "user_id": current_user["id"],
        "user_name": current_user["full_name"],
        "user_phone": current_user.get("phone_number"),
        "booking_id": booking_id,
        "status": "active",
        "triggered_at": datetime.utcnow(),
        "location": location,
        "ip_address": user_ip,
        "trusted_contacts": current_user.get("trusted_contacts", [])
    }
    
    result = await db.sos_alerts.insert_one(alert)
    
    await db.platform_alerts.insert_one({
        "type": "SOS",
        "title": "CRITICAL: SOS Triggered",
        "body": f"User {current_user['full_name']} triggered SOS",
        "user_id": current_user["id"],
        "booking_id": booking_id,
        "sos_id": str(result.inserted_id),
        "status": "active",
        "created_at": datetime.utcnow()
    })
    
    return {"success": True, "alert_id": str(result.inserted_id)}

@router.post("/report")
async def file_report(report: UserReport, current_user: Dict[str, Any] = Depends(get_current_user)):
    try:
        print("Incoming Report:", report.model_dump())
        
        resolved_user_id = await resolve_to_user_id(report.reported_user_id)
        print("Resolved User ID:", resolved_user_id)
        
        # Validate reported user actually exists in users collection
        reported_user = await db.users.find_one({"_id": ObjectId(resolved_user_id)})
        if not reported_user:
            return JSONResponse(
                status_code=404,
                content={
                    "success": False,
                    "error_code": "USER_NOT_FOUND",
                    "message": "Unable to find the selected user."
                }
            )

        report_dict = report.model_dump(by_alias=True)
        if "_id" in report_dict: report_dict.pop("_id")
        
        report_dict.update({
            "reporter_id": current_user["id"],
            "reporter_name": current_user["full_name"],
            "reported_user_id": resolved_user_id,
            "reported_name": reported_user.get("full_name", "Unknown"),
            "status": "pending",
            "created_at": datetime.utcnow()
        })
        
        result = await db.reports.insert_one(report_dict)
        
        # Platform Alert for Admin
        await db.platform_alerts.insert_one({
            "type": "REPORT",
            "title": "New User Report",
            "body": f"Report filed by {current_user['full_name']} against {reported_user.get('full_name')}",
            "priority": "HIGH",
            "status": "active",
            "created_at": datetime.utcnow()
        })
        
        return {"success": True, "message": "Report submitted successfully"}
        
    except Exception as e:
        print(f"REPORT_ERROR: {e}")
        return JSONResponse(status_code=500, content={"success": False, "message": "Failed to submit report"})

@router.get("/contacts")
async def get_trusted_contacts(current_user: Dict[str, Any] = Depends(get_current_user)):
    user = await db.users.find_one({"_id": ObjectId(current_user["id"])})
    return serialize_docs(user.get("trusted_contacts", []))

@router.post("/contacts/add")
async def add_trusted_contact(contact: TrustedContact, current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$push": {"trusted_contacts": contact.model_dump()}}
    )
    return {"message": "Contact added"}

@router.delete("/contacts")
async def delete_trusted_contact(phone: str = Body(..., embed=True), current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$pull": {"trusted_contacts": {"phone": phone}}}
    )
    return {"message": "Contact removed"}
