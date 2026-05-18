from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.services.analytics_service import AnalyticsService
from app.services.habit_service import HabitLearningService
from app.services.gamification_service import GamificationService

router = APIRouter()

@router.get("/productivity")
def get_productivity_metrics(
    days: int = Query(30, ge=1, le=365),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get detailed productivity metrics"""
    service = AnalyticsService(db)
    return service.get_detailed_productivity_metrics(current_user.id, days)

@router.get("/burnout")
def check_burnout_risk(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check burnout risk with recommendations"""
    service = AnalyticsService(db)
    return service.detect_burnout(current_user.id)

@router.get("/patterns")
def get_productivity_patterns(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Recognize and analyze productivity patterns"""
    service = AnalyticsService(db)
    return service.recognize_patterns(current_user.id)

@router.get("/habits")
def get_learned_habits(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get learned habits and personalized suggestions"""
    service = HabitLearningService(db)
    return service.learn_user_habits(current_user.id)

@router.get("/gamification")
def get_gamification_stats(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get gamification stats (points, achievements, streaks)"""
    service = GamificationService(db)
    
    # Check for new achievements
    newly_earned = service.check_and_award_achievements(current_user.id)
    
    # Get complete stats
    stats = service.get_user_gamification_stats(current_user.id)
    
    if newly_earned:
        stats['newly_earned'] = newly_earned
    
    return stats

@router.post("/streak/update")
def update_daily_streak(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update daily completion streak"""
    service = GamificationService(db)
    return service.update_streak(current_user.id)

@router.get("/leaderboard")
def get_leaderboard(
    limit: int = Query(10, ge=1, le=100),
    db: Session = Depends(get_db)
):
    """Get leaderboard (top users by points)"""
    service = GamificationService(db)
    return service.get_leaderboard(limit)

@router.get("/achievements/check")
def check_new_achievements(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Check and award any new achievements"""
    service = GamificationService(db)
    newly_earned = service.check_and_award_achievements(current_user.id)
    
    if newly_earned:
        return {
            'message': f'Congratulations! You earned {len(newly_earned)} new achievement(s)!',
            'achievements': newly_earned
        }
    else:
        return {
            'message': 'No new achievements at this time. Keep working towards your goals!',
            'achievements': []
        }