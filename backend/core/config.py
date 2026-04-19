"""
应用配置管理
"""
from pydantic_settings import BaseSettings
from typing import Optional, List


class Settings(BaseSettings):
    """应用配置"""

    # 应用配置
    APP_NAME: str = "Kitchen Assistant"
    DEBUG: bool = True
    API_V1_PREFIX: str = "/api/v1"

    # 数据库配置 (使用 SQLite 本地开发)
    DATABASE_URL: str = "sqlite+aiosqlite:///./kitchen_assistant.db"

    # Redis 配置
    REDIS_URL: str = "redis://localhost:6379/0"

    # 阿里云通义千问配置
    DASHSCOPE_API_KEY: str = ""
    QWEN_VL_MODEL: str = "qwen-vl-max"
    QWEN_TEXT_MODEL: str = "qwen-turbo"

    # JWT 配置
    JWT_SECRET_KEY: str = "your-super-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_MINUTES: int = 60 * 24 * 7  # 7天

    # 文件上传配置
    MAX_IMAGE_SIZE: int = 10 * 1024 * 1024  # 10MB
    ALLOWED_IMAGE_TYPES: List[str] = ["image/jpeg", "image/png", "image/webp"]

    # 短信验证码配置
    SMS_CODE_LENGTH: int = 6
    SMS_CODE_EXPIRE_MINUTES: int = 5
    SMS_CODE_RESEND_INTERVAL_SECONDS: int = 60
    SMS_ENABLED: bool = False

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
