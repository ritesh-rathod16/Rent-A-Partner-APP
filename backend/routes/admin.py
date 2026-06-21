from fastapi import APIRouter, HTTPException, Body, Depends
from database import db
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from bson import ObjectId
from utils.serializers import serialize_doc, serialize_docs
from pydantic import BaseModel
import requests
from config import settings

router = APIRouter(prefix="/admin", tags=["admin"])

class EmailRequest(BaseModel):
    subject: str
    message: str

class RejectRequest(BaseModel):
    reason: str

# --- Helper for Valid ID ---
def validate_id(id: str):
    if not ObjectId.is_valid(id):
        raise HTTPException(status_code=400, detail="Invalid ID format")

# --- Dashboard Home ---
@router.get("/stats")
async def get_dashboard_stats():
    try:
        total_users = await db.users.count_documents({})
        total_companions = await db.companions.count_documents({"status": "approved"})
        pending_apps = await db.companions.count_documents({"status": "pending"})
        active_bookings = await db.bookings.count_documents({"status": "active"})
        
        active_sos = await db.sos_alerts.count_documents({"status": "active"})
        pending_reports = await db.reports.count_documents({"status": "pending"})
        withdrawal_requests = await db.statements.count_documents({"type": "withdrawal", "status": "PENDING"})
        
        revenue = 0
        pipeline = [{"$match": {"status": "completed"}}, {"$group": {"_id": None, "total": {"$sum": "$total_amount"}}}]
        res = await db.bookings.aggregate(pipeline).to_list(1)
        if res: revenue = res[0]["total"]

        alerts = await db.platform_alerts.find({"status": "active"}).sort("created_at", -1).limit(10).to_list(10)

        return {
            "total_users": total_users,
            "total_companions": total_companions,
            "pending_applications": pending_apps,
            "active_bookings": active_bookings,
            "active_sos": active_sos,
            "pending_reports": pending_reports,
            "withdrawal_requests": withdrawal_requests,
            "total_revenue": revenue,
            "platform_earnings": revenue * 0.25,
            "recent_alerts": serialize_docs(alerts)
        }
    except Exception as e:
        print(f"ADMIN_STATS_ERROR: {e}")
        return {
            "total_users": 0, "total_companions": 0, "pending_applications": 0,
            "active_bookings": 0, "active_sos": 0, "pending_reports": 0,
            "withdrawal_requests": 0, "total_revenue": 0, "platform_earnings": 0,
            "recent_alerts": []
        }

# --- Application Management ---
@router.get("/applications")
async def list_applications(status: str = "pending"):
    apps = await db.companions.find({"status": status}).sort("created_at", -1).to_list(100)
    return serialize_docs(apps)

@router.get("/applications/{id}")
async def get_application_details(id: str):
    validate_id(id)
    app = await db.companions.find_one({"_id": ObjectId(id)})
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    return serialize_doc(app)

@router.post("/applications/{id}/approve")
async def approve_application(id: str):
    validate_id(id)
    oid = ObjectId(id)
    app = await db.companions.find_one({"_id": oid})
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    await db.companions.update_one({"_id": oid}, {"$set": {"status": "approved", "updated_at": datetime.utcnow()}})
    await db.users.update_one({"_id": ObjectId(app["user_id"])}, {"$set": {"is_companion": True, "companion_id": id}})
    
    await db.notifications.insert_one({
        "user_id": app["user_id"],
        "title": "Application Approved!",
        "body": "Congratulations! Your companion profile is now live. Start earning now.",
        "created_at": datetime.utcnow(),
        "is_new": True
    })
    return {"message": "Application approved"}

@router.post("/applications/{id}/reject")
async def reject_application(id: str, req: RejectRequest):
    validate_id(id)
    await db.companions.update_one({"_id": ObjectId(id)}, {"$set": {"status": "rejected", "rejection_reason": req.reason, "updated_at": datetime.utcnow()}})
    return {"message": "Application rejected"}

