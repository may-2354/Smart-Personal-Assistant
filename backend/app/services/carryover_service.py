from sqlalchemy.orm import Session
from datetime import datetime, timedelta
from typing import List, Dict
from apscheduler.schedulers.background import BackgroundScheduler

from app.models.task import Task
from app.services.scheduling_service import SchedulingService

class CarryoverService:
    def __init__(self, db: Session):
        self.db = db
        self.scheduling_service = SchedulingService(db)
    
    def get_overdue_tasks(self, user_id: int) -> List[Task]:
        """Get all incomplete tasks past their deadline"""
        now = datetime.utcnow()
        return self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status.in_(['pending', 'in_progress']),
            Task.deadline < now
        ).all()
    
    def smart_reschedule(self, task: Task) -> Task:
        """Intelligently reschedule a carried-over task"""
        # Get available slots for next 7 days
        available_slots = self.scheduling_service.get_available_slots(
            task.user_id,
            days_ahead=7
        )
        
        if not available_slots:
            # No slots available, push to next week
            task.deadline = datetime.utcnow() + timedelta(days=7)
            task.carryover_count += 1
            task.last_carryover_date = datetime.utcnow()
            task.carryover_reason = "No available slots found"
            self.db.commit()
            return task
        
        # Find optimal slot
        best_slot = self.scheduling_service.find_optimal_slot(task, available_slots)
        
        if best_slot:
            # Update task with new schedule
            task.scheduled_start = best_slot['start']
            task.scheduled_end = best_slot['end']
            task.deadline = best_slot['end']
            
            # Update carryover metadata
            task.carryover_count += 1
            task.last_carryover_date = datetime.utcnow()
            task.carryover_reason = "Auto-rescheduled by system"
            
            # Boost priority based on carryover count
            if task.carryover_count >= 2 and task.priority != 'critical':
                task.priority = 'high'
            if task.carryover_count >= 3:
                task.priority = 'critical'
                task.is_urgent = True
            
            self.db.commit()
        
        return task
    
    def bulk_reschedule(self, user_id: int) -> Dict:
        """Reschedule all overdue tasks for a user"""
        overdue_tasks = self.get_overdue_tasks(user_id)
        
        rescheduled = []
        failed = []
        
        for task in overdue_tasks:
            if task.auto_reschedule_enabled:
                try:
                    rescheduled_task = self.smart_reschedule(task)
                    rescheduled.append(rescheduled_task)
                except Exception as e:
                    failed.append({'task_id': task.id, 'error': str(e)})
            else:
                failed.append({'task_id': task.id, 'error': 'Auto-reschedule disabled'})
        
        return {
            'rescheduled_count': len(rescheduled),
            'failed_count': len(failed),
            'rescheduled_tasks': rescheduled,
            'failed_tasks': failed
        }
    
    def get_carryover_stats(self, user_id: int) -> Dict:
        """Get carryover statistics for a user"""
        tasks = self.db.query(Task).filter(Task.user_id == user_id).all()
        
        total_carryovers = sum(task.carryover_count for task in tasks)
        tasks_with_carryovers = len([t for t in tasks if t.carryover_count > 0])
        avg_carryovers = total_carryovers / len(tasks) if tasks else 0
        
        # Tasks by carryover count
        never_carried = len([t for t in tasks if t.carryover_count == 0])
        carried_once = len([t for t in tasks if t.carryover_count == 1])
        carried_multiple = len([t for t in tasks if t.carryover_count >= 2])
        
        return {
            'total_carryovers': total_carryovers,
            'tasks_with_carryovers': tasks_with_carryovers,
            'average_carryovers_per_task': round(avg_carryovers, 2),
            'never_carried': never_carried,
            'carried_once': carried_once,
            'carried_multiple_times': carried_multiple
        }
    
    def suggest_carryover_action(self, task: Task) -> str:
        """Suggest action for a carried-over task"""
        if task.carryover_count == 0:
            return "Task is on schedule"
        elif task.carryover_count == 1:
            return "First carryover - reschedule to next available slot"
        elif task.carryover_count == 2:
            return "Second carryover - consider breaking into smaller tasks"
        elif task.carryover_count >= 3:
            return "Multiple carryovers detected - review task priority and complexity"
        
        return "Unknown status"