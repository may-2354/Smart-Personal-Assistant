import re
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta, time as datetime_time
import os
from dotenv import load_dotenv

load_dotenv()

class SimpleNLU:
    """Simple Natural Language Understanding for task management"""
    
    def __init__(self):
        self.intents = {
            'create_task': [
                r'create task (.+)',
                r'add task (.+)',
                r'new task (.+)',
                r'i need to (.+)',
                r'remind me to (.+)',
                r'schedule (.+)',
                r'add (.+) to my list',
            ],
            'view_tasks': [
                r'show (my )?tasks',
                r'list (my )?tasks',
                r'what tasks',
                r'my tasks',
                r'show (my )?to.?do',
                r'what do i have',
                r'tasks for today',
            ],
            'get_stats': [
                r'show (my )?stats',
                r'my statistics',
                r'how am i doing',
                r'show (my )?progress',
                r'completion rate',
                r'my productivity',
            ],
            'mark_complete': [
                r'complete (.+)',
                r'mark (.+) (as )?complete',
                r'finished (.+)',
                r'done with (.+)',
                r'i completed (.+)',
                r'(.+) is done',
            ],
            'delete_task': [
                r'delete (.+)',
                r'remove (.+)',
                r'cancel (.+)',
            ],
            'overdue_tasks': [
                r'overdue',
                r'late tasks',
                r'what.?s late',
                r'missed tasks',
                r'show delayed',
            ],
            'help': [
                r'^help$',
                r'what can you do',
                r'commands',
                r'how to use',
            ],
            'greet': [
                r'^hi$',
                r'^hello$',
                r'^hey$',
                r'good morning',
                r'good evening',
            ],
            'goodbye': [
                r'^bye$',
                r'goodbye',
                r'see you',
            ],
        }
        
        # Complex query indicators - route to Gemini
        self.complex_indicators = [
            'how should', 'help me', 'suggest', 'advice', 'recommend',
            'what do you think', 'tips', 'best way', 'how to approach',
            'strategy', 'plan for', 'break down', 'prioritize',
            'what if', 'should i', 'better to'
        ]
    
    def is_complex_query(self, text: str) -> bool:
        """Determine if query needs Gemini AI"""
        text_lower = text.lower()
        return any(indicator in text_lower for indicator in self.complex_indicators)
    
    def detect_intent(self, text: str) -> Tuple[str, Optional[str]]:
        """Detect intent and extract entity from user message"""
        text_lower = text.lower().strip()
        
        for intent, patterns in self.intents.items():
            for pattern in patterns:
                match = re.search(pattern, text_lower)
                if match:
                    # Extract entity if present
                    entity = match.group(1) if match.groups() else None
                    if entity:
                        entity = entity.strip()
                    return intent, entity
        
        return 'unknown', None
    
    def parse_deadline(self, text: str) -> Optional[datetime]:
        """Extract deadline from text"""
        text_lower = text.lower()
        
        if 'today' in text_lower:
            return datetime.now().replace(hour=17, minute=0, second=0, microsecond=0)
        
        if 'tomorrow' in text_lower:
            return (datetime.now() + timedelta(days=1)).replace(hour=17, minute=0, second=0, microsecond=0)
        
        if 'this week' in text_lower:
            days_until_sunday = 6 - datetime.now().weekday()
            return datetime.now() + timedelta(days=days_until_sunday)
        
        if 'next week' in text_lower:
            return datetime.now() + timedelta(days=7)
        
        if 'next month' in text_lower:
            return datetime.now() + timedelta(days=30)
        
        return None
    
    def extract_date_from_query(self, text: str) -> Optional[datetime]:
        """Extract specific date from query like 'tasks for 18 may' or 'tasks on monday'"""
        text_lower = text.lower()
        
        # Handle "today"
        if 'today' in text_lower:
            return datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Handle "tomorrow"
        if 'tomorrow' in text_lower:
            return (datetime.now() + timedelta(days=1)).replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Handle day names (monday, tuesday, etc.)
        days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        for i, day in enumerate(days):
            if day in text_lower:
                current_day = datetime.now().weekday()
                days_ahead = i - current_day
                if days_ahead <= 0:
                    days_ahead += 7
                return (datetime.now() + timedelta(days=days_ahead)).replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Handle "DD month" format (e.g., "18 may", "5 june")
        months = {
            'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
            'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6,
            'july': 7, 'jul': 7, 'august': 8, 'aug': 8, 'september': 9, 'sep': 9,
            'october': 10, 'oct': 10, 'november': 11, 'nov': 11, 'december': 12, 'dec': 12
        }
        
        for month_name, month_num in months.items():
            pattern = rf'(\d{{1,2}})\s+{month_name}'
            match = re.search(pattern, text_lower)
            if match:
                day = int(match.group(1))
                year = datetime.now().year
                try:
                    return datetime(year, month_num, day, 0, 0, 0)
                except ValueError:
                    continue
        
        # Handle "month DD" format (e.g., "may 18")
        for month_name, month_num in months.items():
            pattern = rf'{month_name}\s+(\d{{1,2}})'
            match = re.search(pattern, text_lower)
            if match:
                day = int(match.group(1))
                year = datetime.now().year
                try:
                    return datetime(year, month_num, day, 0, 0, 0)
                except ValueError:
                    continue
        
        return None

    def parse_deadline_with_time(self, text: str) -> Optional[datetime]:
        """Extract deadline with specific time from text"""
        text_lower = text.lower()
    
    # Extract time first (e.g., "9pm", "9:30 pm", "21:00")
        time_pattern = r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)?'
        time_match = re.search(time_pattern, text_lower)
    
        hour = 17  # Default 5 PM
        minute = 0
    
        if time_match:
            hour = int(time_match.group(1))
            minute = int(time_match.group(2)) if time_match.group(2) else 0
            am_pm = time_match.group(3)
        
            # Convert to 24-hour format
            if am_pm == 'pm' and hour != 12:
                hour += 12
            elif am_pm == 'am' and hour == 12:
                hour = 0
            elif not am_pm and hour >= 1 and hour <= 12:
                # Assume PM if no am/pm specified and hour is 1-12
                if hour < 7:  # 1-6 without am/pm = PM
                    hour += 12
    
    # Now extract the date
        if 'today' in text_lower:
            return datetime.now().replace(hour=hour, minute=minute, second=0, microsecond=0)
    
        if 'tomorrow' in text_lower:
            return (datetime.now() + timedelta(days=1)).replace(hour=hour, minute=minute, second=0, microsecond=0)
    
    # Handle day names
        days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
        for i, day in enumerate(days):
            if day in text_lower:
                current_day = datetime.now().weekday()
                days_ahead = i - current_day
                if days_ahead <= 0:
                    days_ahead += 7
                return (datetime.now() + timedelta(days=days_ahead)).replace(hour=hour, minute=minute, second=0, microsecond=0)
    
    # Handle "DD month" or "month DD" with time
        months = {
            'january': 1, 'jan': 1, 'february': 2, 'feb': 2, 'march': 3, 'mar': 3,
            'april': 4, 'apr': 4, 'may': 5, 'june': 6, 'jun': 6,
            'july': 7, 'jul': 7, 'august': 8, 'aug': 8, 'september': 9, 'sep': 9,
            'october': 10, 'oct': 10, 'november': 11, 'nov': 11, 'december': 12, 'dec': 12
        }
    
        for month_name, month_num in months.items():
        # "18 may"
            pattern = rf'(\d{{1,2}})\s+{month_name}'
            match = re.search(pattern, text_lower)
            if match:
                day = int(match.group(1))
                year = datetime.now().year
                try:
                    return datetime(year, month_num, day, hour, minute, 0)
                except ValueError:
                    continue
        
        # "may 18"
            pattern = rf'{month_name}\s+(\d{{1,2}})'
            match = re.search(pattern, text_lower)
            if match:
                day = int(match.group(1))
                year = datetime.now().year
                try:
                    return datetime(year, month_num, day, hour, minute, 0)
                except ValueError:
                    continue
    
    # Fallback to old parse_deadline behavior
        if 'this week' in text_lower:
            days_until_sunday = 6 - datetime.now().weekday()
            return (datetime.now() + timedelta(days=days_until_sunday)).replace(hour=hour, minute=minute, second=0, microsecond=0)
    
        if 'next week' in text_lower:
            return (datetime.now() + timedelta(days=7)).replace(hour=hour, minute=minute, second=0, microsecond=0)
    
        if 'next month' in text_lower:
            return (datetime.now() + timedelta(days=30)).replace(hour=hour, minute=minute, second=0, microsecond=0)
    
        return None

