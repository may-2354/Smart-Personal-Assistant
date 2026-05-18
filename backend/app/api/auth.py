from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas.user import UserCreate, UserResponse, UserLogin
from app.schemas.auth import Token
from app.services.auth_service import AuthService
from app.utils.security import decode_access_token

router = APIRouter()

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """Dependency to get current authenticated user"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    payload = decode_access_token(token)
    if payload is None:
        raise credentials_exception
    
    email: str = payload.get("sub")
    if email is None:
        raise credentials_exception
    
    service = AuthService(db)
    user = service.get_current_user(email)
    return user

@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Register a new user"""
    service = AuthService(db)
    user = service.register_user(user_data)
    return user

@router.post("/login", response_model=Token)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login user and return JWT token (OAuth2 compatible)"""
    # OAuth2PasswordRequestForm uses 'username' field for email
    login_data = UserLogin(email=form_data.username, password=form_data.password)
    service = AuthService(db)
    token = service.login_user(login_data)
    return token

@router.post("/login-json", response_model=Token)
def login_json(login_data: UserLogin, db: Session = Depends(get_db)):
    """Login user and return JWT token (JSON body)"""
    service = AuthService(db)
    token = service.login_user(login_data)
    return token

@router.get("/me", response_model=UserResponse)
def get_me(current_user = Depends(get_current_user)):
    """Get current user information"""
    return current_user

@router.post("/logout")
def logout(current_user = Depends(get_current_user)):
    """Logout user (client should discard token)"""
    return {"message": "Successfully logged out"}