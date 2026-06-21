from pymongo import MongoClient

uri = "mongodb+srv://rentapartner:RentPartner%402026@db01.faavjjk.mongodb.net/?retryWrites=true&w=majority&appName=db01"

client = MongoClient(uri)

print(client.admin.command("ping"))
print("Connected!")