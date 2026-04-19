"""
短信验证码模型
"""
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime
from database import Base


class SmsCode(Base):
    """短信验证码表"""
    __tablename__ = "sms_codes"

    id = Column(String, primary_key=True)
    phone = Column(String(20), nullable=False, index=True)
    code = Column(String(6), nullable=False)
    purpose = Column(String(20), nullable=False)  # "register", "login", "reset_password"
    is_used = Column(Boolean, default=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
