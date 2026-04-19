from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from core.security import get_current_user_id
from services.chat_service import ChatService

router = APIRouter()


class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


@router.post("/")
async def chat(
    request: ChatRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    chat_service = ChatService()
    session_id = request.session_id or str(__import__("uuid").uuid4())
    response = await chat_service.chat(user_id, session_id, request.message, db)
    return {"success": True, "data": {"response": response, "session_id": session_id}}


@router.get("/history/{session_id}")
async def get_history(
    session_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    chat_service = ChatService()
    messages = await chat_service.get_history(user_id, session_id, db)
    return {
        "success": True,
        "data": [
            {"role": m.role, "content": m.content, "created_at": m.created_at.isoformat() if m.created_at else None}
            for m in messages
        ],
    }