@router.delete("/applications/{id}")
async def delete_application(id: str):
    validate_id(id)
    await db.companions.delete_one({"_id": ObjectId(id)})
    return {"message": "Application deleted"}

# --- User Management ---
@router.get("/users")
async def list_users():
    users = await db.users.find().to_list(100)
    return serialize_docs(users)

@router.post("/users/{user_id}/status")
async def update_user_status(user_id: str, data: dict = Body(...)):
    validate_id(user_id)
    status = data.get("status")
    await db.users.update_one({"_id": ObjectId(user_id)}, {"$set": {"status": status}})
    return {"message": f"User status updated to {status}"}

@router.delete("/users/{user_id}")
async def delete_user(user_id: str):
    validate_id(user_id)
    await db.users.delete_one({"_id": ObjectId(user_id)})
    return {"message": "User deleted"}

@router.post("/users/{user_id}/verify")
async def verify_user_badge(user_id: str, action: str = Body(..., embed=True)):
    validate_id(user_id)
    account_type = "verified" if action == "verify" else "standard"
    
    # 1. Update Users Collection
    await db.users.update_one({"_id": ObjectId(user_id)}, {"$set": {"account_type": account_type}})
    
    # 2. Update Companions Collection (if exists)
    await db.companions.update_one({"user_id": user_id}, {"$set": {"account_type": account_type}})

    return {"message": f"User account type updated to {account_type}"}

# --- Payment Logs ---
@router.get("/payments")
async def get_payments():
    bookings = await db.bookings.find({"status": {"$in": ["confirmed", "completed"]}}).sort("created_at", -1).to_list(100)
    payments = []
    for b in bookings:
        payments.append({
            "id": str(b["_id"]),
            "user_name": b.get("customer_name", "Unknown"),
            "companion_name": b.get("companion_name", "Unknown"),
            "amount": b.get("total_amount", 0),
            "timestamp": b.get("created_at", datetime.utcnow()).isoformat(),
            "status": b.get("status", "pending"),
            "payment_id": b.get("payment_id", "N/A")
        })
    return payments

# --- SOS & Safety Monitoring ---
@router.get("/sos/alerts")
async def list_sos_alerts():
    alerts = await db.sos_alerts.find({"status": "active"}).sort("triggered_at", -1).to_list(100)
    return serialize_docs(alerts)

@router.post("/sos/{id}/resolve")
async def resolve_sos(id: str):
    validate_id(id)
    oid = ObjectId(id)
    await db.sos_alerts.update_one({"_id": oid}, {"$set": {"status": "resolved", "resolved_at": datetime.utcnow()}})
    await db.platform_alerts.update_many({"sos_id": id}, {"$set": {"status": "resolved"}})
    return {"message": "SOS alert resolved"}

# --- User Reports ---
@router.get("/reports")
async def list_user_reports():
    reports = await db.reports.find().sort("created_at", -1).to_list(100)
    return serialize_docs(reports)

@router.post("/reports/{id}/resolve")
async def resolve_report(id: str):
    validate_id(id)
    await db.reports.update_one({"_id": ObjectId(id)}, {"$set": {"status": "resolved", "resolved_at": datetime.utcnow()}})
    return {"message": "Report resolved"}

# --- Booking Management ---
@router.get("/bookings/active")
async def list_active_bookings():
    bookings = await db.bookings.find({"status": "active"}).to_list(100)
    return serialize_docs(bookings)

@router.get("/bookings/logs")
async def list_booking_logs():
    bookings = await db.bookings.find({"status": {"$in": ["completed", "cancelled"]}}).sort("created_at", -1).to_list(100)
    return serialize_docs(bookings)

@router.get("/bookings/{id}")
async def get_booking_by_id(id: str):
    validate_id(id)
    booking = await db.bookings.find_one({"_id": ObjectId(id)})
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return serialize_doc(booking)

