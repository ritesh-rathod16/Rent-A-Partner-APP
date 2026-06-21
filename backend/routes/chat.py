import shutil
import os
from fastapi import APIRouter, HTTPException, Depends, Body, File, UploadFile
from database import db
from routes.auth import get_current_user
from typing import List, Dict, Any
from datetime import datetime
from bson import ObjectId
from utils.serializers import serialize_doc, serialize_docs

router = APIRouter(prefix="/chat", tags=["Chat"])

@router.post("/send")
async def send_message(data: Dict[str, Any] = Body(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    recipient_id = data.get("recipient_id")
    text = data.get("text")
    image_url = data.get("image_url")
    msg_type = data.get("type", "text") # text, image
    
    if not recipient_id:
        return {"success": False, "message": "Recipient required"}
        
    message = {
        "sender_id": current_user["id"],
        "recipient_id": recipient_id,
        "text": text,
        "image_url": image_url,
        "type": msg_type,
        "created_at": datetime.utcnow(),
        "is_read": False,
        "is_liked": False
    }
    
    result = await db.messages.insert_one(message)
    return {"success": True, "status": "sent", "message_id": str(result.inserted_id)}

@router.post("/upload-image")
async def upload_chat_image(file: UploadFile = File(...), current_user: Dict[str, Any] = Depends(get_current_user)):
    try:
        os.makedirs("uploads/chat", exist_ok=True)
        file_extension = file.filename.split(".")[-1]
        file_name = f"chat_{current_user['id']}_{int(datetime.utcnow().timestamp())}.{file_extension}"
        file_path = f"uploads/chat/{file_name}"
        
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
            
        return {"image_url": f"chat/{file_name}", "success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/message/{msg_id}/like")
async def toggle_like(msg_id: str, current_user: Dict[str, Any] = Depends(get_current_user)):
    msg = await db.messages.find_one({"_id": ObjectId(msg_id)})
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found")
    
    new_like_status = not msg.get("is_liked", False)
    await db.messages.update_one({"_id": ObjectId(msg_id)}, {"$set": {"is_liked": new_like_status}})
    return {"success": True, "is_liked": new_like_status}

@router.get("/messages/{peer_id}")
async def get_messages(peer_id: str, current_user: Dict[str, Any] = Depends(get_current_user)):
    user_id = current_user["id"]
    
    messages = await db.messages.find({
        "$or": [
            {"sender_id": user_id, "recipient_id": peer_id},
            {"sender_id": peer_id, "recipient_id": user_id}
        ]
    }).sort("created_at", 1).to_list(100)
    
    await db.messages.update_many(
        {"sender_id": peer_id, "recipient_id": user_id, "is_read": False},
        {"$set": {"is_read": True}}
    )
    
    return serialize_docs(messages)

@router.get("/conversations")
async def get_conversations(current_user: Dict[str, Any] = Depends(get_current_user)):
    user_id = current_user["id"]
    
    pipeline = [
        {"$match": {"$or": [{"sender_id": user_id}, {"recipient_id": user_id}]}},
        {"$sort": {"created_at": -1}},
        {
            "$group": {
                "_id": {
                    "$cond": [
                        {"$eq": ["$sender_id", user_id]},
                        "$recipient_id",
                        "$sender_id"
                    ]
                },
                "last_message": {"$first": "$text"},
                "timestamp": {"$first": "$created_at"},
                "unread_count": {
                    "$sum": {
                        "$cond": [
                            {"$and": [{"$eq": ["$recipient_id", user_id]}, {"$eq": ["$is_read", False]}]},
                            1,
                            0
                        ]
                    }
                }
            }
        }
    ]
    
    peers = await db.messages.aggregate(pipeline).to_list(100)
    
    enriched_peers = []
    for p in peers:
        peer_id = p["_id"]
        user_info = await db.users.find_one({"_id": ObjectId(peer_id) if len(peer_id) == 24 else peer_id})
        if user_info:
            enriched_peers.append({
                "peer_id": str(peer_id),
                "peer_name": user_info.get("full_name", "Unknown"),
                "peer_photo": user_info.get("photo_url", ""),
                "last_message": p["last_message"],
                "timestamp": p["timestamp"],
                "unread_count": p["unread_count"]
            })
            
    return enriched_peers
