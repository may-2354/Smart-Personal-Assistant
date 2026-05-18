from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

# Find user
user = db.query(User).filter(User.email == "Prajakta@example.com").first()

if user:
    print(f"✅ User found!")
    print(f"   ID: {user.id}")
    print(f"   Email: {user.email}")
    print(f"   Username: {user.username}")
    print(f"   Password hash: {user.password_hash[:30]}...")
else:
    print("❌ User not found!")

db.close()