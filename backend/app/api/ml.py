from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.database import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.services.ml_service import MLService

router = APIRouter()

class PredictRequest(BaseModel):
    title: str
    description: str = None
    priority: str = "medium"
    deadline: str = None

@router.post("/predict-priority")
def predict_priority(
    request: PredictRequest,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Predict task priority using ML"""
    ml_service = MLService(db)
    
    task_data = {
        'title': request.title,
        'description': request.description,
        'priority': request.priority,
        'deadline': request.deadline,
        'carryover_count': 0
    }
    
    predicted_priority = ml_service.predict_priority(task_data)
    estimated_duration = ml_service.estimate_duration(task_data)
    
    return {
        'predicted_priority': predicted_priority,
        'estimated_duration_minutes': estimated_duration,
        'estimated_duration_hours': round(estimated_duration / 60, 1)
    }

@router.post("/analyze-sentiment")
def analyze_sentiment(
    message: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Analyze message sentiment"""
    ml_service = MLService(db)
    analysis = ml_service.analyze_sentiment(message)
    
    return analysis

@router.post("/train-models")
def train_models(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Train ML models on user's task data"""
    ml_service = MLService(db)
    result = ml_service.train_models(current_user.id)
    
    return result

@router.get("/suggestions")
def get_suggestions(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get AI-powered task suggestions"""
    ml_service = MLService(db)
    suggestions = ml_service.get_smart_suggestions(current_user.id)
    
    return suggestions