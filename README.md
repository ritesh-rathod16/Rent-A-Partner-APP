# Rent A Partner

Rent A Partner is a verified companionship marketplace. Users can book verified male or female companions for various activities like events, travel, coffee, etc.

## Tech Stack
- **Frontend:** Flutter (Latest Stable)
- **Backend:** Python FastAPI
- **Database:** MongoDB Atlas
- **Payments:** Razorpay
- **Maps:** Google Maps API
- **Notifications:** Firebase Cloud Messaging (FCM)
- **Email/OTP:** Brevo SMTP

## Project Structure
- `frontend/`: Flutter application code.
- `backend/`: FastAPI Python code.
- `docs/`: Documentation and API specs.
- `assets/`: Design assets and images.

## Setup Instructions

### Backend Setup
1. Navigate to `backend/`
2. Create a virtual environment: `python -m venv venv`
3. Activate: `source venv/bin/activate` (Linux/Mac) or `venv\Scripts\activate` (Windows)
4. Install dependencies: `pip install -r requirements.txt`
5. Create `.env` file with necessary credentials.
6. Run: `uvicorn main:app --reload`

### Frontend Setup
1. Navigate to `frontend/`
2. Run `flutter pub get`
3. Create `.env` file for Flutter.
4. Run: `flutter run`
