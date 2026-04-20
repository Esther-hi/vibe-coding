"""
购物清单工具
"""
from langchain_classic.tools import BaseTool
from typing import Type, List
from pydantic import BaseModel, Field
import asyncio

from services.llm_service import LLMService


class ShoppingListInput(BaseModel):
    """购物清单工具输入模型"""
    recipe_name: str = Field(description="目标菜谱名称")
    missing_ingredients: List[dict] = Field(description="缺少的食材列表")
    available_ingredients: List[str] = Field(description="已有食材列表")


class ShoppingListTool(BaseTool):
    """购物清单生成工具"""

    name: str = "shopping_list"
    description: str = "根据菜谱和已有食材生成购物清单"
    args_schema: Type[BaseModel] = ShoppingListInput

    def __init__(self):
        super().__init__()
        self.llm_service = LLMService()

    def _run(
        self,
        recipe_name: str,
        missing_ingredients: List[dict],
        available_ingredients: List[str]
    ) -> str:
        """同步执行"""
        return asyncio.run(self._arun(recipe_name, missing_ingredients, available_ingredients))

    async def _arun(
        self,
        recipe_name: str,
        missing_ingredients: List[dict],
        available_ingredients: List[str]
    ) -> str:
        """异步执行购物清单生成"""
        result = await self.llm_service.generate_shopping_list(
            recipe_name=recipe_name,
            missing_ingredients=missing_ingredients,
            available_ingredients=available_ingredients
        )
        import json
        return json.dumps(result, ensure_ascii=False, indent=2)
