"""
短信验证码服务
"""
import random
import string
import uuid
from datetime import datetime, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.sms_code import SmsCode
from core.config import settings


class SmsService:
    def generate_code(self) -> str:
        return "".join(random.choices(string.digits, k=settings.SMS_CODE_LENGTH))

    async def send_code(self, phone: str, purpose: str, db: AsyncSession) -> str:
        now = datetime.utcnow()
        cutoff = now - timedelta(seconds=settings.SMS_CODE_RESEND_INTERVAL_SECONDS)

        result = await db.execute(
            select(SmsCode)
            .where(SmsCode.phone == phone, SmsCode.purpose == purpose, SmsCode.created_at > cutoff)
            .order_by(SmsCode.created_at.desc())
        )
        recent = result.scalars().first()
        if recent:
            raise ValueError("验证码发送过于频繁，请稍后再试")

        code = self.generate_code()
        sms_code = SmsCode(
            id=str(uuid.uuid4()),
            phone=phone,
            code=code,
            purpose=purpose,
            expires_at=now + timedelta(minutes=settings.SMS_CODE_EXPIRE_MINUTES),
        )
        db.add(sms_code)
        await db.commit()

        if not settings.SMS_ENABLED:
            print(f"[DEV] SMS code for {phone} ({purpose}): {code}")

        return code

    async def verify_code(self, phone: str, code: str, purpose: str, db: AsyncSession) -> bool:
        now = datetime.utcnow()
        result = await db.execute(
            select(SmsCode)
            .where(
                SmsCode.phone == phone,
                SmsCode.code == code,
                SmsCode.purpose == purpose,
                SmsCode.is_used == False,
                SmsCode.expires_at > now,
            )
            .order_by(SmsCode.created_at.desc())
        )
        sms_code = result.scalars().first()
        if not sms_code:
            return False
        sms_code.is_used = True
        await db.commit()
        return True
