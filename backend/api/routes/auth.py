from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from pydantic import BaseModel, EmailStr
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from models.user import User
from core.security import (
    verify_password, get_password_hash, create_access_token, get_current_user_id
)
from services.sms_service import SmsService

router = APIRouter()


# Schemas
class SendCodeRequest(BaseModel):
    phone: str
    purpose: str = "register"


class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    new_password: str


class UserRegister(BaseModel):
    username: str
    phone: str
    code: str
    password: str
    email: Optional[EmailStr] = None


class UserLogin(BaseModel):
    username: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    code: Optional[str] = None


class UserResponse(BaseModel):
    id: str
    username: str
    email: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None

    class Config:
        from_attributes = True


@router.post("/send-code")
async def send_code(request: SendCodeRequest, db: AsyncSession = Depends(get_db)):
    sms_service = SmsService()
    try:
        await sms_service.send_code(request.phone, request.purpose, db)
    except ValueError as e:
        raise HTTPException(status_code=429, detail=str(e))
    return {"success": True, "message": "验证码已发送"}


@router.post("/register")
async def register(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    sms_service = SmsService()
    if not await sms_service.verify_code(user_data.phone, user_data.code, "register", db):
        raise HTTPException(status_code=400, detail="验证码无效或已过期")

    existing = await db.execute(select(User).where(User.username == user_data.username))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="用户名已存在")

    existing_phone = await db.execute(select(User).where(User.phone == user_data.phone))
    if existing_phone.scalars().first():
        raise HTTPException(status_code=400, detail="手机号已注册")

    user = User(
        username=user_data.username,
        phone=user_data.phone,
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)


@router.post("/login")
async def login(user_data: UserLogin, db: AsyncSession = Depends(get_db)):
    user = None

    if user_data.phone and user_data.code:
        sms_service = SmsService()
        if not await sms_service.verify_code(user_data.phone, user_data.code, "login", db):
            raise HTTPException(status_code=401, detail="验证码无效或已过期")
        result = await db.execute(select(User).where(User.phone == user_data.phone))
        user = result.scalars().first()
        if not user:
            raise HTTPException(status_code=401, detail="用户不存在")

    elif user_data.username and user_data.password:
        result = await db.execute(
            select(User).where(
                (User.username == user_data.username) | (User.phone == user_data.username)
            )
        )
        user = result.scalars().first()
        if not user or not verify_password(user_data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="用户名或密码错误")

    else:
        raise HTTPException(status_code=400, detail="请提供登录凭证")

    access_token = create_access_token(data={"sub": user.id})
    return {"access_token": access_token}


@router.get("/me")
async def get_current_user(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")
    return UserResponse.model_validate(user)


@router.post("/reset-password")
async def reset_password(request: ResetPasswordRequest, db: AsyncSession = Depends(get_db)):
    sms_service = SmsService()
    if not await sms_service.verify_code(request.phone, request.code, "reset_password", db):
        raise HTTPException(status_code=400, detail="验证码无效或已过期")

    result = await db.execute(select(User).where(User.phone == request.phone))
    user = result.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="用户不存在")

    user.password_hash = get_password_hash(request.new_password)
    await db.commit()
    return {"success": True, "message": "密码重置成功"}
