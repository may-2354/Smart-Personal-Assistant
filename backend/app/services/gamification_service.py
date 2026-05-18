# app/services/gamification_service.py
from sqlalchemy.orm import Session
from datetime import datetime, timedelta, date
from typing import Dict, List
from app.models.achievement import Achievement, UserAchievement, Streak
from app.models.task import Task
from app.models.user import User

class GamificationService:
    def __init__(self, db: Session):
        self.db = db
        self._ensure_achievements_exist()
    
    def _ensure_achievements_exist(self):
        """Create default achievements if they don't exist"""
        default_achievements = [
            {
                'name': 'First Task',
                'description': 'Complete your first task',
                'badge_icon': '🎯',
                'points': 10,
                'category': 'milestone',
                'rarity': 'common',
                'criteria': {'tasks_completed': 1}
            },
            {
                'name': 'Early Bird',
                'description': 'Complete 10 tasks before 9 AM',
                'badge_icon': '🌅',
                'points': 30,
                'category': 'productivity',
                'rarity': 'common',
                'criteria': {'early_morning_completions': 10}
            },
            {
                'name': 'Night Owl',
                'description': 'Complete 10 tasks after 8 PM',
                'badge_icon': '🦉',
                'points': 30,
                'category': 'productivity',
                'rarity': 'common',
                'criteria': {'night_completions': 10}
            },
            {
                'name': 'Week Warrior',
                'description': 'Complete all tasks for a full week',
                'badge_icon': '⚔️',
                'points': 50,
                'category': 'consistency',
                'rarity': 'rare',
                'criteria': {'week_completion': True}
            },
            {
                'name': 'Comeback Champion',
                'description': 'Complete 3 carried-over tasks in one day',
                'badge_icon': '💪',
                'points': 40,
                'category': 'recovery',
                'rarity': 'rare',
                'criteria': {'carryover_completions_one_day': 3}
            },
            {
                'name': 'Productivity Master',
                'description': 'Maintain 90%+ completion rate for a month',
                'badge_icon': '👑',
                'points': 100,
                'category': 'consistency',
                'rarity': 'epic',
                'criteria': {'completion_rate_30_days': 90}
            },
            {
                'name': 'No Carryover Week',
                'description': 'Zero carryovers for an entire week',
                'badge_icon': '🔥',
                'points': 60,
                'category': 'consistency',
                'rarity': 'rare',
                'criteria': {'zero_carryover_week': True}
            },
            {
                'name': 'Task Master',
                'description': 'Complete 100 tasks',
                'badge_icon': '🏆',
                'points': 80,
                'category': 'milestone',
                'rarity': 'rare',
                'criteria': {'tasks_completed': 100}
            },
            {
                'name': 'Streak Legend',
                'description': 'Maintain a 30-day completion streak',
                'badge_icon': '⚡',
                'points': 150,
                'category': 'consistency',
                'rarity': 'legendary',
                'criteria': {'streak_days': 30}
            },
            {
                'name': 'Speed Demon',
                'description': 'Complete 10 tasks in one day',
                'badge_icon': '🚀',
                'points': 50,
                'category': 'productivity',
                'rarity': 'rare',
                'criteria': {'tasks_one_day': 10}
            },
            {
                'name': 'Perfectionist',
                'description': 'Complete 20 tasks without any carryovers',
                'badge_icon': '💎',
                'points': 70,
                'category': 'consistency',
                'rarity': 'epic',
                'criteria': {'perfect_completions': 20}
            },
            {
                'name': 'Priority Pro',
                'description': 'Complete 50 high-priority tasks',
                'badge_icon': '🎖️',
                'points': 90,
                'category': 'productivity',
                'rarity': 'epic',
                'criteria': {'high_priority_completed': 50}
            },
            {
                'name': 'Organization Expert',
                'description': 'Use 5 different task categories',
                'badge_icon': '📊',
                'points': 25,
                'category': 'milestone',
                'rarity': 'common',
                'criteria': {'categories_used': 5}
            },
            {
                'name': 'Time Wizard',
                'description': 'Estimate task duration within 10% accuracy 20 times',
                'badge_icon': '🧙',
                'points': 75,
                'category': 'productivity',
                'rarity': 'epic',
                'criteria': {'accurate_estimates': 20}
            },
            {
                'name': 'Dedicated',
                'description': 'Use the app for 30 consecutive days',
                'badge_icon': '🌟',
                'points': 120,
                'category': 'consistency',
                'rarity': 'legendary',
                'criteria': {'app_usage_days': 30}
            }
        ]
        
        for achievement_data in default_achievements:
            existing = self.db.query(Achievement).filter(
                Achievement.name == achievement_data['name']
            ).first()
            
            if not existing:
                achievement = Achievement(**achievement_data)
                self.db.add(achievement)
        
        self.db.commit()

    def check_and_award_achievements(self, user_id: int) -> List[Dict]:
        """Check all achievements and award if criteria met"""
        newly_earned = []
        
        # Get user's tasks
        tasks = self.db.query(Task).filter(Task.user_id == user_id).all()
        completed_tasks = [t for t in tasks if t.status == 'completed']
        
        # Get all achievements
        all_achievements = self.db.query(Achievement).all()
        
        # Get already earned achievements
        earned_ids = [
            ua.achievement_id for ua in 
            self.db.query(UserAchievement).filter(UserAchievement.user_id == user_id).all()
        ]
        
        for achievement in all_achievements:
            if achievement.id in earned_ids:
                continue  # Already earned
            
            if self._check_criteria(user_id, achievement.criteria, tasks, completed_tasks):
                # Award achievement
                user_achievement = UserAchievement(
                    user_id=user_id,
                    achievement_id=achievement.id
                )
                self.db.add(user_achievement)
                self.db.commit()
                
                newly_earned.append({
                    'name': achievement.name,
                    'description': achievement.description,
                    'badge_icon': achievement.badge_icon,
                    'points': achievement.points,
                    'rarity': achievement.rarity
                })
        
        return newly_earned

    def _check_criteria(self, user_id: int, criteria: Dict, tasks: List, completed_tasks: List) -> bool:
        """Check if achievement criteria is met"""
        
        if 'tasks_completed' in criteria:
            return len(completed_tasks) >= criteria['tasks_completed']
        
        if 'early_morning_completions' in criteria:
            early_tasks = [
                t for t in completed_tasks 
                if t.completed_at and t.completed_at.hour < 9
            ]
            return len(early_tasks) >= criteria['early_morning_completions']
        
        if 'night_completions' in criteria:
            night_tasks = [
                t for t in completed_tasks 
                if t.completed_at and t.completed_at.hour >= 20
            ]
            return len(night_tasks) >= criteria['night_completions']
        
        if 'week_completion' in criteria:
            # Check if user completed all tasks in last 7 days
            week_ago = datetime.utcnow() - timedelta(days=7)
            week_tasks = [t for t in tasks if t.created_at >= week_ago]
            week_completed = [t for t in week_tasks if t.status == 'completed']
            return len(week_tasks) > 0 and len(week_tasks) == len(week_completed)
        
        if 'carryover_completions_one_day' in criteria:
            # Check any single day
            daily_carryover_completions = {}
            for task in completed_tasks:
                if task.carryover_count > 0 and task.completed_at:
                    day = task.completed_at.date()
                    daily_carryover_completions[day] = daily_carryover_completions.get(day, 0) + 1
            
            return any(count >= criteria['carryover_completions_one_day'] 
                      for count in daily_carryover_completions.values())
        
        if 'completion_rate_30_days' in criteria:
            month_ago = datetime.utcnow() - timedelta(days=30)
            month_tasks = [t for t in tasks if t.created_at >= month_ago]
            if len(month_tasks) < 10:  # Need minimum tasks
                return False
            month_completed = [t for t in month_tasks if t.status == 'completed']
            completion_rate = (len(month_completed) / len(month_tasks) * 100) if month_tasks else 0
            return completion_rate >= criteria['completion_rate_30_days']
        
        if 'zero_carryover_week' in criteria:
            week_ago = datetime.utcnow() - timedelta(days=7)
            week_tasks = [t for t in tasks if t.created_at >= week_ago]
            return all(t.carryover_count == 0 for t in week_tasks) and len(week_tasks) > 0
        
        if 'streak_days' in criteria:
            streak = self.db.query(Streak).filter(
                Streak.user_id == user_id,
                Streak.streak_type == 'daily_completion'
            ).first()
            return streak and streak.current_count >= criteria['streak_days']
        
        if 'tasks_one_day' in criteria:
            daily_completions = {}
            for task in completed_tasks:
                if task.completed_at:
                    day = task.completed_at.date()
                    daily_completions[day] = daily_completions.get(day, 0) + 1
            return any(count >= criteria['tasks_one_day'] for count in daily_completions.values())
        
        if 'perfect_completions' in criteria:
            perfect_tasks = [t for t in completed_tasks if t.carryover_count == 0]
            return len(perfect_tasks) >= criteria['perfect_completions']
        
        if 'high_priority_completed' in criteria:
            high_priority = [t for t in completed_tasks if t.priority in ['high', 'critical']]
            return len(high_priority) >= criteria['high_priority_completed']
        
        if 'categories_used' in criteria:
            categories = set(t.category for t in tasks if t.category)
            return len(categories) >= criteria['categories_used']
        
        if 'accurate_estimates' in criteria:
            # Check tasks with estimated and actual duration
            accurate = [
                t for t in completed_tasks 
                if t.estimated_duration and t.actual_duration and
                abs(t.actual_duration - t.estimated_duration) / t.estimated_duration <= 0.1
            ]
            return len(accurate) >= criteria['accurate_estimates']
        
        if 'app_usage_days' in criteria:
            # Check consecutive days of task creation/completion
            activity_dates = set()
            for task in tasks:
                if task.created_at:
                    activity_dates.add(task.created_at.date())
                if task.completed_at:
                    activity_dates.add(task.completed_at.date())
            
            if not activity_dates:
                return False
            
            # Check for consecutive days
            sorted_dates = sorted(activity_dates)
            max_streak = 1
            current_streak = 1
            
            for i in range(1, len(sorted_dates)):
                if (sorted_dates[i] - sorted_dates[i-1]).days == 1:
                    current_streak += 1
                    max_streak = max(max_streak, current_streak)
                else:
                    current_streak = 1
            
            return max_streak >= criteria['app_usage_days']
        
        return False

    def update_streak(self, user_id: int, streak_type: str = 'daily_completion') -> Dict:
        """Update user's streak"""
        today = datetime.utcnow().date()
        
        streak = self.db.query(Streak).filter(
            Streak.user_id == user_id,
            Streak.streak_type == streak_type
        ).first()
        
        if not streak:
            # Create new streak
            streak = Streak(
                user_id=user_id,
                streak_type=streak_type,
                current_count=1,
                best_count=1,
                last_activity_date=datetime.utcnow()
            )
            self.db.add(streak)
            self.db.commit()
            return {'current_streak': 1, 'best_streak': 1, 'status': 'new_streak'}
        
        # Check if activity was today
        if streak.last_activity_date:
            last_date = streak.last_activity_date.date()
            
            if last_date == today:
                # Already updated today
                return {
                    'current_streak': streak.current_count,
                    'best_streak': streak.best_count,
                    'status': 'already_updated'
                }
            elif last_date == today - timedelta(days=1):
                # Consecutive day
                streak.current_count += 1
                if streak.current_count > streak.best_count:
                    streak.best_count = streak.current_count
                status = 'streak_continued'
            else:
                # Streak broken
                streak.current_count = 1
                status = 'streak_broken'
        else:
            streak.current_count = 1
            status = 'streak_started'
        
        streak.last_activity_date = datetime.utcnow()
        self.db.commit()
        
        return {
            'current_streak': streak.current_count,
            'best_streak': streak.best_count,
            'status': status
        }

    def get_user_gamification_stats(self, user_id: int) -> Dict:
        """Get complete gamification stats for user"""
        # Get achievements
        user_achievements = self.db.query(UserAchievement).filter(
            UserAchievement.user_id == user_id
        ).all()
        
        total_points = sum(ua.achievement.points for ua in user_achievements)
        
        achievements_by_rarity = {
            'common': len([ua for ua in user_achievements if ua.achievement.rarity == 'common']),
            'rare': len([ua for ua in user_achievements if ua.achievement.rarity == 'rare']),
            'epic': len([ua for ua in user_achievements if ua.achievement.rarity == 'epic']),
            'legendary': len([ua for ua in user_achievements if ua.achievement.rarity == 'legendary'])
        }
        
        # Get streaks
        streaks = self.db.query(Streak).filter(Streak.user_id == user_id).all()
        streak_data = {
            s.streak_type: {
                'current': s.current_count,
                'best': s.best_count,
                'last_activity': s.last_activity_date.isoformat() if s.last_activity_date else None
            }
            for s in streaks
        }
        
        # Calculate level (every 100 points = 1 level)
        level = (total_points // 100) + 1
        points_to_next_level = 100 - (total_points % 100)
        
        return {
            'total_points': total_points,
            'level': level,
            'points_to_next_level': points_to_next_level,
            'achievements_earned': len(user_achievements),
            'achievements_by_rarity': achievements_by_rarity,
            'streaks': streak_data,
            'recent_achievements': [
                {
                    'name': ua.achievement.name,
                    'badge_icon': ua.achievement.badge_icon,
                    'earned_at': ua.earned_at.isoformat()
                }
                for ua in sorted(user_achievements, key=lambda x: x.earned_at, reverse=True)[:5]
            ]
        }

    def get_leaderboard(self, limit: int = 10) -> List[Dict]:
        """Get top users by points"""
        # Get all users with their points
        users_points = {}
        
        all_user_achievements = self.db.query(UserAchievement).all()
        
        for ua in all_user_achievements:
            if ua.user_id not in users_points:
                users_points[ua.user_id] = 0
            users_points[ua.user_id] += ua.achievement.points
        
        # Sort by points
        sorted_users = sorted(users_points.items(), key=lambda x: x[1], reverse=True)[:limit]
        
        # Get user details
        leaderboard = []
        for rank, (user_id, points) in enumerate(sorted_users, 1):
            user = self.db.query(User).filter(User.id == user_id).first()
            if user:
                leaderboard.append({
                    'rank': rank,
                    'user_id': user_id,
                    'username': user.username,
                    'points': points,
                    'level': (points // 100) + 1
                })
        
        return leaderboard