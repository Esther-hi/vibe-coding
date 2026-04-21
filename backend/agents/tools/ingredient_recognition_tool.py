"""
食材识别工具
"""
from langchain_classic.tools import BaseTool
from typing import Optional, Type
from pydantic import BaseModel, Field
import asyncio

from services.vision_service import VisionService


class IngredientRecognitionInput(BaseModel):
    """食材识别工具输入模型"""
    image_base64: str = Field(description="Base64 编码的图片数据")


class IngredientRecognitionTool(BaseTool):
    """食材识别工具 - 使用 qwen-vl-max 多模态模型"""

    name: str = "ingredient_recognition"
    description: str = "识别冰箱照片中的食材，返回食材列表、数量和新鲜度"
    args_schema: Type[BaseModel] = IngredientRecognitionInput

    def _run(self, image_base64: str) -> str:
        """同步执行食材识别"""
        return asyncio.run(self._arun(image_base64))

    async def _arun(self, image_base64: str) -> str:
        """异步执行食材识别"""
        vision_service = VisionService()
        result = await vision_service.recognize_ingredients(image_base64)
        import json
        return json.dumps(result, ensure_ascii=False, indent=2)
