from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

print("MONGODB_URL =", settings.MONGODB_URL)
print("DATABASE_NAME =", settings.DATABASE_NAME)

client = AsyncIOMotorClient(settings.MONGODB_URL)
db = client[settings.DATABASE_NAME]