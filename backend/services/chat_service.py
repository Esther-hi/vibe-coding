import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.chat_message import ChatMessage
from agents.kitchen_assistant_agent import KitchenAssistantAgent
from core.config import settings


class ChatService:
    def __init__(self):
        self.agent = KitchenAssistantAgent(api_key=settings.DASHSCOPE_API_KEY)

    async def chat(self, user_id: str, session_id: str, message: str, db: AsyncSession) -> str:
        # Save user message
        user_msg = ChatMessage(
            id=str(uuid.uuid4()),
            user_id=user_id,
            session_id=session_id,
            role="user",
            content=message,
        )
        db.add(user_msg)
        await db.commit()

        # Call agent
        result = await self.agent.process_request(message)
        response_text = result.get("result", "抱歉，我暂时无法回答这个问题。")

        # Save assistant message
        assistant_msg = ChatMessage(
            id=str(uuid.uuid4()),
            user_id=user_id,
            session_id=session_id,
            role="assistant",
            content=response_text,
        )
        db.add(assistant_msg)
        await db.commit()

        return response_text

    async def get_history(self, user_id: str, session_id: str, db: AsyncSession, limit: int = 20):
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.user_id == user_id, ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at.desc())
            .limit(limit)
        )
        messages = result.scalars().all()
        return list(reversed(messages))
