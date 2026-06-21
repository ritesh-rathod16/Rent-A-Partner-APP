from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from routes import auth, companion, booking, admin, review, tracking, ads, user, safety, chat
import uvicorn
import os
import traceback

app = FastAPI(title="Rent A Partner API")

# Custom Validation Error Handler (Handle 422)
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    print(f"VALIDATION_ERROR at {request.url}: {errors}")
    
    # Default message
    msg = "Please complete all required fields correctly."
    
    if errors:
        error = errors[0]
        field = error['loc'][-1]
        raw_msg = error['msg']
        
        # Field mapping for user-friendly names
        field_map = {
            "full_name": "Full Name",
            "email": "Email Address",
            "phone_number": "Phone Number",
            "city": "City",
            "dob": "Date of Birth",
            "reason": "Report Reason",
            "description": "Description",
            "reported_user_id": "Target User",
            "booking_id": "Booking ID"
        }
        
        # Use string formatting to avoid 'str' unresolved reference warning if it persists
        field_str = "{}".format(field)
        display_field = field_map.get(field, field_str.replace('_', ' ').title())
        
        err_type = error.get('type', '')
        
        if 'missing' in err_type or 'missing' in raw_msg.lower():
            msg = f"The {display_field} is required."
        elif 'email' in err_type or 'email' in raw_msg.lower():
            msg = "Please enter a valid email address."
        else:
            msg = f"Invalid {display_field}: {raw_msg}"
        
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "success": False,
            "error_code": "VALIDATION_ERROR",
            "message": msg,
            "errors": errors
        },
    )

# Global Exception Handler for Production
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print(f"CRITICAL_SERVER_ERROR at {request.url}:")
    traceback.print_exc()

    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error_code": "INTERNAL_SERVER_ERROR",
            "message": "Something went wrong on our end. Please try again later."
        }
    )

# Ensure uploads directory exists
if not os.path.exists("uploads"):
    os.makedirs("uploads")
    os.makedirs("uploads/profile", exist_ok=True)
    os.makedirs("uploads/companion", exist_ok=True)
    os.makedirs("uploads/gallery", exist_ok=True)
    os.makedirs("uploads/panic_recordings", exist_ok=True)
    os.makedirs("uploads/chat", exist_ok=True)

# Serve static files from uploads directory
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(auth.router)
app.include_router(user.router)
app.include_router(companion.router)
app.include_router(booking.router)
app.include_router(admin.router)
app.include_router(review.router)
app.include_router(tracking.router)
app.include_router(ads.router)
app.include_router(safety.router)
app.include_router(chat.router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Welcome to Rent A Partner API"}

if __name__ == "__main__":
    # Get port from environment variable for Render deployment
    server_port = int(os.environ.get("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=server_port, reload=False)
