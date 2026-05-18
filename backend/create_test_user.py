from sqlalchemy.orm import Session
from app.database import SessionLocal
from app.models.user import User
from app.utils.security import get_password_hash

db = SessionLocal()

try:
    # Delete old user if exists
    old_user = db.query(User).filter(User.email == "test@test.com").first()
    if old_user:
        db.delete(old_user)
        db.commit()
        print("Deleted old test user")
    
    # Create fresh user with working hash
    new_user = User(
        email="test@test.com",
        username="testuser",
        full_name="Test User",
        password_hash=get_password_hash("test1234")
    )
    
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    
    print(f"✅ New test user created!")
    print(f"   Email: {new_user.email}")
    print(f"   Username: {new_user.username}")
    print(f"   Password: test1234")
    print(f"   Hash: {new_user.password_hash[:50]}...")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
finally:
    db.close()