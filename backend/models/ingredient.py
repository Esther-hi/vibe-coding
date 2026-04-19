"""
食材和识别历史模型
"""
from sqlalchemy import Column, String, Boolean, DateTime, JSON
from datetime import datetime
from database import Base
import uuid


class Ingredient(Base):
    """食材表"""
    __tablename__ = "ingredients"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(100), unique=True, nullable=False, index=True)
    category = Column(String(50), nullable=False)
    default_unit = Column(String(20), nullable=True)
    nutrition_info = Column(JSON, nullable=True)
    image_url = Column(String(500), nullable=True)


class RecognitionHistory(Base):
    """识别历史表"""
    __tablename__ = "recognition_history"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    image_url = Column(String(500), nullable=True)
    recognition_data = Column(JSON, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class ShoppingListItem(Base):
    """购物清单项"""
    __tablename__ = "shopping_list_items"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=False)
    ingredient_name = Column(String(100), nullable=False)
    quantity = Column(String(50), nullable=False)
    estimated_price = Column(String(20), nullable=True)
    is_purchased = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
