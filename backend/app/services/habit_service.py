from sqlalchemy.orm import Session
from datetime import datetime, timedelta, time
from typing import Dict, List
import statistics
from collections import defaultdict

from app.models.task import Task

class HabitLearningService:
    def __init__(self, db: Session):
        self.db = db
    
    def learn_user_habits(self, user_id: int) -> Dict:
        """Learn and analyze user habits from task completion patterns"""
        tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.created_at >= datetime.utcnow() - timedelta(days=90)
        ).all()
        
        if len(tasks) < 20:
            return {
                'message': 'Need at least 20 tasks for habit learning',
                'task_count': len(tasks)
            }
        
        habits = {}
        
        # Learn optimal working hours
        habits['optimal_hours'] = self._learn_optimal_hours(tasks)
        
        # Learn task duration patterns
        habits['duration_patterns'] = self._learn_duration_patterns(tasks)
        
        # Learn priority patterns
        habits['priority_patterns'] = self._learn_priority_patterns(tasks)
        
        # Learn procrastination patterns
        habits['procrastination_analysis'] = self._analyze_procrastination(tasks)
        
        # Learn category preferences
        habits['category_preferences'] = self._learn_category_preferences(tasks)
        
        # Generate personalized suggestions
        habits['personalized_suggestions'] = self._generate_habit_suggestions(habits)
        
        return habits
    
    def _learn_optimal_hours(self, tasks: List[Task]) -> Dict:
        """Learn when user is most productive"""
        completed_tasks = [t for t in tasks if t.completed_at and t.status == 'completed']
        
        if not completed_tasks:
            return {'message': 'No completed tasks to analyze'}
        
        # Analyze by hour
        hourly_performance = defaultdict(lambda: {'count': 0, 'avg_duration': []})
        
        for task in completed_tasks:
            hour = task.completed_at.hour
            hourly_performance[hour]['count'] += 1
            
            if task.actual_duration:
                hourly_performance[hour]['avg_duration'].append(task.actual_duration)
        
        # Find peak hours
        peak_hours = sorted(
            [(hour, data['count']) for hour, data in hourly_performance.items()],
            key=lambda x: x[1],
            reverse=True
        )[:3]
        
        # Categorize into time blocks
        morning = sum(data['count'] for hour, data in hourly_performance.items() if 6 <= hour < 12)
        afternoon = sum(data['count'] for hour, data in hourly_performance.items() if 12 <= hour < 18)
        evening = sum(data['count'] for hour, data in hourly_performance.items() if 18 <= hour < 24)
        
        best_time_block = max([
            ('morning', morning),
            ('afternoon', afternoon),
            ('evening', evening)
        ], key=lambda x: x[1])[0]
        
        return {
            'peak_hours': [f'{hour:02d}:00' for hour, _ in peak_hours],
            'best_time_block': best_time_block,
            'morning_productivity': morning,
            'afternoon_productivity': afternoon,
            'evening_productivity': evening
        }
    
    def _learn_duration_patterns(self, tasks: List[Task]) -> Dict:
        """Analyze task duration patterns"""
        completed_with_duration = [
            t for t in tasks 
            if t.status == 'completed' and t.estimated_duration and t.actual_duration
        ]
        
        if len(completed_with_duration) < 5:
            return {'message': 'Not enough duration data'}
        
        # Compare estimated vs actual
        differences = [
            ((t.actual_duration - t.estimated_duration) / t.estimated_duration * 100)
            for t in completed_with_duration
        ]
        
        avg_difference = statistics.mean(differences)
        
        # Analyze accuracy
        if abs(avg_difference) < 10:
            accuracy = 'excellent'
        elif abs(avg_difference) < 25:
            accuracy = 'good'
        else:
            accuracy = 'needs_improvement'
        
        # Tendency
        if avg_difference > 10:
            tendency = 'underestimates'
        elif avg_difference < -10:
            tendency = 'overestimates'
        else:
            tendency = 'accurate'
        
        return {
            'estimation_accuracy': accuracy,
            'tendency': tendency,
            'avg_estimation_error_percent': round(avg_difference, 2),
            'suggestion': self._get_duration_suggestion(tendency, avg_difference)
        }
    
    def _learn_priority_patterns(self, tasks: List[Task]) -> Dict:
        """Analyze how user handles different priorities"""
        priority_stats = {}
        
        for priority in ['low', 'medium', 'high', 'critical']:
            priority_tasks = [t for t in tasks if t.priority == priority]
            
            if not priority_tasks:
                continue
            
            completed = len([t for t in priority_tasks if t.status == 'completed'])
            completion_rate = (completed / len(priority_tasks) * 100) if priority_tasks else 0
            
            avg_carryover = statistics.mean([t.carryover_count for t in priority_tasks])
            
            priority_stats[priority] = {
                'total': len(priority_tasks),
                'completed': completed,
                'completion_rate': round(completion_rate, 2),
                'avg_carryover': round(avg_carryover, 2)
            }
        
        # Identify strengths and weaknesses
        best_priority = max(
            priority_stats.items(),
            key=lambda x: x[1]['completion_rate']
        )[0] if priority_stats else None
        
        return {
            'by_priority': priority_stats,
            'best_handled_priority': best_priority
        }
    
    def _analyze_procrastination(self, tasks: List[Task]) -> Dict:
        """Analyze procrastination patterns"""
        tasks_with_deadline = [t for t in tasks if t.deadline]
        
        if not tasks_with_deadline:
            return {'message': 'No deadline data available'}
        
        # Check how many tasks completed near deadline
        last_minute_completions = 0
        early_completions = 0
        late_completions = 0
        
        for task in tasks_with_deadline:
            if task.completed_at and task.deadline:
                hours_before_deadline = (task.deadline - task.completed_at).total_seconds() / 3600
                
                if hours_before_deadline < 24:
                    last_minute_completions += 1
                elif hours_before_deadline > 72:
                    early_completions += 1
            elif task.deadline < datetime.utcnow() and task.status != 'completed':
                late_completions += 1
        
        total = len(tasks_with_deadline)
        last_minute_rate = (last_minute_completions / total * 100) if total else 0
        
        # Determine procrastination level
        if last_minute_rate > 50:
            level = 'high'
        elif last_minute_rate > 25:
            level = 'moderate'
        else:
            level = 'low'
        
        return {
            'procrastination_level': level,
            'last_minute_completion_rate': round(last_minute_rate, 2),
            'early_completions': early_completions,
            'last_minute_completions': last_minute_completions,
            'late_completions': late_completions,
            'suggestion': self._get_procrastination_suggestion(level)
        }
    
    def _learn_category_preferences(self, tasks: List[Task]) -> Dict:
        """Learn which categories user excels at"""
        category_stats = defaultdict(lambda: {'total': 0, 'completed': 0})
        
        for task in tasks:
            if task.category:
                category_stats[task.category]['total'] += 1
                if task.status == 'completed':
                    category_stats[task.category]['completed'] += 1
        
        category_performance = {}
        for category, stats in category_stats.items():
            completion_rate = (stats['completed'] / stats['total'] * 100) if stats['total'] else 0
            category_performance[category] = {
                'total': stats['total'],
                'completed': stats['completed'],
                'completion_rate': round(completion_rate, 2)
            }
        
        # Find best and worst categories
        if category_performance:
            best_category = max(category_performance.items(), key=lambda x: x[1]['completion_rate'])
            worst_category = min(category_performance.items(), key=lambda x: x[1]['completion_rate'])
            
            return {
                'by_category': category_performance,
                'strongest_category': best_category[0],
                'weakest_category': worst_category[0]
            }
        
        return {'message': 'No category data available'}
    
    def _generate_habit_suggestions(self, habits: Dict) -> List[str]:
        """Generate personalized suggestions based on learned habits"""
        suggestions = []
        
        # Optimal hours suggestion
        if 'optimal_hours' in habits and 'best_time_block' in habits['optimal_hours']:
            time_block = habits['optimal_hours']['best_time_block']
            suggestions.append(
                f"📅 Schedule important tasks during your {time_block} - your most productive time"
            )
        
        # Duration estimation suggestion
        if 'duration_patterns' in habits and 'tendency' in habits['duration_patterns']:
            if habits['duration_patterns']['tendency'] == 'underestimates':
                suggestions.append(
                    "⏰ You tend to underestimate task duration. Add 20-30% buffer time"
                )
            elif habits['duration_patterns']['tendency'] == 'overestimates':
                suggestions.append(
                    "⚡ You tend to overestimate tasks. Try to be more optimistic with estimates"
                )
        
        # Procrastination suggestion
        if 'procrastination_analysis' in habits:
            level = habits['procrastination_analysis'].get('procrastination_level')
            if level in ['high', 'moderate']:
                suggestions.append(
                    "🎯 Set artificial deadlines 24-48 hours before actual deadlines"
                )
        
        # Category-based suggestion
        if 'category_preferences' in habits and 'strongest_category' in habits['category_preferences']:
            strongest = habits['category_preferences']['strongest_category']
            weakest = habits['category_preferences'].get('weakest_category')
            
            if strongest and weakest:
                suggestions.append(
                    f"💪 You excel at {strongest} tasks. Consider tackling {weakest} tasks during your peak hours"
                )
        
        return suggestions
    
    def _get_duration_suggestion(self, tendency: str, error_percent: float) -> str:
        """Get suggestion based on duration estimation tendency"""
        if tendency == 'underestimates':
            return f"Add {abs(error_percent):.0f}% buffer to your time estimates"
        elif tendency == 'overestimates':
            return f"You can reduce estimates by {abs(error_percent):.0f}%"
        return "Your time estimates are accurate! Keep it up"
    
    def _get_procrastination_suggestion(self, level: str) -> str:
        """Get suggestion based on procrastination level"""
        suggestions = {
            'high': "Try the 2-minute rule: if a task takes less than 2 minutes, do it immediately",
            'moderate': "Break large tasks into smaller chunks to reduce procrastination",
            'low': "Great job staying ahead of deadlines! Keep up the good work"
        }
        return suggestions.get(level, "Keep tracking your tasks")