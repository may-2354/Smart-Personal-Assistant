from app.utils.security import verify_password, get_password_hash
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()

# Get user
user = db.query(User).filter(User.email == "Prajakta@example.com").first()

if user:
    print(f"Testing password for: {user.email}")
    print(f"Stored hash: {user.password_hash[:50]}...")
    
    # Test with the password you're using
    test_password = "prajakta123"
    
    try:
        result = verify_password(test_password, user.password_hash)
        if result:
            print(f"✅ Password verification SUCCESS!")
        else:
            print(f"❌ Password verification FAILED!")
            print(f"   The hash doesn't match the password")
    except Exception as e:
        print(f"❌ Error during verification: {e}")
else:
    print("❌ User not found")

db.close()