import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from dashscope import Generation
from models.chat_message import ChatMessage
from agents.kitchen_assistant_agent import KitchenAssistantAgent
from core.config import settings

CHAT_SYSTEM_PROMPT = "你是一个温暖、专业的美食助手。请用简洁友好的中文回答用户关于烹饪、食材、菜谱的问题。"


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

        # Try agent first
        response_text = None
        try:
            result = await self.agent.process_request(message)
            intent = result.get("intent")
            agent_result = result.get("result", "")

            # Agent succeeded and returned a real answer
            if intent != "error" and agent_result:
                response_text = agent_result
        except Exception:
            pass

        # Fallback: direct LLM call
        if not response_text:
            response_text = await self._direct_chat(message, db, user_id, session_id)

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

    async def _direct_chat(self, message: str, db: AsyncSession, user_id: str, session_id: str) -> str:
        """Fallback: 直接调用 DashScope Generation API"""
        history = await self._get_recent_history(db, user_id, session_id, limit=6)

        prompt_parts = [CHAT_SYSTEM_PROMPT, ""]
        for msg in history:
            if msg.role == "user":
                prompt_parts.append(f"用户：{msg.content}")
            elif msg.role == "assistant":
                prompt_parts.append(f"助手：{msg.content}")
        prompt_parts.append(f"用户：{message}")
        prompt_parts.append("助手：")
        prompt = "\n".join(prompt_parts)

        response = Generation.call(
            model=settings.QWEN_TEXT_MODEL,
            prompt=prompt,
            api_key=settings.DASHSCOPE_API_KEY,
            temperature=0.8,
            top_p=0.9,
            max_tokens=1500,
        )

        if response.status_code == 200:
            return response.output.text.strip()
        return "抱歉，我暂时无法回答这个问题，请稍后再试。"

    async def _get_recent_history(self, db: AsyncSession, user_id: str, session_id: str, limit: int = 6):
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.user_id == user_id, ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at.desc())
            .limit(limit)
        )
        messages = result.scalars().all()
        return list(reversed(messages))

    async def get_history(self, user_id: str, session_id: str, db: AsyncSession, limit: int = 20):
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.user_id == user_id, ChatMessage.session_id == session_id)
            .order_by(ChatMessage.created_at.desc())
            .limit(limit)
        )
        messages = result.scalars().all()
        return list(reversed(messages))
