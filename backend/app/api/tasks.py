from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from app.services.carryover_service import CarryoverService
from app.services.scheduling_service import SchedulingService
from app.integrations.gemini_api import GeminiService

from app.database import get_db
from app.schemas.task import TaskCreate, TaskUpdate, TaskResponse
from app.services.task_service import TaskService
from app.api.auth import get_current_user
from app.models.user import User

router = APIRouter()

def estimate_task_duration(task_data: TaskCreate) -> int:
    """
    Automatically estimate task duration in minutes based on multiple factors
    """
    # Base duration by priority
    base_durations = {
        'critical': 90,
        'high': 60,
        'medium': 30,
        'low': 15
    }
    
    duration = base_durations.get(task_data.priority.lower(), 30)
    
    # Adjust by description length
    if task_data.description:
        desc_length = len(task_data.description)
        if desc_length > 200:
            duration += 15  # Complex task
        elif desc_length < 50:
            duration -= 10  # Simple task
    
    # Adjust by category
    if task_data.category:
        category_lower = task_data.category.lower()
        if category_lower in ['work', 'academic', 'project']:
            duration += 15  # More time-consuming
        elif category_lower in ['shopping', 'quick', 'errand']:
            duration = max(5, duration - 10)  # Quick tasks
    
    # Detect keywords in title
    title_lower = task_data.title.lower()
    time_consuming_keywords = ['report', 'presentation', 'project', 'research', 'study', 'write', 'develop']
    quick_keywords = ['call', 'email', 'buy', 'quick', 'check']
    
    if any(keyword in title_lower for keyword in time_consuming_keywords):
        duration += 15
    elif any(keyword in title_lower for keyword in quick_keywords):
        duration = max(5, duration - 10)
    
    # Eisenhower matrix adjustment (use getattr to safely check)
    is_urgent = getattr(task_data, 'is_urgent', False)
    is_important = getattr(task_data, 'is_important', False)
    if is_urgent and is_important:
        duration += 10  # Critical tasks often take longer
    
    # Ensure minimum and maximum bounds
    duration = max(5, min(duration, 240))  # 5 min to 4 hours max
    
    return duration

@router.post("/", response_model=TaskResponse, status_code=status.HTTP_201_CREATED)
def create_task(
    task_data: TaskCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create a new task with automatic duration estimation"""
    service = TaskService(db)
    task = service.create_task(current_user.id, task_data)
    
    # Auto-estimate duration if not provided
    if not task.estimated_duration:
        task.estimated_duration = estimate_task_duration(task_data)
        db.commit()
        db.refresh(task)
    
    return task

@router.get("/", response_model=List[TaskResponse])
def get_tasks(
    status: Optional[str] = Query(None, description="Filter by status"),
    priority: Optional[str] = Query(None, description="Filter by priority"),
    category: Optional[str] = Query(None, description="Filter by category"),
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all tasks for current user with optional filters"""
    service = TaskService(db)
    tasks = service.get_user_tasks(
        user_id=current_user.id,
        status=status,
        priority=priority,
        category=category,
        skip=skip,
        limit=limit
    )
    return tasks

@router.get("/overdue", response_model=List[TaskResponse])
def get_overdue_tasks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get all overdue tasks"""
    service = TaskService(db)
    tasks = service.get_overdue_tasks(current_user.id)
    return tasks

@router.get("/today", response_model=List[TaskResponse])
def get_today_tasks(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get tasks due today"""
    service = TaskService(db)
    tasks = service.get_today_tasks(current_user.id)
    return tasks

@router.get("/stats")
def get_task_statistics(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get task statistics for current user"""
    service = TaskService(db)
    stats = service.get_task_stats(current_user.id)
    return stats

@router.get("/{task_id}", response_model=TaskResponse)
def get_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get a specific task by ID"""
    service = TaskService(db)
    task = service.get_task_by_id(current_user.id, task_id)
    return task

@router.put("/{task_id}", response_model=TaskResponse)
def update_task(
    task_id: int,
    task_update: TaskUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update a task"""
    service = TaskService(db)
    task = service.update_task(current_user.id, task_id, task_update)
    if task_update.status == 'completed':
        from app.services.gamification_service import GamificationService
        gamification_service = GamificationService(db)
        
        # Update daily completion streak
        streak_result = gamification_service.update_streak(current_user.id, 'daily_completion')
        print(f"✅ Streak updated: {streak_result}")
        
        # Check for new achievements
        newly_earned = gamification_service.check_and_award_achievements(current_user.id)
        if newly_earned:
            print(f"🏆 New achievements earned: {[a['name'] for a in newly_earned]}")
    return task

@router.delete("/{task_id}")
def delete_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete a task"""
    service = TaskService(db)
    result = service.delete_task(current_user.id, task_id)
    return result

@router.get("/carryover/stats")
def get_carryover_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get carryover statistics"""
    service = CarryoverService(db)
    stats = service.get_carryover_stats(current_user.id)
    return stats

@router.post("/{task_id}/carryover", response_model=TaskResponse)
def carryover_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Manually trigger carryover for a specific task"""
    service = CarryoverService(db)
    task_service = TaskService(db)
    
    # Get the task
    task = task_service.get_task_by_id(current_user.id, task_id)
    
    # Reschedule it
    rescheduled_task = service.smart_reschedule(task)
    
    return rescheduled_task

@router.post("/carryover/bulk")
def bulk_carryover(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Reschedule all overdue tasks"""
    service = CarryoverService(db)
    result = service.bulk_reschedule(current_user.id)
    return result

@router.post("/{task_id}/decompose")
def decompose_task(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Break down a task into subtasks using Gemini AI"""
    task_service = TaskService(db)
    gemini_service = GeminiService()
    
    # Get the task
    task = task_service.get_task_by_id(current_user.id, task_id)
    
    # Get subtasks from Gemini
    subtasks_data = gemini_service.decompose_task(
        task.title, 
        task.description or ""
    )
    
    # Create subtasks in database
    created_subtasks = []
    for subtask_data in subtasks_data:
        # Create subtask using TaskCreate schema
        subtask_create = TaskCreate(
            title=subtask_data['title'],
            priority=subtask_data['priority'],
            description=f"Subtask of: {task.title}"
        )
        
        # Create the subtask
        subtask = task_service.create_task(current_user.id, subtask_create)
        
        # Update subtask metadata
        subtask.parent_task_id = task.id
        subtask.is_subtask = True
        subtask.estimated_duration = subtask_data['estimated_duration']
        
        db.commit()
        db.refresh(subtask)
        created_subtasks.append(subtask)
    
    return {
        "message": f"Created {len(created_subtasks)} subtasks",
        "parent_task_id": task.id,
        "parent_task_title": task.title,
        "subtasks_count": len(created_subtasks),
        "subtasks": [
            {
                "id": st.id,
                "title": st.title,
                "estimated_duration": st.estimated_duration,
                "priority": st.priority
            } for st in created_subtasks
        ]
    }

@router.get("/{task_id}/suggestions")
def get_task_suggestions(
    task_id: int,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI suggestions for completing a task"""
    task_service = TaskService(db)
    gemini_service = GeminiService()
    
    # Get the task
    task = task_service.get_task_by_id(current_user.id, task_id)
    
    # Get suggestions from Gemini
    suggestions = gemini_service.get_task_suggestions(
        task.title,
        task.description or ""
    )
    
    return {
        "task": task,
        "suggestions": suggestions
    }
