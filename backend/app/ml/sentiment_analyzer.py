from typing import Dict
import re

class SentimentAnalyzer:
    """Analyze sentiment from user messages"""
    
    def __init__(self):
        # Sentiment keywords
        self.stress_keywords = [
            'overwhelmed', 'stressed', 'anxious', 'worried', 'exhausted',
            'tired', 'can\'t handle', 'too much', 'burnout', 'frustrated',
            'impossible', 'difficult', 'hard', 'struggling'
        ]
        
        self.positive_keywords = [
            'great', 'good', 'happy', 'excited', 'productive', 'accomplished',
            'done', 'completed', 'finished', 'successful', 'motivated'
        ]
        
        self.negative_keywords = [
            'bad', 'terrible', 'awful', 'hate', 'dislike', 'failed',
            'missed', 'late', 'behind', 'delayed'
        ]
    
    def analyze(self, text: str) -> Dict:
        """Analyze sentiment of text"""
        text_lower = text.lower()
        
        # Count sentiment indicators
        stress_count = sum(1 for kw in self.stress_keywords if kw in text_lower)
        positive_count = sum(1 for kw in self.positive_keywords if kw in text_lower)
        negative_count = sum(1 for kw in self.negative_keywords if kw in text_lower)
        
        # Determine overall sentiment
        total_score = positive_count - negative_count - (stress_count * 1.5)
        
        if stress_count >= 2:
            sentiment = 'stressed'
            suggestion = 'break'
        elif total_score >= 2:
            sentiment = 'positive'
            suggestion = None
        elif total_score <= -2:
            sentiment = 'negative'
            suggestion = 'support'
        else:
            sentiment = 'neutral'
            suggestion = None
        
        return {
            'sentiment': sentiment,
            'stress_level': min(10, stress_count * 2),  # 0-10 scale
            'positivity': positive_count,
            'negativity': negative_count,
            'suggestion': suggestion,
            'needs_break': stress_count >= 2,
            'needs_support': negative_count >= 2
        }
    
    def get_supportive_message(self, analysis: Dict) -> str:
        """Generate supportive message based on sentiment"""
        sentiment = analysis['sentiment']
        
        if sentiment == 'stressed':
            return "I notice you might be feeling overwhelmed. Consider taking a short break or breaking tasks into smaller steps. 🌟"
        elif sentiment == 'negative':
            return "It seems like things are challenging right now. Remember, progress is progress, no matter how small! 💪"
        elif sentiment == 'positive':
            return "Great energy! Keep up the momentum! 🎉"
        else:
            return None