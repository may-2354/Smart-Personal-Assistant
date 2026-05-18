# app/ml/priority_classifier.py
import re
from typing import Dict
from datetime import datetime, timedelta

class PriorityClassifier:
    """Rule-based priority classifier"""
    
    def __init__(self):
        self.model = None
    
    def predict(self, task_data: Dict) -> str:
        """
        Predict task priority based on rules.
        IMPORTANT: This method IGNORES task_data['priority'] and makes independent prediction
        """
        
        # Extract features (DO NOT use task_data['priority'])
        title = task_data.get('title', '').lower()
        description = task_data.get('description', '').lower() if task_data.get('description') else ''
        deadline = task_data.get('deadline')
        carryover_count = task_data.get('carryover_count', 0)
        
        # Initialize score
        urgency_score = 0
        
        print(f"\n--- Analyzing Task ---")
        print(f"Title: {title}")
        print(f"Description: {description[:100]}...")
        print(f"Deadline: {deadline}")
        
        # 1. Check for HIGH PRIORITY keywords in title/description
        high_priority_keywords = [
            'urgent', 'critical', 'emergency', 'asap', 'immediately', 
            'important', 'priority', 'deadline', 'crucial', 'vital',
            'bug', 'fix', 'issue', 'problem', 'broken', 'crash',
            'production', 'live', 'customer', 'client'
        ]
        
        keyword_matches = []
        for keyword in high_priority_keywords:
            if keyword in title or keyword in description:
                urgency_score += 2
                keyword_matches.append(keyword)
        
        if keyword_matches:
            print(f"Found urgent keywords: {keyword_matches} (+{len(keyword_matches)*2} points)")
        
        # 2. Check deadline urgency
        if deadline:
            try:
                # Handle both datetime and string
                if isinstance(deadline, str):
                    # Remove timezone info for comparison
                    deadline_str = deadline.replace('Z', '').replace('+00:00', '')
                    deadline_dt = datetime.fromisoformat(deadline_str)
                else:
                    deadline_dt = deadline
                
                # Make deadline timezone-naive for comparison
                if deadline_dt.tzinfo:
                    deadline_dt = deadline_dt.replace(tzinfo=None)
                
                now = datetime.now()
                days_until_deadline = (deadline_dt - now).total_seconds() / 86400
                
                print(f"Days until deadline: {days_until_deadline:.2f}")
                
                if days_until_deadline < 0:
                    urgency_score += 5  # Overdue
                    print("Overdue! (+5 points)")
                elif days_until_deadline <= 1:
                    urgency_score += 4  # Due today or tomorrow
                    print("Due within 1 day! (+4 points)")
                elif days_until_deadline <= 3:
                    urgency_score += 3  # Due within 3 days
                    print("Due within 3 days (+3 points)")
                elif days_until_deadline <= 7:
                    urgency_score += 1  # Due within a week
                    print("Due within a week (+1 point)")
                elif days_until_deadline > 30:
                    urgency_score -= 1  # Far in the future
                    print("Deadline far away (-1 point)")
                    
            except Exception as e:
                print(f"Error parsing deadline: {e}")
        
        # 3. Check carryover count
        if carryover_count > 2:
            urgency_score += 3
            print(f"Carried over {carryover_count} times (+3 points)")
        elif carryover_count > 0:
            urgency_score += 1
            print(f"Carried over {carryover_count} times (+1 point)")
        
        # 4. Check for LOW priority keywords
        low_priority_keywords = [
            'maybe', 'someday', 'eventually', 'nice to have', 
            'consider', 'explore', 'research', 'plan', 'think about',
            'when we have time', 'no rush', 'low priority'
        ]
        
        low_keyword_matches = []
        for keyword in low_priority_keywords:
            if keyword in title or keyword in description:
                urgency_score -= 2
                low_keyword_matches.append(keyword)
        
        if low_keyword_matches:
            print(f"Found low-priority keywords: {low_keyword_matches} ({len(low_keyword_matches)*-2} points)")
        
        # 5. Check title length and complexity
        if len(title.split()) > 10:
            urgency_score += 1
            print("Long detailed title (+1 point)")
        
        print(f"Total urgency score: {urgency_score}")
        
        # Determine priority based on score
        if urgency_score >= 5:
            predicted = 'high'
        elif urgency_score >= 2:
            predicted = 'medium'
        else:
            predicted = 'low'
        
        print(f"Predicted priority: {predicted}")
        print("--- End Analysis ---\n")
        
        return predicted
    
    def train(self, training_data):
        """Train the model (placeholder for rule-based system)"""
        if len(training_data) < 5:
            return False
        # For now, we're using rule-based system
        print(f"Training with {len(training_data)} samples")
        return True