from google import genai

class GeminiNLU:
    """Advanced NLU using Google Gemini AI for complex queries"""
    
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.client = None
        if self.api_key:
            try:
                self.client = genai.Client(api_key=self.api_key)                
            except Exception as e:
                print(f"Gemini initialization error: {e}")
                self.client = None
    
    def process_complex_query(self, message: str, user_context: Dict = None) -> str:
        """Process complex query using Gemini AI"""
        if not self.client:
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

            response = self.client.models.generate_content(
                model='gemini-2.5-flash',
                contents=prompt
            )
            
            return response.text
            
        except Exception as e:
            print(f"Gemini API error: {e}")
            return self._fallback_response(message)
    
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

class ConversationService:
    """Handle conversational interactions with hybrid NLU"""
    
    def __init__(self, db, user_id: int):
        self.db = db
        self.user_id = user_id
        self.simple_nlu = SimpleNLU()
        self.gemini_nlu = GeminiNLU()
        self.conversation_history = []
    
    def get_user_context(self) -> Dict:
        """Get user context for Gemini"""
        from app.services.task_service import TaskService
        
        task_service = TaskService(self.db)
        
        try:
            tasks = task_service.get_user_tasks(self.user_id, limit=10)
            stats = task_service.get_task_stats(self.user_id)
            
            return {
                'tasks': tasks,
                'stats': stats,
                'task_count': len(tasks)
            }
        except:
            return {}
    
    def process_message(self, message: str) -> Dict:
        """Process user message with intelligent routing"""
        
        # Add to conversation history
        self.conversation_history.append({
            'role': 'user',
            'message': message,
            'timestamp': datetime.now()
        })
        
        # Check if it's a complex query that needs Gemini
        if self.simple_nlu.is_complex_query(message):
            return self._handle_complex_query(message)
        
        # Otherwise, use simple NLU for quick responses
        return self._handle_simple_query(message)
    
    def _handle_complex_query(self, message: str) -> Dict:
        """Handle complex queries with Gemini AI"""
        context = self.get_user_context()
    
        response = self.gemini_nlu.process_complex_query(message, context)
    
        # ⭐ NEW: Check if Gemini created a task and actually create it!
        task_created = False
        message_lower = message.lower()
        response_lower = response.lower()
    
        # Detect if this was a task creation request
        is_task_request = any(keyword in message_lower for keyword in [
            'create task', 'add task', 'new task', 'create a task',
            'schedule', 'remind me', 'set up', 'add a', 'create a'
        ])
    
        # Detect if Gemini confirmed task creation
        is_task_confirmed = any(phrase in response_lower for phrase in [
            'task has been added',
            'task added',
            'has been scheduled',
            'scheduled for you',
            'added to your list',
            'added to your schedule',
            'is now added',
            'i\'ve scheduled',
            'i\'ve created',
            'successfully added',
            'successfully scheduled',
            'has been set',
            'have been set',
            'is set as',
            'set as a recurring'
        ])
    
        if is_task_request and is_task_confirmed:
            # ⭐ ACTUALLY CREATE THE TASK IN DATABASE!
            try:
                # Check if it's a recurring task
                if self._is_recurring_task(message):
                    # Handle recurring tasks
                    pattern = self._extract_recurring_pattern(message)
                    
                    if pattern['is_recurring']:
                        # Extract title (remove time/day info)
                        task_title = self._extract_task_title(message)
                        # Clean up title from day/time mentions
                        for word in ['from', 'to', 'am', 'pm', 'monday', 'tuesday', 'wednesday', 
                                    'thursday', 'friday', 'saturday', 'sunday', 'recurring', 
                                    'every', 'daily', 'weekly', 'weekdays']:
                            task_title = re.sub(rf'\b{word}\b', '', task_title, flags=re.IGNORECASE)
                        task_title = re.sub(r'\s+', ' ', task_title).strip()  # Clean whitespace
                        task_title = re.sub(r'\d{1,2}:?\d{0,2}\s*(am|pm)?', '', task_title, flags=re.IGNORECASE).strip()
                        
                        priority = self._extract_priority(message)
                        
                        # Create multiple recurring tasks
                        count = self._create_recurring_tasks(task_title, pattern, priority)
                        task_created = True
                        
                        print(f"✅ Created {count} recurring tasks: {task_title}")
                        
                        # Update response to mention count
                        response = f"🤔 {response}\n\n✅ Created {count} recurring tasks in your calendar!"
                    else:
                        # Fallback to single task
                        task_title = self._extract_task_title(message)
                        deadline = self.simple_nlu.parse_deadline(message)
                        priority = self._extract_priority(message)
                        
                        from app.services.task_service import TaskService
                        from app.schemas.task import TaskCreate
                        
                        task_service = TaskService(self.db)
                        task_data = TaskCreate(
                            title=task_title,
                            priority=priority,
                            deadline=deadline,
                            description=f"Created via AI assistant: {message[:100]}"
                        )
                        
                        task = task_service.create_task(self.user_id, task_data)
                        task_created = True
                        
                        print(f"✅ Task created in DB: ID={task.id}, Title={task.title}")
                else:
                    # Non-recurring single task
                    task_title = self._extract_task_title(message)
                    deadline = self.simple_nlu.parse_deadline(message)
                    priority = self._extract_priority(message)
                    
                    from app.services.task_service import TaskService
                    from app.schemas.task import TaskCreate
                    
                    task_service = TaskService(self.db)
                    task_data = TaskCreate(
                        title=task_title,
                        priority=priority,
                        deadline=deadline,
                        description=f"Created via AI assistant: {message[:100]}"
                    )
                    
                    task = task_service.create_task(self.user_id, task_data)
                    task_created = True
                    
                    print(f"✅ Task created in DB: ID={task.id}, Title={task.title}")
                
            except Exception as e:
                print(f"❌ Error creating task: {e}")
                import traceback
                traceback.print_exc()
    
        return {
            'response': f"🤔 {response}",
            'intent': 'complex_query',
            'handled_by': 'gemini_ai',
            'task_created': task_created,
            'suggestion': True
        }
    
    def _handle_simple_query(self, message: str) -> Dict:
        """Handle simple queries with pattern matching"""
        intent, entity = self.simple_nlu.detect_intent(message)
        
        if intent == 'greet':
            return {
                'response': "Hello! 👋 I'm your AI task assistant. I can help you manage tasks, give productivity advice, and answer questions. What would you like to do?",
                'intent': intent,
                'handled_by': 'simple_nlu'
            }
        
        elif intent == 'goodbye':
            return {
                'response': "Goodbye! Have a productive day! 🚀",
                'intent': intent,
                'handled_by': 'simple_nlu'
            }
        
        elif intent == 'help':
            return {
                'response': """I can help you with:

**Quick Commands:**
📝 "Create task [name]" - Add a new task
📋 "Show my tasks" - View all tasks
📋 "Show my tasks for [date]" - View tasks for specific date
✅ "Complete [task name]" - Mark as done
🗑️ "Delete [task name]" - Remove task
📊 "Show my stats" - View statistics
⏰ "Show overdue tasks" - See delayed items

**AI-Powered Help:**
💡 Ask me "How should I approach..." for advice
🎯 Ask me "Help me prioritize..." for suggestions
🧠 Ask me "Break down..." for task decomposition

What would you like to do?""",
                'intent': intent,
                'handled_by': 'simple_nlu'
            }
        
        elif intent == 'create_task':
            if entity:
                from app.services.task_service import TaskService
                from app.schemas.task import TaskCreate
                
                task_service = TaskService(self.db)
                deadline = self.simple_nlu.parse_deadline_with_time(message)
                
                task_data = TaskCreate(
                    title=entity,
                    priority='medium',
                    deadline=deadline
                )
                
                try:
                    task = task_service.create_task(self.user_id, task_data)
                    deadline_text = f" 📅 Due: {deadline.strftime('%b %d')}" if deadline else ""
                    return {
                        'response': f"✅ Created task: '{entity}'{deadline_text}",
                        'intent': intent,
                        'task_id': task.id,
                        'handled_by': 'simple_nlu'
                    }
                except Exception as e:
                    return {
                        'response': f"Sorry, I couldn't create the task. Error: {str(e)}",
                        'intent': intent,
                        'error': True,
                        'handled_by': 'simple_nlu'
                    }
            else:
                return {
                    'response': "What task would you like to create?",
                    'intent': intent,
                    'needs_clarification': True,
                    'handled_by': 'simple_nlu'
                }
        
        elif intent == 'view_tasks':
            from app.services.task_service import TaskService
            
            task_service = TaskService(self.db)
            
            # Check if user specified a date
            target_date = self.simple_nlu.extract_date_from_query(message)
            
            if target_date:
                # Filter tasks for specific date
                all_tasks = task_service.get_user_tasks(self.user_id, limit=100)
                tasks = [task for task in all_tasks if task.deadline and task.deadline.date() == target_date.date()]
                
                date_str = target_date.strftime('%B %d, %Y')  # "May 18, 2026"
                
                if not tasks:
                    return {
                        'response': f"📋 No tasks scheduled for {date_str}",
                        'intent': intent,
                        'handled_by': 'simple_nlu'
                    }
                
                response = f"📋 **Tasks for {date_str}:**\n\n"
            else:
                # Show all tasks
                tasks = task_service.get_user_tasks(self.user_id, limit=10)
                
                if not tasks:
                    return {
                        'response': "You don't have any tasks yet! Create one to get started. Try: 'Create task finish report'",
                        'intent': intent,
                        'handled_by': 'simple_nlu'
                    }
                
                response = "📋 **Your Tasks:**\n\n"
            
            for i, task in enumerate(tasks[:20], 1):
                status_icon = "✅" if task.status == "completed" else "⏳"
                priority_icons = {
                    "critical": "🔴",
                    "high": "🟠", 
                    "medium": "🟡",
                    "low": "🟢"
                }
                priority_icon = priority_icons.get(task.priority, "⚪")
                
                deadline_text = ""
                if task.deadline:
                    deadline_text = f" (Due: {task.deadline.strftime('%b %d')})"
                
                response += f"{i}. {status_icon} {priority_icon} {task.title}{deadline_text}\n"
            
            response += f"\n💡 Tip: Say 'Complete [task name]' to mark as done!"
            
            return {
                'response': response,
                'intent': intent,
                'task_count': len(tasks),
                'handled_by': 'simple_nlu'
            }
        
        elif intent == 'get_stats':
            from app.services.task_service import TaskService
            
            task_service = TaskService(self.db)
            stats = task_service.get_task_stats(self.user_id)
            
            # Get carryover stats
            from app.services.carryover_service import CarryoverService
            carryover_service = CarryoverService(self.db)
            carryover_stats = carryover_service.get_carryover_stats(self.user_id)
            
            emoji = "🔥" if stats['completion_rate'] >= 70 else "💪"
            
            response = f"""📊 **Your Productivity Stats:**

✅ Completed: {stats['completed']}
⏳ Pending: {stats['pending']}
📈 Total: {stats['total']}
🎯 Completion Rate: {stats['completion_rate']}%
🔄 Tasks Carried Over: {carryover_stats['tasks_with_carryovers']}

{emoji} {"Great job! Keep it up!" if stats['completion_rate'] >= 70 else "You're making progress!"}"""
            
            return {
                'response': response,
                'intent': intent,
                'stats': stats,
                'handled_by': 'simple_nlu'
            }
        
        elif intent == 'mark_complete':
            if entity:
                from app.services.task_service import TaskService
                
                task_service = TaskService(self.db)
                tasks = task_service.get_user_tasks(self.user_id)
                
                for task in tasks:
                    if entity.lower() in task.title.lower():
                        from app.schemas.task import TaskUpdate, TaskStatus
                        task_service.update_task(
                            self.user_id, 
                            task.id, 
                            TaskUpdate(status=TaskStatus.completed)
                        )
                        return {
                            'response': f"✅ Marked '{task.title}' as completed! Great job! 🎉",
                            'intent': intent,
                            'task_id': task.id,
                            'handled_by': 'simple_nlu'
                        }
                
                return {
                    'response': f"I couldn't find a task matching '{entity}'. Try 'Show my tasks' to see your list.",
                    'intent': intent,
                    'handled_by': 'simple_nlu'
                }
            else:
                return {
                    'response': "Which task did you complete?",
                    'intent': intent,
                    'needs_clarification': True,
                    'handled_by': 'simple_nlu'
                }
        
        elif intent == 'delete_task':
            if entity:
                from app.services.task_service import TaskService
                
                task_service = TaskService(self.db)
                tasks = task_service.get_user_tasks(self.user_id)
                
                for task in tasks:
                    if entity.lower() in task.title.lower():
                        task_service.delete_task(self.user_id, task.id)
                        return {
                            'response': f"🗑️ Deleted task: '{task.title}'",
                            'intent': intent,
                            'task_id': task.id,
                            'handled_by': 'simple_nlu'
                        }
                
                return {
                    'response': f"I couldn't find a task matching '{entity}'.",
                    'intent': intent,
                    'handled_by': 'simple_nlu'
                }
            else:
                return {
                    'response': "Which task would you like to delete?",
                    'intent': intent,
                    'needs_clarification': True,
                    'handled_by': 'simple_nlu'
                }
        
        elif intent == 'overdue_tasks':
            from app.services.task_service import TaskService
            
            task_service = TaskService(self.db)
            overdue = task_service.get_overdue_tasks(self.user_id)
            
            if not overdue:
                return {
                    'response': "🎉 No overdue tasks! You're all caught up! Keep up the great work!",
                    'intent': intent,
                    'handled_by': 'simple_nlu'
                }
            
            response = "⚠️ **Overdue Tasks:**\n\n"
            for i, task in enumerate(overdue, 1):
                days_overdue = (datetime.now() - task.deadline).days if task.deadline else 0
                response += f"{i}. {task.title} ({days_overdue} days overdue)\n"
            
            response += "\n💡 Would you like me to help you reschedule these?"
            
            return {
                'response': response,
                'intent': intent,
                'overdue_count': len(overdue),
                'handled_by': 'simple_nlu'
            }
        
        else:
            # Unknown intent - route to Gemini for help
            return self._handle_complex_query(message)
    
    def _extract_task_title(self, message: str) -> str:
        """Extract task title from user message"""
        message_lower = message.lower()
        
        # Remove command words
        title = message
        for cmd in ['create task', 'add task', 'new task', 'create a task',
                    'add a task', 'schedule', 'remind me to', 'set up',
                    'create a', 'add a']:
            if cmd in message_lower:
                # Find the command and take everything after it
                idx = message_lower.find(cmd)
                title = message[idx + len(cmd):].strip()
                break
        
        # Clean up
        title = title.strip(' .,:;')
        
        # Capitalize first letter
        if title:
            title = title[0].upper() + title[1:] if len(title) > 1 else title.upper()
        else:
            title = "New Task"
        
        # Limit length
        if len(title) > 200:
            title = title[:197] + "..."
        
        return title
    
    def _extract_priority(self, message: str) -> str:
        """Extract priority from message"""
        message_lower = message.lower()
        
        if any(word in message_lower for word in ['urgent', 'critical', 'asap', 'immediately', 'emergency']):
            return 'critical'
        elif any(word in message_lower for word in ['important', 'high priority', 'soon']):
            return 'high'
        elif any(word in message_lower for word in ['low', 'minor', 'whenever', 'eventually']):
            return 'low'
        else:
            return 'medium'
    
    def _is_recurring_task(self, message: str) -> bool:
        """Check if task is recurring"""
        message_lower = message.lower()
        recurring_keywords = [
            'every', 'daily', 'weekly', 'recurring', 'recur',
            'monday to friday', 'weekdays', 'mon-fri',
            'every day', 'each day', 'every week'
        ]
        return any(keyword in message_lower for keyword in recurring_keywords)
    
    def _extract_recurring_pattern(self, message: str) -> Dict:
        """Extract recurring task pattern"""
        message_lower = message.lower()
        pattern = {
            'is_recurring': False,
            'days': [],
            'start_time': None,
            'end_time': None,
            'duration_weeks': 8  # Default 2 months
        }
        
        # Extract days
        if 'monday to friday' in message_lower or 'weekdays' in message_lower or 'mon-fri' in message_lower:
            pattern['days'] = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday']
            pattern['is_recurring'] = True
        elif 'every day' in message_lower or 'daily' in message_lower:
            pattern['days'] = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']
            pattern['is_recurring'] = True
        elif 'every monday' in message_lower:
            pattern['days'] = ['monday']
            pattern['is_recurring'] = True
        # Add more day patterns as needed
        
        # Extract time - look for patterns like "7am", "7:00 AM", "8:30am"
        time_pattern = r'(\d{1,2}):?(\d{2})?\s*(am|pm)'
        times = re.findall(time_pattern, message_lower)
        
        if len(times) >= 2:
            # Start time (first match)
            hour1 = int(times[0][0])
            minute1 = int(times[0][1]) if times[0][1] else 0
            if times[0][2] == 'pm' and hour1 != 12:
                hour1 += 12
            elif times[0][2] == 'am' and hour1 == 12:
                hour1 = 0
            pattern['start_time'] = datetime_time(hour1, minute1)
            
            # End time (second match)
            hour2 = int(times[1][0])
            minute2 = int(times[1][1]) if times[1][1] else 0
            if times[1][2] == 'pm' and hour2 != 12:
                hour2 += 12
            elif times[1][2] == 'am' and hour2 == 12:
                hour2 = 0
            pattern['end_time'] = datetime_time(hour2, minute2)
        
        return pattern
    
    def _create_recurring_tasks(self, title: str, pattern: Dict, priority: str) -> int:
        """Create multiple tasks for recurring pattern"""
        from app.services.task_service import TaskService
        from app.schemas.task import TaskCreate
        
        task_service = TaskService(self.db)
        created_count = 0
        
        # Get next occurrence of each day
        day_map = {
            'monday': 0, 'tuesday': 1, 'wednesday': 2,
            'thursday': 3, 'friday': 4, 'saturday': 5, 'sunday': 6
        }
        
        today = datetime.now()
        
        # For each day in pattern
        for day_name in pattern['days']:
            target_weekday = day_map[day_name]
            current_weekday = today.weekday()
            
            # Calculate days until next occurrence
            days_ahead = target_weekday - current_weekday
            if days_ahead <= 0:  # Target day already passed this week
                days_ahead += 7
            
            # Create tasks for next N weeks
            for week in range(pattern.get('duration_weeks', 8)):
                task_date = today + timedelta(days=days_ahead + (week * 7))
                
                # Set deadline with time
                if pattern['start_time']:
                    deadline = task_date.replace(
                        hour=pattern['start_time'].hour,
                        minute=pattern['start_time'].minute,
                        second=0,
                        microsecond=0
                    )
                else:
                    deadline = task_date.replace(hour=9, minute=0, second=0, microsecond=0)
                
                # Create task
                task_data = TaskCreate(
                    title=f"{title} ({day_name.title()})",
                    priority=priority,
                    deadline=deadline,
                    description=f"Recurring task: {title}\nTime: {pattern['start_time']} - {pattern['end_time']}" if pattern['start_time'] else f"Recurring task: {title}"
                )
                
                try:
                    task_service.create_task(self.user_id, task_data)
                    created_count += 1
                except Exception as e:
                    print(f"Error creating recurring task: {e}")
        
        return created_count