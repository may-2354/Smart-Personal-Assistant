from sqlalchemy.orm import Session
from datetime import datetime, timedelta, time as dt_time
from typing import List, Dict, Optional
import random

from app.models.task import Task
from app.models.user import User

class SchedulingService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_available_slots(
        self, 
        user_id: int, 
        days_ahead: int = 7,
        slot_duration: int = 60  # minutes
    ) -> List[Dict]:
        """Get available time slots for scheduling"""
        user = self.db.query(User).filter(User.id == user_id).first()
        
        # Get user's work hours (default 9-5)
        work_start = dt_time(9, 0)
        work_end = dt_time(17, 0)
        
        available_slots = []
        current_date = datetime.now().date()
        
        for day in range(days_ahead):
            date = current_date + timedelta(days=day)
            
            # Skip weekends (optional)
            if date.weekday() >= 5:  # Saturday=5, Sunday=6
                continue
            
            # Get existing tasks for this day
            existing_tasks = self.db.query(Task).filter(
                Task.user_id == user_id,
                Task.scheduled_start >= datetime.combine(date, datetime.min.time()),
                Task.scheduled_start < datetime.combine(date, datetime.max.time())
            ).all()
            
            # Create time slots
            current_time = datetime.combine(date, work_start)
            end_time = datetime.combine(date, work_end)
            
            while current_time + timedelta(minutes=slot_duration) <= end_time:
                slot_end = current_time + timedelta(minutes=slot_duration)
                
                # Check if slot conflicts with existing tasks
                is_available = True
                for task in existing_tasks:
                    if task.scheduled_start and task.scheduled_end:
                        if not (slot_end <= task.scheduled_start or 
                               current_time >= task.scheduled_end):
                            is_available = False
                            break
                
                if is_available:
                    available_slots.append({
                        'start': current_time,
                        'end': slot_end,
                        'date': date,
                        'duration': slot_duration
                    })
                
                current_time += timedelta(minutes=slot_duration)
        
        return available_slots
    
    def find_optimal_slot(
        self, 
        task: Task, 
        available_slots: List[Dict]
    ) -> Optional[Dict]:
        """Find the optimal time slot for a task based on various factors"""
        if not available_slots:
            return None
        
        # Score each slot
        scored_slots = []
        
        for slot in available_slots:
            score = 0
            
            # 1. Prefer earlier slots for high priority tasks
            if task.priority in ['high', 'critical']:
                days_from_now = (slot['date'] - datetime.now().date()).days
                score += (7 - days_from_now) * 10  # Earlier is better
            
            # 2. Prefer morning slots for important tasks
            if task.is_important:
                hour = slot['start'].hour
                if 9 <= hour <= 12:  # Morning
                    score += 20
            
            # 3. Consider deadline proximity
            if task.deadline:
                days_until_deadline = (task.deadline.date() - slot['date']).days
                if days_until_deadline <= 2:
                    score += 30  # Very urgent
                elif days_until_deadline <= 5:
                    score += 15
            
            # 4. Avoid end of day for complex tasks
            if slot['start'].hour >= 16:  # After 4 PM
                score -= 5
            
            scored_slots.append({
                'slot': slot,
                'score': score
            })
        
        # Return slot with highest score
        best_slot = max(scored_slots, key=lambda x: x['score'])
        return best_slot['slot']
    
    def schedule_task(
        self, 
        task: Task, 
        start_time: datetime, 
        duration: int = 60
    ) -> Task:
        """Schedule a task at a specific time"""
        task.scheduled_start = start_time
        task.scheduled_end = start_time + timedelta(minutes=duration)
        self.db.commit()
        return task
    
    def check_conflicts(self, user_id: int, task: Task) -> List[Task]:
        """Check if a task conflicts with other scheduled tasks"""
        if not task.scheduled_start or not task.scheduled_end:
            return []
        
        conflicting_tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.id != task.id,
            Task.scheduled_start.isnot(None),
            Task.scheduled_end.isnot(None),
            ~((Task.scheduled_end <= task.scheduled_start) | 
              (Task.scheduled_start >= task.scheduled_end))
        ).all()
        
        return conflicting_tasks