from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import List, Optional

from app.database import get_db
from app.api.auth import get_current_user
from app.models.user import User
from app.services.nlu_service import ConversationService

router = APIRouter()

class ChatMessage(BaseModel):
    message: str

class ChatResponse(BaseModel):
    response: str
    intent: Optional[str] = None
    handled_by: Optional[str] = None
    suggestion: Optional[bool] = False

@router.post("/", response_model=ChatResponse)
def chat_with_assistant(
    chat_message: ChatMessage,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Chat with the AI assistant
    
    - Uses simple NLU for quick commands
    - Routes complex queries to Claude AI
    - Provides context-aware responses
    """
    conversation = ConversationService(db, current_user.id)
    result = conversation.process_message(chat_message.message)
    
    return ChatResponse(
        response=result.get('response', 'I could not process that request.'),
        intent=result.get('intent'),
        handled_by=result.get('handled_by'),
        suggestion=result.get('suggestion', False)
    )

@router.get("/health")
def chat_health():
    """Check chat service health"""
    import os
    gemini_available = bool(os.getenv("GEMINI_API_KEY"))
    
    return {
        "status": "healthy",
        "simple_nlu": "active",
        "gemini_ai": "active" if gemini_available else "fallback_mode",
        "version": "hybrid_v1.0_gemini"
    }

@router.get("/examples")
def get_example_queries():
    """Get example queries users can try"""
    return {
        "quick_commands": [
            "Create task finish report",
            "Show my tasks",
            "Complete presentation",
            "Show my stats",
            "Show overdue tasks",
            "Delete old task"
        ],
        "ai_powered": [
            "How should I approach my thesis project?",
            "Help me prioritize my tasks for this week",
            "Give me tips for better productivity",
            "What's the best way to tackle a large project?",
            "Suggest a strategy for managing deadlines"
        ]
    }