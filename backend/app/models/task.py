from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text, ARRAY, ForeignKey
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.database import Base

class Task(Base):
    __tablename__ = "tasks"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(Text)
    status = Column(String(50), default="pending")  # pending, in_progress, completed
    priority = Column(String(20), default="medium")  # low, medium, high, critical
    category = Column(String(100))
    
    estimated_duration = Column(Integer)  # in minutes
    actual_duration = Column(Integer)
    deadline = Column(DateTime)
    scheduled_start = Column(DateTime)
    scheduled_end = Column(DateTime)
    completed_at = Column(DateTime)
    
    # Carryover fields
    carryover_count = Column(Integer, default=0)
    original_deadline = Column(DateTime)
    last_carryover_date = Column(DateTime)
    carryover_reason = Column(Text)
    auto_reschedule_enabled = Column(Boolean, default=True)
    carryover_priority_boost = Column(Integer, default=0)
    
    # Eisenhower Matrix
    is_urgent = Column(Boolean, default=False)
    is_important = Column(Boolean, default=False)
    
    # Recurring
    is_recurring = Column(Boolean, default=False)
    recurrence_pattern = Column(String(50))
    
    # Task decomposition
    parent_task_id = Column(Integer, ForeignKey("tasks.id"))
    is_subtask = Column(Boolean, default=False)
    
    # Metadata
    tags = Column(ARRAY(String), default=[])
    location = Column(String(255))
    context = Column(String(255))
    energy_level = Column(String(20))
    
    created_at = Column(DateTime, server_default=func.now())
    updated_at = Column(DateTime, server_default=func.now(), onupdate=func.now())
    
    # Relationships
    user = relationship("User", back_populates="tasks")
    subtasks = relationship("Task", backref="parent_task", remote_side=[id])
    
    def __repr__(self):
        return f"<Task {self.title}>"