from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Achievement(Base):
    __tablename__ = "achievements"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False, unique=True)
    description = Column(String(500))
    badge_icon = Column(String(100))  # Emoji or icon name
    points = Column(Integer, default=0)
    criteria = Column(JSON)  # JSON with achievement criteria
    category = Column(String(100))  # productivity, consistency, recovery, milestone
    rarity = Column(String(20), default='common')  # common, rare, epic, legendary
    created_at = Column(DateTime, server_default=func.now())

class UserAchievement(Base):
    __tablename__ = "user_achievements"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    achievement_id = Column(Integer, ForeignKey("achievements.id"), nullable=False)
    earned_at = Column(DateTime, server_default=func.now())
    progress = Column(Integer, default=100)  # For progressive achievements
    
    # Relationships
    achievement = relationship("Achievement")

class Streak(Base):
    __tablename__ = "streaks"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    streak_type = Column(String(50), nullable=False)  # daily_completion, weekly_goal
    current_count = Column(Integer, default=0)
    best_count = Column(Integer, default=0)
    last_activity_date = Column(DateTime)
    started_at = Column(DateTime, server_default=func.now())
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())