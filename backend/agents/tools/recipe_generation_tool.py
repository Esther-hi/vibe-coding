"""
菜谱生成工具
"""
from langchain.tools import BaseTool
from typing import Optional, Type, List
from pydantic import BaseModel, Field
import asyncio

from services.llm_service import LLMService


class RecipeGenerationInput(BaseModel):
    """菜谱生成工具输入模型"""
    ingredients: List[str] = Field(description="可用食材列表")
    preferences: Optional[dict] = Field(default=None, description="用户偏好")
    count: int = Field(default=3, description="推荐菜谱数量")


class RecipeGenerationTool(BaseTool):
    """菜谱生成工具"""

    name = "recipe_generation"
    description = "根据可用食材和用户偏好生成菜谱推荐"
    args_schema: Type[BaseModel] = RecipeGenerationInput

    def __init__(self):
        super().__init__()
        self.llm_service = LLMService()

    def _run(
        self,
        ingredients: List[str],
        preferences: dict = None,
        count: int = 3
    ) -> str:
        """同步执行"""
        return asyncio.run(self._arun(ingredients, preferences, count))

    async def _arun(
        self,
        ingredients: List[str],
        preferences: dict = None,
        count: int = 3
    ) -> str:
        """异步执行菜谱生成"""
        result = await self.llm_service.generate_recipes(
            ingredients=ingredients,
            preferences=preferences,
            count=count
        )
        import json
        return json.dumps(result, ensure_ascii=False, indent=2)
