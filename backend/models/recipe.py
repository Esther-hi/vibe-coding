"""
菜谱模型
"""
from sqlalchemy import Column, String, Integer, Text, JSON, DateTime, ForeignKey
from datetime import datetime
from database import Base
import uuid


class Recipe(Base):
    """菜谱表"""
    __tablename__ = "recipes"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    difficulty = Column(String(20), default="简单")
    cooking_time = Column(Integer, default=0)
    cuisine = Column(String(50), nullable=True)
    servings = Column(String(20), nullable=True)
    ingredients_json = Column(JSON, default=[])
    missing_ingredients_json = Column(JSON, default=[])
    steps = Column(JSON, default=[])
    nutrition = Column(JSON, default={})
    tips = Column(Text, nullable=True)
    image_url = Column(String(500), nullable=True)
    user_id = Column(String, nullable=True)
    created_by = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Favorite(Base):
    """收藏表"""
    __tablename__ = "favorites"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    recipe_id = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
