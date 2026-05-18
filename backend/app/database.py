from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from pymongo import MongoClient
import redis
import os
from dotenv import load_dotenv

load_dotenv()

# PostgreSQL
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# MongoDB
MONGODB_URL = os.getenv("MONGODB_URL")
mongo_client = MongoClient(MONGODB_URL)
mongo_db = mongo_client.smart_assistant

def get_mongo_db():
    return mongo_db

# Redis
REDIS_URL = os.getenv("REDIS_URL")
redis_client = redis.from_url(REDIS_URL, decode_responses=True)

def get_redis():
    return redis_client