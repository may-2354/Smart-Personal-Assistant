from pymongo import MongoClient

try:
    # Try without authentication first
    client = MongoClient("mongodb://localhost:27017/")
    db = client.smart_assistant
    
    # Test write
    test_collection = db.test
    test_collection.insert_one({"test": "Hello MongoDB!", "status": "working"})
    
    # Test read
    result = test_collection.find_one({"test": "Hello MongoDB!"})
    
    print("✅ MongoDB connection successful!")
    print(f"Test document: {result}")
    print(f"Databases available: {client.list_database_names()}")
    
    # Cleanup
    test_collection.delete_many({"test": "Hello MongoDB!"})
    client.close()
    
except Exception as e:
    print(f"❌ MongoDB connection failed: {e}")