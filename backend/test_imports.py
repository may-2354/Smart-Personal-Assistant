print("Testing imports...")
try:
    import fastapi
    print("✅ FastAPI")
    import sqlalchemy
    print("✅ SQLAlchemy")
    import pymongo
    print("✅ PyMongo")
    import redis
    print("✅ Redis")
    from dotenv import load_dotenv
    print("✅ python-dotenv")
    print("\n🎉 All core packages imported successfully!")
except Exception as e:
    print(f"❌ Error: {e}")