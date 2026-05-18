from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from fastapi import HTTPException, status
from datetime import datetime
from typing import List, Optional

from app.models.task import Task
from app.schemas.task import TaskCreate, TaskUpdate, TaskStatus

class TaskService:
    def __init__(self, db: Session):
        self.db = db
    
    def create_task(self, user_id: int, task_data: TaskCreate) -> Task:
        """Create a new task for user"""
        # Create task
        new_task = Task(
            user_id=user_id,
            title=task_data.title,
            description=task_data.description,
            priority=task_data.priority,
            category=task_data.category,
            deadline=task_data.deadline,
            tags=task_data.tags or [],
            status="pending"
        )
        
        # Auto-classify using Eisenhower Matrix
        if task_data.deadline:
            # If deadline is within 24 hours, mark as urgent
            time_until_deadline = (task_data.deadline - datetime.utcnow()).days
            new_task.is_urgent = time_until_deadline <= 1
        
        # High and critical priority tasks are important
        new_task.is_important = task_data.priority in ["high", "critical"]
        
        self.db.add(new_task)
        self.db.commit()
        self.db.refresh(new_task)
        
        return new_task
    
    def get_user_tasks(
        self, 
        user_id: int, 
        status: Optional[str] = None,
        priority: Optional[str] = None,
        category: Optional[str] = None,
        skip: int = 0,
        limit: int = 100
    ) -> List[Task]:
        """Get all tasks for a user with optional filters"""
        query = self.db.query(Task).filter(Task.user_id == user_id)
        
        # Apply filters
        if status:
            query = query.filter(Task.status == status)
        if priority:
            query = query.filter(Task.priority == priority)
        if category:
            query = query.filter(Task.category == category)
        
        # Order by deadline and priority
        query = query.order_by(
            Task.deadline.asc().nullslast(),
            Task.priority.desc()
        )
        
        tasks = query.offset(skip).limit(limit).all()
        return tasks
    
    def get_task_by_id(self, user_id: int, task_id: int) -> Task:
        """Get a specific task by ID"""
        task = self.db.query(Task).filter(
            Task.id == task_id,
            Task.user_id == user_id
        ).first()
        
        if not task:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Task not found"
            )
        
        return task
    
    def update_task(self, user_id: int, task_id: int, task_update: TaskUpdate) -> Task:
        """Update a task"""
        task = self.get_task_by_id(user_id, task_id)
        
        # Update fields if provided
        update_data = task_update.dict(exclude_unset=True)
        
        for field, value in update_data.items():
            setattr(task, field, value)
        
        # Update timestamp
        task.updated_at = datetime.utcnow()
        
        # If status changed to completed, set completed_at
        if task_update.status == TaskStatus.completed:
            task.completed_at = datetime.utcnow()
        
        self.db.commit()
        self.db.refresh(task)
        
        return task
    
    def delete_task(self, user_id: int, task_id: int) -> dict:
        """Delete a task"""
        task = self.get_task_by_id(user_id, task_id)
        
        self.db.delete(task)
        self.db.commit()
        
        return {"message": "Task deleted successfully", "task_id": task_id}
    
    def get_overdue_tasks(self, user_id: int) -> List[Task]:
        """Get all overdue tasks for a user"""
        now = datetime.utcnow()
        
        overdue_tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.deadline < now
        ).all()
        
        return overdue_tasks
    
    def get_today_tasks(self, user_id: int) -> List[Task]:
        """Get tasks due today"""
        from datetime import date
        today = date.today()
        
        tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == "pending",
            Task.deadline >= datetime.combine(today, datetime.min.time()),
            Task.deadline < datetime.combine(today, datetime.max.time())
        ).all()
        
        return tasks
    
    def get_task_stats(self, user_id: int) -> dict:
        """Get task statistics for user"""
        total = self.db.query(Task).filter(Task.user_id == user_id).count()
        completed = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == "completed"
        ).count()
        pending = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == "pending"
        ).count()
        in_progress = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == "in_progress"
        ).count()
        overdue = len(self.get_overdue_tasks(user_id))
        
        completion_rate = (completed / total * 100) if total > 0 else 0
        
        return {
            "total": total,
            "completed": completed,
            "pending": pending,
            "in_progress": in_progress,
            "overdue": overdue,
            "completion_rate": round(completion_rate, 2)
        }