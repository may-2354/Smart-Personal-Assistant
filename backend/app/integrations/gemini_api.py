import os
from typing import List, Dict
from google import genai
from google.genai import types
from dotenv import load_dotenv

load_dotenv()

class GeminiService:
    """Gemini Flash AI Service for complex queries"""
    
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        if self.api_key:
            try:
                # NEW: Create client instance instead of configure
                self.client = genai.Client(api_key=self.api_key)
                self.model_name = 'gemini-2.5-flash'  # Updated model name
                print(f"✅ Gemini initialized successfully with {self.model_name}")
            except Exception as e:
                print(f"❌ Gemini initialization error: {e}")
                self.client = None
        else:
            print("⚠️ GEMINI_API_KEY not found in environment variables")
            self.client = None
    
    def decompose_task(self, task_title: str, task_description: str = "") -> List[Dict]:
        """Break down a large task into smaller subtasks using Gemini"""
        if not self.client:
            return self._mock_decompose_task(task_title)
        
        try:
            prompt = f"""Break down this task into 3-5 smaller, actionable subtasks:

Task: {task_title}
Description: {task_description}

For each subtask, provide:
1. A clear title (keep it concise)
2. Estimated duration in minutes
3. Priority level (low, medium, high)

Format your response as a simple list with the format:
- [Title] | [Duration] minutes | [Priority]

Example:
- Research topic | 30 minutes | medium
- Create outline | 20 minutes | high"""
            
            # NEW: Use client.models.generate_content
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt
            )
            
            subtasks = self._parse_subtasks(response.text)
            
            return subtasks
            
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
            return self._mock_decompose_task(task_title)
    
    def get_task_suggestions(self, task_title: str, task_description: str = "") -> str:
        """Get suggestions on how to complete a task"""
        if not self.client:
            return self._mock_suggestions(task_title)
        
        try:
            prompt = f"""Provide 3-4 practical suggestions on how to complete this task efficiently:

Task: {task_title}
Description: {task_description}

Keep suggestions actionable and concise."""
            
            # NEW: Use client.models.generate_content
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt
            )
            
            return response.text
            
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
            return self._mock_suggestions(task_title)
    
    def process_complex_query(self, message: str, user_context: Dict = None) -> str:
        """Process complex query using Gemini AI"""
        if not self.client:
            print("⚠️ Gemini client not available, using fallback")
            return self._fallback_response(message)
        
        try:
            # Build context-aware prompt
            context = ""
            if user_context:
                if user_context.get('tasks'):
                    tasks_info = f"User currently has {len(user_context['tasks'])} tasks"
                    context += f"\n{tasks_info}"
                if user_context.get('stats'):
                    stats = user_context['stats']
                    context += f"\nCompletion rate: {stats.get('completion_rate', 0)}%"
            
            prompt = f"""You are a helpful task management assistant. 

User's question: {message}

Context: {context if context else "No additional context"}

Provide a helpful, actionable response in 2-3 sentences. Be concise and practical."""

            # NEW: Use client.models.generate_content
            print(f"🤖 Sending to Gemini: {message[:50]}...")
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt
            )
            
            print(f"✅ Gemini responded successfully")
            return response.text
            
        except Exception as e:
            print(f"❌ Gemini API error: {e}")
            return self._fallback_response(message)
    
    def _parse_subtasks(self, response_text: str) -> List[Dict]:
        """Parse Gemini's response into structured subtasks"""
        subtasks = []
        lines = response_text.strip().split('\n')
        
        for line in lines:
            if '|' in line:
                parts = [p.strip() for p in line.split('|')]
                if len(parts) >= 3:
                    title = parts[0].strip('- ').strip('*').strip()
                    duration = parts[1].replace('minutes', '').strip()
                    priority = parts[2].strip()
                    
                    try:
                        duration_int = int(duration)
                    except:
                        duration_int = 30
                    
                    subtasks.append({
                        'title': title,
                        'estimated_duration': duration_int,
                        'priority': priority.lower()
                    })
        
        return subtasks if subtasks else self._mock_decompose_task("Task")
    
    def _mock_decompose_task(self, task_title: str) -> List[Dict]:
        """Return mock subtasks when API is not available"""
        return [
            {
                'title': f'Research and plan {task_title}',
                'estimated_duration': 30,
                'priority': 'high'
            },
            {
                'title': f'Execute main work for {task_title}',
                'estimated_duration': 60,
                'priority': 'high'
            },
            {
                'title': f'Review and finalize {task_title}',
                'estimated_duration': 20,
                'priority': 'medium'
            }
        ]
    
    def _mock_suggestions(self, task_title: str) -> str:
        """Return mock suggestions when API is not available"""
        return f"""Here are some suggestions for completing '{task_title}':

1. Break it down into smaller steps
2. Set a specific time to work on it
3. Remove distractions before starting
4. Track your progress as you go"""
    
    def _fallback_response(self, message: str) -> str:
        """Fallback response when Gemini is unavailable"""
        if 'help' in message.lower() or 'how' in message.lower():
            return """Here are some tips for managing tasks effectively:

1. Break large tasks into smaller, manageable subtasks
2. Prioritize based on urgency and importance
3. Set realistic deadlines and stick to them
4. Review your progress regularly

What specific task would you like help with?"""
        
        return "I understand you need help with something complex. Could you rephrase your question or break it down into specific tasks I can help you with?"

# For backward compatibility, create an alias
ClaudeService = GeminiService