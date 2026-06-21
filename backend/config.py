from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGODB_URL: str = "mongodb+srv://rentapartner:RentPartner%402026@db01.faavjjk.mongodb.net/rent_a_partner?retryWrites=true&w=majority&appName=db01"
    DATABASE_NAME: str = "rent_a_partner"
    SECRET_KEY: str = "rahFhJk9phc-WPIO-3WmSJ2ZiNIyu6dmBGZaEvns_QQ_qvpbIF249NuwU_7FMtu9T5k"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    BASE_URL: str = "https://rent-a-partner-app.onrender.com" # Overridden by .env or Render ENV VAR
    
    # Razorpay
    RAZORPAY_KEY_ID: str = "rzp_live_S3PqGffrDLRgtX"
    RAZORPAY_KEY_SECRET: str = "iWHq838HUbipymFAZ24nfc64"
    
    # Google Maps
    GOOGLE_MAPS_SERVER_API_KEY: str = ""
    
    # Brevo API
    BREVO_API_KEY: str = "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"
    EMAIL_FROM: str = "riteshrathod016@gmail.com"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
