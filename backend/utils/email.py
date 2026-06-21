import requests
from config import settings

async def send_otp_email(email: str, otp: str):
    url = "https://api.brevo.com/v3/smtp/email"
    headers = {
        "accept": "application/json",
        "content-type": "application/json",
        "api-key": settings.BREVO_API_KEY # Use Brevo v3 API Key
    }
    payload = {
        "sender": {"name": "Rent A Partner", "email": settings.EMAIL_FROM},
        "to": [{"email": email}],
        "replyTo": {"email": settings.EMAIL_FROM},
        "subject": "Verify Your Account - Rent A Partner",
        "htmlContent": f"""
            <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
                <h2 style="color: #FF4D8D;">Welcome to Rent A Partner</h2>
                <p>Use the following code to verify your account:</p>
                <div style="background: #f4f4f4; padding: 15px; font-size: 24px; font-weight: bold; letter-spacing: 5px; text-align: center;">
                    {otp}
                </div>
                <p style="color: #666; font-size: 12px; margin-top: 20px;">This code will expire in 5 minutes. If you did not request this, please ignore this email.</p>
            </div>
        """
    }
    try:
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        if response.status_code not in [200, 201]:
            print(f"--- BREVO API ERROR ---")
            print(f"Status: {response.status_code}")
            print(f"Body: {response.text}")
            print(f"Sender Email: {settings.EMAIL_FROM} (Must be verified in Brevo)")
            print(f"-----------------------")
        else:
            print(f"OTP Email sent successfully to {email}")
    except Exception as e:
        print(f"EMAIL_CONNECTION_ERROR: {e}")
