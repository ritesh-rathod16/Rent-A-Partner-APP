from fastapi import APIRouter, HTTPException, Depends, Body
from database import db
from bson import ObjectId
from routes.auth import get_current_user, generate_otp
from datetime import datetime, timedelta
from typing import Dict, Any, List
from utils.serializers import serialize_doc, serialize_docs
from pydantic import BaseModel, EmailStr
from utils.email import send_otp_email

router = APIRouter(prefix="/user", tags=["User"])

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

# --- Privacy Settings ---
@router.get("/privacy-settings")
async def get_privacy_settings(current_user: Dict[str, Any] = Depends(get_current_user)):
    user = await db.users.find_one({"_id": ObjectId(current_user["id"])})
    return user.get("privacy_settings", {
        "public_profile": True,
        "show_active_status": True,
        "two_factor_auth": False
    })

@router.patch("/privacy-settings")
async def update_privacy_settings(data: Dict[str, bool] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$set": {"privacy_settings": data}}
    )
    return {"message": "Settings updated"}

# --- Password Management ---
@router.post("/change-password")
async def change_password(data: ChangePasswordRequest, current_user: Dict[str, Any] = Depends(get_current_user)):
    user = await db.users.find_one({"_id": ObjectId(current_user["id"])})
    if user.get("password") != data.current_password:
        return {
            "success": False,
            "error_code": "WRONG_PASSWORD",
            "message": "Current password incorrect."
        }
    
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$set": {"password": data.new_password}}
    )
    return {"success": True, "message": "Password changed successfully"}

# --- Device Management ---
@router.get("/connected-devices")
async def get_connected_devices(current_user: Dict[str, Any] = Depends(get_current_user)):
    # Simulating sessions for now. In production, use a sessions collection.
    devices = [
        {
            "id": "current",
            "device_name": "Android Device (Current Session)",
            "last_active": datetime.utcnow().isoformat(),
            "ip_address": "192.168.29.163",
            "is_current": True
        }
    ]
    return devices

@router.delete("/connected-devices/{device_id}")
async def logout_device(device_id: str, current_user: Dict[str, Any] = Depends(get_current_user)):
    if device_id == "current":
        raise HTTPException(status_code=400, detail="Cannot logout current device from here. Use Logout button.")
    return {"message": "Device logged out"}

# --- Account Deactivation ---
@router.post("/deactivate-account")
async def deactivate_account(current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$set": {"status": "inactive"}}
    )
    return {"message": "Account deactivated. You will be logged out."}

# --- Two-Factor Authentication ---
@router.post("/2fa/enable")
async def enable_2fa(current_user: Dict[str, Any] = Depends(get_current_user)):
    otp = generate_otp()
    email = current_user["email"]
    
    await db.otp_logs.insert_one({
        "email": email,
        "otp": otp,
        "created_at": datetime.utcnow(),
        "expires_at": datetime.utcnow() + timedelta(minutes=5),
        "is_used": False,
        "type": "2fa_setup"
    })
    
    try:
        await send_otp_email(email, otp)
        return {"message": "Security code sent to your email."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send email: {str(e)}")

@router.post("/2fa/verify")
async def verify_2fa(data: Dict[str, str] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    otp = data.get("otp")
    email = current_user["email"]
    
    otp_record = await db.otp_logs.find_one({
        "email": email,
        "otp": otp,
        "is_used": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })
    
    if not otp_record:
        return {
            "success": False,
            "error_code": "INVALID_OTP",
            "message": "Invalid or expired security code."
        }

    await db.otp_logs.update_one({"_id": otp_record["_id"]}, {"$set": {"is_used": True}})
    
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$set": {"privacy_settings.two_factor_auth": True}}
    )
    return {"message": "Two-factor authentication is now active."}

@router.post("/2fa/disable")
async def disable_2fa(current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.users.update_one(
        {"_id": ObjectId(current_user["id"])},
        {"$set": {"privacy_settings.two_factor_auth": False}}
    )
    return {"message": "Two-factor authentication disabled."}
