"""
购物清单路由
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from models import ShoppingListItem
from core import get_current_user_id
from services.llm_service import LLMService

router = APIRouter()


# ============ Pydantic Schemas ============

class ShoppingListRequest(BaseModel):
    """购物清单请求"""
    recipe_name: str
    missing_ingredients: List[dict]
    available_ingredients: List[str]


class ShoppingItem(BaseModel):
    """购物项"""
    name: str
    quantity: str
    estimated_price: Optional[str] = None
    purchase_location: Optional[str] = None
    storage_tip: Optional[str] = None


class ShoppingListResponse(BaseModel):
    """购物清单响应"""
    success: bool
    data: dict


# ============ API Routes ============

@router.post("/generate", response_model=ShoppingListResponse)
async def generate_shopping_list(
    request: ShoppingListRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    生成购物清单

    根据缺少的食材生成购物清单
    """
    llm_service = LLMService()

    try:
        result = await llm_service.generate_shopping_list(
            recipe_name=request.recipe_name,
            missing_ingredients=request.missing_ingredients,
            available_ingredients=request.available_ingredients
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"购物清单生成失败: {str(e)}"
        )

    # 保存到数据库
    items = result.get("shopping_list", [])
    for item in items:
        list_item = ShoppingListItem(
            user_id=user_id,
            ingredient_name=item.get("name", ""),
            quantity=item.get("quantity", ""),
            estimated_price=item.get("estimated_price", "")
        )
        db.add(list_item)
    await db.commit()

    return ShoppingListResponse(
        success=True,
        data=result
    )


@router.get("/")
async def get_shopping_list(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """获取当前购物清单（全部，含已购买和未购买）"""
    result = await db.execute(
        select(ShoppingListItem)
        .where(ShoppingListItem.user_id == user_id)
        .order_by(ShoppingListItem.created_at.desc())
    )
    items = result.scalars().all()

    return {
        "success": True,
        "data": items
    }


@router.put("/{item_id}")
async def update_shopping_item(
    item_id: str,
    is_purchased: bool = True,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """更新购物项状态"""
    result = await db.execute(
        select(ShoppingListItem)
        .where(ShoppingListItem.id == item_id, ShoppingListItem.user_id == user_id)
    )
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(
            status_code=404,
            detail="购物项不存在"
        )

    item.is_purchased = is_purchased
    await db.commit()

    return {"success": True, "message": "更新成功"}


@router.delete("/{item_id}")
async def delete_shopping_item(
    item_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """删除购物项"""
    result = await db.execute(
        select(ShoppingListItem)
        .where(ShoppingListItem.id == item_id, ShoppingListItem.user_id == user_id)
    )
    item = result.scalar_one_or_none()

    if not item:
        raise HTTPException(
            status_code=404,
            detail="购物项不存在"
        )

    await db.delete(item)
    await db.commit()

    return {"success": True, "message": "删除成功"}
