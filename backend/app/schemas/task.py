from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, List
from enum import Enum

class TaskStatus(str, Enum):
    pending = "pending"
    in_progress = "in_progress"
    completed = "completed"
    cancelled = "cancelled"

class TaskPriority(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"

class TaskBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=500)
    description: Optional[str] = None
    priority: TaskPriority = TaskPriority.medium
    category: Optional[str] = None
    deadline: Optional[datetime] = None
    tags: Optional[List[str]] = []

class TaskCreate(TaskBase):
    pass

class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[TaskStatus] = None
    priority: Optional[TaskPriority] = None
    deadline: Optional[datetime] = None

class TaskResponse(TaskBase):
    id: int
    user_id: int
    status: TaskStatus
    carryover_count: int
    is_urgent: bool
    is_important: bool
    estimated_duration: Optional[int] = None  # ADD THIS - in minutes
    actual_duration: Optional[int] = None     # ADD THIS - in minutes
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True