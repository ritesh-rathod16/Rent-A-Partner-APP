from fastapi import APIRouter, HTTPException, Depends, Body, File, UploadFile, Request
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr
import shutil
import os
from database import db
from models.user import User
from utils.email import send_otp_email
from datetime import datetime, timedelta
from jose import jwt, JWTError
from config import settings
import random
from typing import Optional, Dict, Any
from fastapi.security import OAuth2PasswordBearer
from bson import ObjectId
import razorpay

router = APIRouter(
    prefix="/auth",
    tags=["Authentication"]
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

#=====================================================
#HELPERS
#=====================================================

def auth_error(status_code: int, error_code: str, message: str):
    print(f"AUTH_ERROR: {error_code} - {message}")
    return JSONResponse(
        status_code=status_code,
        content={
            "success": False,
            "error_code": error_code,
            "message": message
        }
    )

def generate_otp() -> str:
    return str(random.randint(100000, 999999))

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = await db.users.find_one({"email": email})
    if user is None:
        raise credentials_exception
    user["id"] = str(user["_id"])
    return user

#=====================================================
#REQUEST MODELS
#=====================================================

class VerifyOTPRequest(BaseModel):
    email: EmailStr
    otp: str

class LoginRequest(BaseModel):
    email: EmailStr
    password: Optional[str] = None

#=====================================================
#REGISTER USER
#=====================================================

@router.post("/register")
async def register(user_data: User):
    email = user_data.email.lower().strip()
    
    print(f"DEBUG: Registering user {email}")
    
    # 1. Check Email
    existing_user = await db.users.find_one({"email": email})
    if existing_user:
        return auth_error(400, "EMAIL_EXISTS", "This email is already registered. Please sign in or use another email.")

    # 2. Check Phone
    if user_data.phone_number:
        existing_phone = await db.users.find_one({"phone_number": user_data.phone_number})
        if existing_phone:
            return auth_error(400, "PHONE_EXISTS", "This phone number is already registered.")

    # 3. Check Age (Minimum 18)
    if user_data.dob:
        try:
            birth_date = datetime.strptime(user_data.dob, "%Y-%m-%d")
            age = (datetime.utcnow() - birth_date).days // 365
            if age < 18:
                return auth_error(400, "UNDERAGE", "You must be at least 18 years old to register.")
        except Exception as e:
            print(f"DEBUG: DOB Parsing error {e}")
            pass

    user_dict = user_data.model_dump()
    user_dict["email"] = email
    if "_id" in user_dict and user_dict["_id"] is None:
        user_dict.pop("_id")
    user_dict["is_verified"] = False
    user_dict["city"] = user_data.city
    user_dict["phone_number"] = user_data.phone_number
    user_dict["created_at"] = datetime.utcnow()
    user_dict["wallet_balance"] = 0.0
    user_dict["status"] = "active"

    result = await db.users.insert_one(user_dict)

    otp = generate_otp()

    await db.otp_logs.insert_one({
        "email": email,
        "otp": otp,
        "created_at": datetime.utcnow(),
        "expires_at": datetime.utcnow() + timedelta(minutes=5),
        "is_used": False
    })

    try:
        await send_otp_email(user_data.email, otp)
    except Exception as e:
        print("EMAIL ERROR:", str(e))

    print(f"--- REGISTRATION OTP FOR {user_data.email}: {otp} ---")

    return {
        "success": True,
        "message": "Registration successful",
        "user_id": str(result.inserted_id)
    }

#=====================================================
#VERIFY OTP
#=====================================================

@router.post("/verify-otp")
async def verify_otp(data: VerifyOTPRequest):
    email = data.email.lower().strip()
    print(f"DEBUG: Verifying OTP for {email}")
    
    otp_record = await db.otp_logs.find_one({
        "email": email,
        "otp": data.otp,
        "is_used": False,
        "expires_at": {"$gt": datetime.utcnow()}
    })

    if not otp_record:
        return auth_error(400, "INVALID_OTP", "Invalid or expired OTP. Please check your email.")

    await db.otp_logs.update_one({"_id": otp_record["_id"]}, {"$set": {"is_used": True}})
    await db.users.update_one({"email": email}, {"$set": {"is_verified": True}})

    token = jwt.encode({"sub": email}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

    return {
        "success": True,
        "message": "OTP verified successfully",
        "access_token": token,
        "token_type": "bearer"
    }

#=====================================================
#LOGIN
#=====================================================

@router.post("/login")
async def login(data: LoginRequest):
    email = data.email.lower().strip()
    print(f"DEBUG: Login attempt for {email}")
    
    user = await db.users.find_one({"email": email})

    if not user:
        return auth_error(404, "USER_NOT_FOUND", "No account found with this email.")

    # Check status
    if user.get("status") == "suspended":
        return auth_error(403, "ACCOUNT_SUSPENDED", "Your account has been temporarily suspended. Contact support for assistance.")
    
    if user.get("status") == "banned":
        return auth_error(403, "ACCOUNT_BANNED", "Your account has been permanently banned.")

    if data.password and user.get("password") != data.password:
        return auth_error(401, "WRONG_PASSWORD", "Incorrect password. Please try again.")

    if not user.get("is_verified", False) or user.get("privacy_settings", {}).get("two_factor_auth", False):
        # Send OTP if not verified OR if 2FA is enabled
        otp = generate_otp()
        await db.otp_logs.insert_one({
            "email": email,
            "otp": otp,
            "created_at": datetime.utcnow(),
            "expires_at": datetime.utcnow() + timedelta(minutes=5),
            "is_used": False
        })
        try:
            await send_otp_email(email, otp)
        except: pass
        
        print(f"--- LOGIN OTP FOR {email}: {otp} ---")
        return {"success": True, "message": "OTP sent", "require_otp": True}

    # If already verified and password matches, just log in!
    token = jwt.encode({"sub": email}, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return {
        "success": True,
        "message": "Login successful",
        "access_token": token,
        "token_type": "bearer",
        "require_otp": False
    }

@router.get("/me")
async def get_me(current_user: Dict[str, Any] = Depends(get_current_user)):
    # Remove sensitive info
    current_user.pop("password", None)
    current_user["_id"] = str(current_user["_id"])
    return current_user

@router.post("/update-profile")
async def update_profile(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    # Block manual photo_url updates to prevent local path persistence
    if "photo_url" in data:
        photo = data["photo_url"]
        if photo and (photo.startswith("/") or "data/user" in photo or "cache" in photo):
             data.pop("photo_url")

    await db.users.update_one({"_id": current_user["_id"]}, {"$set": data})
    return {"message": "Profile updated"}

client = razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

@router.post("/wallet/add")
async def add_money(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    amount = data.get("amount", 0)
    try:
        order_data = {
            "amount": int(amount * 100),
            "currency": "INR",
            "payment_capture": 1
        }
        razorpay_order = client.order.create(data=order_data)
        return {
            "success": True,
            "razorpay_order_id": razorpay_order['id'],
            "amount": amount
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Razorpay Error: {str(e)}")

@router.post("/wallet/confirm")
async def confirm_wallet_payment(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    razorpay_order_id = data.get("razorpay_order_id")
    razorpay_payment_id = data.get("razorpay_payment_id")
    razorpay_signature = data.get("razorpay_signature")
    amount = data.get("amount", 0)
    
    # 0. Verify Signature
    params_dict = {
        'razorpay_order_id': razorpay_order_id,
        'razorpay_payment_id': razorpay_payment_id,
        'razorpay_signature': razorpay_signature
    }
    
    try:
        client.utility.verify_payment_signature(params_dict)
    except Exception as e:
        raise HTTPException(status_code=400, detail="Invalid payment signature")

    user_id = ObjectId(current_user["id"])
    
    # 1. Update Balance
    await db.users.update_one({"_id": user_id}, {"$inc": {"wallet_balance": amount}})
    
    # 2. Log Transaction (For Statements)
    await db.statements.insert_one({
        "user_id": str(user_id),
        "user_name": current_user["full_name"],
        "amount": amount,
        "type": "credit",
        "content": f"Added ₹{amount} to wallet via Razorpay",
        "date": datetime.utcnow().isoformat(),
        "status": "Success"
    })
    
    # 3. Create Notification
    await db.notifications.insert_one({
        "user_id": str(user_id),
        "title": "Payment Successful",
        "body": f"₹{amount} has been added to your wallet.",
        "time": "Just now",
        "is_new": True,
        "created_at": datetime.utcnow()
    })
    
    return {"message": "Money added to wallet", "new_balance": current_user.get("wallet_balance", 0) + amount}

@router.get("/notifications")
async def get_my_notifications(current_user: Dict[str, Any] = Depends(get_current_user)):
    # Delete notifications viewed more than 30 mins ago
    thirty_mins_ago = datetime.utcnow() - timedelta(minutes=30)
    await db.notifications.delete_many({
        "user_id": current_user["id"],
        "viewed_at": {"$lt": thirty_mins_ago}
    })

    notes = await db.notifications.find({"user_id": current_user["id"]}).sort("created_at", -1).to_list(50)
    
    # Mark as viewed if not already
    for n in notes:
        n["_id"] = str(n["_id"])
        if "viewed_at" not in n:
            await db.notifications.update_one(
                {"_id": ObjectId(n["_id"])},
                {"$set": {"viewed_at": datetime.utcnow(), "is_new": False}}
            )
    return notes

@router.post("/notifications/mark-read")
async def mark_notifications_read(current_user: Dict[str, Any] = Depends(get_current_user)):
    await db.notifications.delete_many({"user_id": current_user["id"]})
    return {"message": "Notifications cleared"}

@router.post("/favorites/toggle")
async def toggle_favorite(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    companion_id = data.get("companion_id")
    user_id = ObjectId(current_user["id"])
    
    user = await db.users.find_one({"_id": user_id})
    favorites = user.get("favorites", [])
    
    if companion_id in favorites:
        favorites.remove(companion_id)
        msg = "Removed from favorites"
    else:
        favorites.append(companion_id)
        msg = "Added to favorites"
        
    await db.users.update_one({"_id": user_id}, {"$set": {"favorites": favorites}})
    return {"message": msg, "favorites": favorites}

@router.post("/update-photo")
async def update_photo(file: UploadFile = File(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    try:
        # Validate file type
        if not file.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="File must be an image")
            
        os.makedirs("uploads/profile", exist_ok=True)
        file_extension = file.filename.split(".")[-1]
        file_name = f"profile_{current_user['id']}_{int(datetime.utcnow().timestamp())}.{file_extension}"
        file_path = f"uploads/profile/{file_name}"
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        # Store relative path in DB to be flexible with BASE_URL changes
        relative_url = f"profile/{file_name}"
        await db.users.update_one({"_id": ObjectId(current_user["id"])}, {"$set": {"photo_url": relative_url}})
        
        return {"photo_url": relative_url, "message": "Photo uploaded successfully"}
    except Exception as e:
        print(f"UPLOAD_ERROR: {e}")
        raise HTTPException(status_code=500, detail=str(e))
