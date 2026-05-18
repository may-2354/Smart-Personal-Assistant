from sqlalchemy.orm import Session
from sqlalchemy import func, and_, extract
from datetime import datetime, timedelta
from typing import Dict, List
import statistics

from app.models.task import Task
from app.models.user import User

class AnalyticsService:
    def __init__(self, db: Session):
        self.db = db
    
    def get_detailed_productivity_metrics(self, user_id: int, days: int = 30) -> Dict:
        """Get comprehensive productivity metrics"""
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)
        
        # Get all tasks in period
        tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.created_at >= start_date
        ).all()
        
        if not tasks:
            return self._empty_metrics()
        
        # Basic counts
        total_tasks = len(tasks)
        completed_tasks = len([t for t in tasks if t.status == 'completed'])
        pending_tasks = len([t for t in tasks if t.status == 'pending'])
        in_progress_tasks = len([t for t in tasks if t.status == 'in_progress'])
        
        # Completion rate
        completion_rate = (completed_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        # Average completion time
        completed_with_time = [
            (t.completed_at - t.created_at).total_seconds() / 3600
            for t in tasks 
            if t.status == 'completed' and t.completed_at
        ]
        avg_completion_time = statistics.mean(completed_with_time) if completed_with_time else 0
        
        # Tasks by priority
        priority_breakdown = {
            'critical': len([t for t in tasks if t.priority == 'critical']),
            'high': len([t for t in tasks if t.priority == 'high']),
            'medium': len([t for t in tasks if t.priority == 'medium']),
            'low': len([t for t in tasks if t.priority == 'low'])
        }
        
        # Tasks by category
        categories = {}
        for task in tasks:
            if task.category:
                categories[task.category] = categories.get(task.category, 0) + 1
        
        # Carryover analysis
        tasks_with_carryover = len([t for t in tasks if t.carryover_count > 0])
        total_carryovers = sum(t.carryover_count for t in tasks)
        avg_carryovers = total_carryovers / len(tasks) if tasks else 0
        
        # Time-based analysis
        daily_completion = self._get_daily_completion_trend(user_id, days)
        hourly_productivity = self._get_hourly_productivity(tasks)
        
        # Overdue rate
        overdue_tasks = len([
            t for t in tasks 
            if t.deadline and t.deadline < datetime.utcnow() and t.status != 'completed'
        ])
        overdue_rate = (overdue_tasks / total_tasks * 100) if total_tasks > 0 else 0
        
        return {
            'period_days': days,
            'total_tasks': total_tasks,
            'completed': completed_tasks,
            'pending': pending_tasks,
            'in_progress': in_progress_tasks,
            'completion_rate': round(completion_rate, 2),
            'avg_completion_time_hours': round(avg_completion_time, 2),
            'priority_breakdown': priority_breakdown,
            'top_categories': dict(sorted(categories.items(), key=lambda x: x[1], reverse=True)[:5]),
            'carryover_stats': {
                'tasks_with_carryover': tasks_with_carryover,
                'total_carryovers': total_carryovers,
                'avg_carryovers_per_task': round(avg_carryovers, 2)
            },
            'overdue_tasks': overdue_tasks,
            'overdue_rate': round(overdue_rate, 2),
            'daily_completion_trend': daily_completion,
            'hourly_productivity': hourly_productivity
        }
    
    def _get_daily_completion_trend(self, user_id: int, days: int) -> List[Dict]:
        """Get daily task completion trend"""
        trend = []
        for i in range(days):
            date = datetime.utcnow().date() - timedelta(days=i)
            
            completed = self.db.query(Task).filter(
                Task.user_id == user_id,
                func.date(Task.completed_at) == date,
                Task.status == 'completed'
            ).count()
            
            created = self.db.query(Task).filter(
                Task.user_id == user_id,
                func.date(Task.created_at) == date
            ).count()
            
            trend.append({
                'date': date.isoformat(),
                'completed': completed,
                'created': created
            })
        
        return list(reversed(trend))
    
    def _get_hourly_productivity(self, tasks: List[Task]) -> Dict:
        """Analyze productivity by hour of day"""
        hourly_counts = {hour: 0 for hour in range(24)}
        
        for task in tasks:
            if task.completed_at:
                hour = task.completed_at.hour
                hourly_counts[hour] += 1
        
        # Find peak hours
        if any(hourly_counts.values()):
            peak_hour = max(hourly_counts.items(), key=lambda x: x[1])
            return {
                'by_hour': hourly_counts,
                'peak_hour': peak_hour[0],
                'peak_count': peak_hour[1]
            }
        
        return {'by_hour': hourly_counts, 'peak_hour': None, 'peak_count': 0}
    
    def detect_burnout(self, user_id: int) -> Dict:
        """Detect potential burnout based on various factors"""
        recent_tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.created_at >= datetime.utcnow() - timedelta(days=14)
        ).all()
        
        if not recent_tasks:
            return {
                'risk_level': 'low',
                'risk_score': 0,
                'indicators': [],
                'recommendations': ['Start creating tasks to track productivity']
            }
        
        risk_score = 0
        indicators = []
        
        # Factor 1: High carryover rate (>40%)
        carryover_rate = len([t for t in recent_tasks if t.carryover_count > 0]) / len(recent_tasks)
        if carryover_rate > 0.4:
            risk_score += 30
            indicators.append(f'High carryover rate: {carryover_rate*100:.1f}%')
        
        # Factor 2: Low completion rate (<50%)
        completed = len([t for t in recent_tasks if t.status == 'completed'])
        completion_rate = completed / len(recent_tasks)
        if completion_rate < 0.5:
            risk_score += 25
            indicators.append(f'Low completion rate: {completion_rate*100:.1f}%')
        
        # Factor 3: Too many tasks (>20 in 2 weeks)
        if len(recent_tasks) > 20:
            risk_score += 20
            indicators.append(f'High task volume: {len(recent_tasks)} tasks in 2 weeks')
        
        # Factor 4: Multiple high priority tasks incomplete
        high_priority_incomplete = len([
            t for t in recent_tasks 
            if t.priority in ['high', 'critical'] and t.status != 'completed'
        ])
        if high_priority_incomplete > 5:
            risk_score += 15
            indicators.append(f'{high_priority_incomplete} high-priority tasks incomplete')
        
        # Factor 5: Many overdue tasks
        overdue = len([
            t for t in recent_tasks 
            if t.deadline and t.deadline < datetime.utcnow() and t.status != 'completed'
        ])
        if overdue > 3:
            risk_score += 10
            indicators.append(f'{overdue} overdue tasks')
        
        # Determine risk level
        if risk_score >= 70:
            risk_level = 'high'
        elif risk_score >= 40:
            risk_level = 'medium'
        else:
            risk_level = 'low'
        
        # Generate recommendations
        recommendations = self._generate_burnout_recommendations(risk_level, indicators)
        
        return {
            'risk_level': risk_level,
            'risk_score': risk_score,
            'indicators': indicators,
            'recommendations': recommendations
        }
    
    def _generate_burnout_recommendations(self, risk_level: str, indicators: List[str]) -> List[str]:
        """Generate personalized recommendations"""
        recommendations = []
        
        if risk_level == 'high':
            recommendations.append('🚨 Take immediate action to reduce workload')
            recommendations.append('Consider delegating or postponing non-critical tasks')
            recommendations.append('Schedule breaks and personal time')
        elif risk_level == 'medium':
            recommendations.append('⚠️ Monitor your workload closely')
            recommendations.append('Focus on completing existing tasks before adding new ones')
        
        if any('carryover' in ind.lower() for ind in indicators):
            recommendations.append('Review and reschedule carried-over tasks')
        
        if any('completion rate' in ind.lower() for ind in indicators):
            recommendations.append('Break large tasks into smaller, manageable subtasks')
        
        if any('task volume' in ind.lower() for ind in indicators):
            recommendations.append('Reduce daily task creation by 30%')
        
        return recommendations
    
    def recognize_patterns(self, user_id: int) -> Dict:
        """Recognize productivity patterns"""
        tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.created_at >= datetime.utcnow() - timedelta(days=60)
        ).all()
        
        if len(tasks) < 10:
            return {'message': 'Not enough data for pattern recognition'}
        
        patterns = {}
        
        # Pattern 1: Best completion days
        day_performance = {i: {'completed': 0, 'created': 0} for i in range(7)}
        for task in tasks:
            day = task.created_at.weekday()
            day_performance[day]['created'] += 1
            if task.status == 'completed':
                day_performance[day]['completed'] += 1
        
        best_days = sorted(
            [(day, stats['completed']) for day, stats in day_performance.items()],
            key=lambda x: x[1],
            reverse=True
        )[:3]
        
        day_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        patterns['best_completion_days'] = [day_names[day] for day, _ in best_days]
        
        # Pattern 2: Most productive time
        completed_tasks = [t for t in tasks if t.completed_at]
        if completed_tasks:
            morning_completions = len([t for t in completed_tasks if 6 <= t.completed_at.hour < 12])
            afternoon_completions = len([t for t in completed_tasks if 12 <= t.completed_at.hour < 18])
            evening_completions = len([t for t in completed_tasks if 18 <= t.completed_at.hour < 24])
            
            time_slots = {
                'morning': morning_completions,
                'afternoon': afternoon_completions,
                'evening': evening_completions
            }
            
            patterns['most_productive_time'] = max(time_slots.items(), key=lambda x: x[1])[0]
        
        # Pattern 3: Preferred task categories
        category_counts = {}
        for task in tasks:
            if task.category:
                category_counts[task.category] = category_counts.get(task.category, 0) + 1
        
        if category_counts:
            patterns['top_categories'] = sorted(
                category_counts.items(),
                key=lambda x: x[1],
                reverse=True
            )[:3]
        
        # Pattern 4: Task complexity preference
        avg_estimated_duration = statistics.mean([
            t.estimated_duration for t in tasks if t.estimated_duration
        ]) if any(t.estimated_duration for t in tasks) else None
        
        if avg_estimated_duration:
            if avg_estimated_duration < 30:
                patterns['task_preference'] = 'short_tasks'
            elif avg_estimated_duration < 120:
                patterns['task_preference'] = 'medium_tasks'
            else:
                patterns['task_preference'] = 'long_tasks'
        
        return patterns
    
    def _empty_metrics(self) -> Dict:
        """Return empty metrics structure"""
        return {
            'total_tasks': 0,
            'completed': 0,
            'pending': 0,
            'completion_rate': 0,
            'message': 'No tasks found in this period'
        }