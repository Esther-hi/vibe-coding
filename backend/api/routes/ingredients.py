"""
食材识别路由
"""
from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import base64

from database import get_db
from models import RecognitionHistory
from core import get_current_user_id
from services.vision_service import VisionService

router = APIRouter()


# ============ Pydantic Schemas ============

class Ingredient(BaseModel):
    """食材模型"""
    name: str
    category: str
    estimated_quantity: str
    freshness: str
    confidence: float


class RecognitionResult(BaseModel):
    """识别结果"""
    recognition_id: str
    ingredients: List[Ingredient]
    storage_suggestions: str
    image_url: str


class RecognitionResponse(BaseModel):
    """识别响应"""
    success: bool
    data: RecognitionResult


# ============ API Routes ============

@router.post("/recognize", response_model=RecognitionResponse)
async def recognize_ingredients(
    file: UploadFile = File(...),
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    拍照识别食材

    上传图片，返回识别出的食材列表
    """
    # 读取图片
    image_data = await file.read()
    image_base64 = base64.b64encode(image_data).decode('utf-8')

    # 调用视觉服务识别食材
    vision_service = VisionService()
    try:
        result = await vision_service.recognize_ingredients(image_base64)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"食材识别失败: {str(e)}"
        )

    # 保存识别历史
    history = RecognitionHistory(
        user_id=user_id,
        image_url="",  # TODO: 上传到 OSS
        recognition_data=result
    )
    db.add(history)
    await db.commit()

    # 构建响应
    ingredients = [
        Ingredient(
            name=item.get("name", "未知"),
            category=item.get("category", "其他"),
            estimated_quantity=item.get("estimated_quantity", "未知"),
            freshness=item.get("freshness", "未知"),
            confidence=item.get("confidence", 0.0)
        )
        for item in result.get("ingredients", [])
    ]

    return RecognitionResponse(
        success=True,
        data=RecognitionResult(
            recognition_id=history.id,
            ingredients=ingredients,
            storage_suggestions=result.get("storage_suggestions", ""),
            image_url=history.image_url
        )
    )


@router.get("/history")
async def get_recognition_history(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """获取识别历史"""
    result = await db.execute(
        select(RecognitionHistory)
        .where(RecognitionHistory.user_id == user_id)
        .order_by(RecognitionHistory.created_at.desc())
        .limit(20)
    )
    history = result.scalars().all()

    return {
        "success": True,
        "data": history
    }
