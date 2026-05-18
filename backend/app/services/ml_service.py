# app/services/ml_service.py
from sqlalchemy.orm import Session
from typing import List, Dict
from datetime import datetime

from app.ml.priority_classifier import PriorityClassifier
from app.ml.time_estimator import TimeEstimator
from app.ml.sentiment_analyzer import SentimentAnalyzer
from app.models.task import Task

class MLService:
    """Service for ML predictions"""
    
    def __init__(self, db: Session):
        self.db = db
        self.priority_classifier = PriorityClassifier()
        self.time_estimator = TimeEstimator()
        self.sentiment_analyzer = SentimentAnalyzer()
    
    def predict_priority(self, task_data: Dict) -> str:
        """Predict task priority"""
        return self.priority_classifier.predict(task_data)
    
    def estimate_duration(self, task_data: Dict) -> int:
        """Estimate task duration in minutes"""
        return self.time_estimator.predict(task_data)
    
    def analyze_sentiment(self, message: str) -> Dict:
        """Analyze message sentiment"""
        return self.sentiment_analyzer.analyze(message)
    
    def train_models(self, user_id: int) -> Dict:
        """Train models on user's task data"""
        # Get user's tasks
        tasks = self.db.query(Task).filter(Task.user_id == user_id).all()
        
        if len(tasks) < 10:
            return {
                'success': False,
                'message': 'Need at least 10 tasks to train models',
                'task_count': len(tasks)
            }
        
        # Prepare training data
        training_data = []
        for task in tasks:
            task_dict = {
                'title': task.title,
                'description': task.description,
                'priority': task.priority,
                'deadline': task.deadline,
                'carryover_count': task.carryover_count,
                'is_subtask': task.is_subtask,
                'category': task.category,
                'actual_duration': task.actual_duration
            }
            training_data.append(task_dict)
        
        # Train models
        priority_trained = self.priority_classifier.train(training_data)
        time_trained = self.time_estimator.train(training_data)
        
        return {
            'success': True,
            'priority_model': 'trained' if priority_trained else 'insufficient_data',
            'time_model': 'trained' if time_trained else 'insufficient_data',
            'training_samples': len(training_data)
        }
    
    def get_smart_suggestions(self, user_id: int) -> Dict:
        """Get AI-powered suggestions for user"""
        tasks = self.db.query(Task).filter(
            Task.user_id == user_id,
            Task.status == 'pending'
        ).all()
        
        suggestions = []
        debug_info = []
        
        print(f"\n{'='*60}")
        print(f"Analyzing {len(tasks)} tasks for user {user_id}")
        print(f"{'='*60}")
        
        # Analyze each task
        for task in tasks[:10]:  # Top 10 tasks
            # IMPORTANT: Don't include current priority in prediction input
            task_dict = {
                'title': task.title,
                'description': task.description,
                # DO NOT include 'priority': task.priority here
                'deadline': task.deadline,
                'carryover_count': task.carryover_count
            }
            
            # Get predictions (classifier makes independent decision)
            predicted_priority = self.predict_priority(task_dict)
            estimated_time = self.estimate_duration(task_dict)
            
            current_priority = task.priority
            is_match = current_priority == predicted_priority
            
            print(f"\n{'='*60}")
            print(f"Task ID: {task.id}")
            print(f"Title: {task.title}")
            print(f"Current Priority: {current_priority}")
            print(f"Predicted Priority: {predicted_priority}")
            print(f"Match: {'✓ YES' if is_match else '✗ NO - MISMATCH DETECTED!'}")
            print(f"{'='*60}")

            reason = self._get_suggestion_reason(task_dict, predicted_priority)
            
            debug_info.append({
                'task_id': task.id,
                'title': task.title,
                'current_priority': current_priority,
                'predicted_priority': predicted_priority,
                'match': is_match,
                'reason': reason,
                'deadline': str(task.deadline) if task.deadline else None,
                'carryover_count': task.carryover_count
            })
            
            # Generate suggestion if different
            if predicted_priority != current_priority:
                suggestions.append({
                    'task_id': task.id,
                    'task_title': task.title,
                    'current_priority': current_priority,
                    'suggestion': f'Consider changing priority from {current_priority} to {predicted_priority}',
                    'predicted_priority': predicted_priority,
                    'estimated_duration_minutes': estimated_time,
                    'estimated_duration_hours': round(estimated_time / 60, 1),
                    'reason': reason
                })
        
        print(f"\n{'='*60}")
        print(f"Summary: Generated {len(suggestions)} suggestions out of {len(tasks)} tasks")
        print(f"{'='*60}\n")
        
        return {
            'task_count': len(tasks),
            'analyzed_tasks': len(tasks[:10]),
            'suggestions': suggestions,
            'debug': debug_info
        }
    
    def _get_suggestion_reason(self, task_data: Dict, predicted: str) -> str:
        """Explain why priority was predicted"""
        reasons = []
        
        # Check deadline
        if task_data.get('deadline'):
            deadline = task_data['deadline']
            try:
                # Handle both datetime and string
                if isinstance(deadline, str):
                    deadline_str = deadline.replace('Z', '').replace('+00:00', '')
                    deadline_dt = datetime.fromisoformat(deadline_str)
                else:
                    deadline_dt = deadline
                
                # Make timezone-naive
                if hasattr(deadline_dt, 'tzinfo') and deadline_dt.tzinfo:
                    deadline_dt = deadline_dt.replace(tzinfo=None)
                
                now = datetime.now()
                days = (deadline_dt - now).days
                
                if days < 0:
                    reasons.append("overdue")
                elif days <= 1:
                    reasons.append("deadline within 1 day")
                elif days <= 3:
                    reasons.append("deadline within 3 days")
                elif days > 30:
                    reasons.append("deadline far in future")
            except Exception as e:
                print(f"Error calculating deadline reason: {e}")
        
        # Check title for urgent keywords
        title = task_data.get('title', '').lower()
        description = task_data.get('description', '').lower() if task_data.get('description') else ''
        
        urgent_keywords = ['urgent', 'critical', 'emergency', 'asap', 'bug', 'fix', 'production']
        found_urgent = [kw for kw in urgent_keywords if kw in title or kw in description]
        if found_urgent:
            reasons.append(f"contains urgent keywords: {', '.join(found_urgent[:3])}")
        
        # Check for low priority keywords
        low_keywords = ['maybe', 'someday', 'eventually', 'research', 'explore', 'no rush']
        found_low = [kw for kw in low_keywords if kw in title or kw in description]
        if found_low:
            reasons.append(f"contains low-priority keywords: {', '.join(found_low[:3])}")
        
        # Check carryover
        if task_data.get('carryover_count', 0) > 0:
            reasons.append(f"carried over {task_data['carryover_count']} times")
        
        return "; ".join(reasons) if reasons else "based on ML analysis"