# --- Notification Center ---
@router.post("/notifications/send")
async def send_custom_notification(data: Dict[str, Any] = Body(...)):
    title = data.get("title")
    message = data.get("message")
    target = data.get("target", "all")
    
    query = {}
    if target == "verified": query = {"account_type": "verified"}
    elif target == "companions": query = {"is_companion": True}
    elif target == "specific": 
        uid = data.get("user_id")
        validate_id(uid)
        query = {"_id": ObjectId(uid)}
    
    users_list = await db.users.find(query, {"_id": 1}).to_list(None)
    
    await db.notification_history.insert_one({
        "title": title,
        "message": message,
        "target": target,
        "recipient_count": len(users_list),
        "status": "Delivered",
        "created_at": datetime.utcnow()
    })
    
    for u in users_list:
        await db.notifications.insert_one({
            "user_id": str(u["_id"]),
            "title": title,
            "body": message,
            "created_at": datetime.utcnow(),
            "is_new": True
        })
    
    return {"success": True, "recipients": len(users_list)}

@router.get("/notifications/history")
async def get_notification_history():
    history = await db.notification_history.find().sort("created_at", -1).to_list(100)
    return serialize_docs(history)

# --- Statements Management ---
@router.get("/statements")
async def get_all_statements():
    statements = await db.statements.find().sort("date", -1).to_list(100)
    return serialize_docs(statements)

@router.delete("/statements/{id}")
async def delete_statement(id: str):
    validate_id(id)
    await db.statements.delete_one({"_id": ObjectId(id)})
    return {"message": "Statement deleted"}

# --- System Settings ---
@router.post("/settings/update")
async def update_settings(data: dict = Body(...)):
    await db.settings.update_one({"type": "system_config"}, {"$set": data}, upsert=True)
    return {"message": "Settings updated"}

@router.get("/settings/verification")
async def get_verification_settings():
    settings = await db.settings.find_one({"type": "verification_config"})
    if not settings:
        return {
            "verification_price": 499, 
            "description": "Upgrade to Verified Partner for priority ranking and more trust.",
            "benefits": ["Priority Ranking", "Verified Badge", "Higher Trust Score", "Premium Visibility"]
        }
    return serialize_doc(settings)

@router.patch("/settings/verification")
async def update_verification_settings(data: dict = Body(...)):
    await db.settings.update_one(
        {"type": "verification_config"}, 
        {"$set": {
            "verification_price": data.get("verification_price"),
            "description": data.get("description"),
            "benefits": data.get("benefits"),
            "updated_at": datetime.utcnow()
        }}, 
        upsert=True
    )
    return {"message": "Verification settings updated"}

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

@router.post("/sync-companion-badges")
async def sync_companion_badges():
    companions = await db.companions.find().to_list(None)
    count = 0
    for c in companions:
        user = await db.users.find_one({"_id": ObjectId(c["user_id"])})
        if user and "account_type" in user:
            await db.companions.update_one({"_id": c["_id"]}, {"$set": {"account_type": user["account_type"]}})
            count += 1
    return {"message": f"Synced badges for {count} companions"}

# --- Bulk Email ---
@router.post("/send-email-all")
async def send_email_all(req: EmailRequest):
    users_cursor = db.users.find({}, {"email": 1})
    users = await users_cursor.to_list(None)
    emails = [u["email"] for u in users if "email" in u]
    sent, failed = 0, 0
    url = "https://api.brevo.com/v3/smtp/email"
    headers = {"accept": "application/json", "content-type": "application/json", "api-key": settings.BREVO_API_KEY}
    for email in emails:
        payload = {"sender": {"name": "Rent A Partner", "email": settings.EMAIL_FROM}, "to": [{"email": email}], "subject": req.subject, "textContent": req.message}
        try:
            r = requests.post(url, json=payload, headers=headers, timeout=5)
            if r.status_code in [200, 201]: sent += 1
            else: failed += 1
        except: failed += 1
    return {"success": True, "sent": sent, "failed": failed}
