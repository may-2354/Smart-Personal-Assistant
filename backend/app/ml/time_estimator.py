import numpy as np
from sklearn.linear_model import LinearRegression
import joblib
import os
from typing import Dict, Optional

class TimeEstimator:
    """ML model to estimate task duration"""
    
    def __init__(self):
        self.model = None
        self.model_path = 'app/ml/models/time_estimator.pkl'
        
        if os.path.exists(self.model_path):
            self.load_model()
    
    def extract_features(self, task_data: Dict) -> np.array:
        """Extract features for time estimation"""
        features = []
        
        # Feature 1: Title length
        title = task_data.get('title', '')
        features.append(len(title))
        
        # Feature 2: Word count
        features.append(len(title.split()))
        
        # Feature 3: Has description (more complex if yes)
        features.append(1 if task_data.get('description') else 0)
        
        # Feature 4: Description length
        desc = task_data.get('description', '')
        features.append(len(desc) if desc else 0)
        
        # Feature 5: Priority level (higher priority might need more time)
        priority_map = {'low': 1, 'medium': 2, 'high': 3, 'critical': 4}
        features.append(priority_map.get(task_data.get('priority', 'medium'), 2))
        
        # Feature 6: Is subtask (subtasks usually smaller)
        features.append(1 if task_data.get('is_subtask') else 0)
        
        # Feature 7: Category complexity (some categories take longer)
        category = task_data.get('category', '')
        complex_categories = ['project', 'research', 'study', 'development']
        features.append(1 if category.lower() in complex_categories else 0)
        
        return np.array(features).reshape(1, -1)
    
    def train(self, training_data: list):
        """Train time estimation model"""
        if len(training_data) < 10:
            print("Not enough data to train (need at least 10 completed tasks)")
            return False
        
        X = []
        y = []
        
        for task in training_data:
            if task.get('actual_duration') and task['actual_duration'] > 0:
                features = self.extract_features(task)
                X.append(features.flatten())
                y.append(task['actual_duration'])
        
        if len(X) < 10:
            print("Not enough tasks with actual duration")
            return False
        
        X = np.array(X)
        y = np.array(y)
        
        # Train Linear Regression
        self.model = LinearRegression()
        self.model.fit(X, y)
        
        # Save model
        self.save_model()
        
        return True
    
    def predict(self, task_data: Dict) -> int:
        """Predict task duration in minutes"""
        if self.model is None:
            return self._rule_based_estimation(task_data)
        
        features = self.extract_features(task_data)
        prediction = self.model.predict(features)[0]
        
        # Ensure reasonable bounds (15 min to 480 min / 8 hours)
        prediction = max(15, min(480, int(prediction)))
        
        return prediction
    
    def _rule_based_estimation(self, task_data: Dict) -> int:
        """Fallback rule-based estimation"""
        base_time = 30  # Default 30 minutes
        
        # Adjust by priority
        priority = task_data.get('priority', 'medium')
        priority_multiplier = {
            'low': 0.5,
            'medium': 1.0,
            'high': 1.5,
            'critical': 2.0
        }
        base_time *= priority_multiplier.get(priority, 1.0)
        
        # Adjust by complexity (has description)
        if task_data.get('description'):
            desc_length = len(task_data['description'])
            if desc_length > 100:
                base_time *= 1.5
        
        # Adjust if it's a subtask (usually smaller)
        if task_data.get('is_subtask'):
            base_time *= 0.6
        
        # Adjust by category
        category = task_data.get('category', '').lower()
        if category in ['project', 'research', 'development']:
            base_time *= 2.0
        elif category in ['meeting', 'call']:
            base_time *= 0.8
        
        return max(15, min(480, int(base_time)))
    
    def save_model(self):
        """Save model to disk"""
        os.makedirs(os.path.dirname(self.model_path), exist_ok=True)
        joblib.dump(self.model, self.model_path)
    
    def load_model(self):
        """Load model from disk"""
        try:
            self.model = joblib.load(self.model_path)
        except Exception as e:
            print(f"Error loading model: {e}")
            self.model = None