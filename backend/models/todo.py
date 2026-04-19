"""
待办清单模型
"""
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime, JSON
from database import Base


class TodoList(Base):
    """待办清单表"""
    __tablename__ = "todo_lists"

    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    recipe_names = Column(JSON, default=[])  # ["番茄炒蛋", "紫菜蛋花汤"]
    servings = Column(String, nullable=True)
    status = Column(String(20), default="pending")  # pending, shopping, completed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class TodoItem(Base):
    """待办清单项表"""
    __tablename__ = "todo_items"

    id = Column(String, primary_key=True)
    todo_list_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    ingredient_name = Column(String(100), nullable=False)
    quantity = Column(String(50), nullable=False)
    is_purchased = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
