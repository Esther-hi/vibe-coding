"""
菜谱路由
"""
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from database import get_db
from models import Recipe, Favorite
from core import get_current_user_id
from services.llm_service import LLMService

router = APIRouter()


# ============ Pydantic Schemas ============

class RecipeIngredient(BaseModel):
    """菜谱食材"""
    name: str
    quantity: str
    is_available: bool


class MissingIngredient(BaseModel):
    """缺失食材"""
    name: str
    quantity: str


class Nutrition(BaseModel):
    """营养信息"""
    calories: str
    protein: str
    carbs: str
    fat: str


class RecipeItem(BaseModel):
    """菜谱项"""
    name: str
    difficulty: str
    cooking_time: int
    cuisine: str
    servings: Optional[str] = None
    ingredients: List[RecipeIngredient]
    missing_ingredients: List[MissingIngredient]
    steps: List[str]
    nutrition: Nutrition
    tips: Optional[str] = None


class RecipeGenerationRequest(BaseModel):
    """菜谱生成请求"""
    ingredients: List[str]
    people_count: int = 2
    preferences: Optional[dict] = None
    count: int = 3


class RecipeGenerationResponse(BaseModel):
    """菜谱生成响应"""
    success: bool
    data: dict


# ============ API Routes ============

@router.post("/generate", response_model=RecipeGenerationResponse)
async def generate_recipes(
    request: RecipeGenerationRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """
    根据食材生成菜谱推荐

    输入可用食材列表和用餐人数，返回推荐的菜谱
    """
    llm_service = LLMService()

    try:
        result = await llm_service.generate_recipes(
            ingredients=request.ingredients,
            people_count=request.people_count,
            preferences=request.preferences,
            count=request.count
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"菜谱生成失败: {str(e)}"
        )

    # 持久化菜谱到数据库
    recipes_data = result.get("recipes", [])
    for recipe_data in recipes_data:
        recipe_id = str(uuid.uuid4())
        recipe = Recipe(
            id=recipe_id,
            name=recipe_data.get("name", ""),
            difficulty=recipe_data.get("difficulty", "简单"),
            cooking_time=recipe_data.get("cooking_time", 0),
            cuisine=recipe_data.get("cuisine", ""),
            servings=recipe_data.get("servings", ""),
            ingredients_json=recipe_data.get("ingredients", []),
            missing_ingredients_json=recipe_data.get("missing_ingredients", []),
            steps=recipe_data.get("steps", []),
            nutrition=recipe_data.get("nutrition", {}),
            tips=recipe_data.get("tips"),
            user_id=user_id,
        )
        db.add(recipe)
        recipe_data["id"] = recipe_id
    await db.commit()

    return RecipeGenerationResponse(
        success=True,
        data=result
    )


@router.get("/search")
async def search_recipes(
    query: str,
    user_id: str = Depends(get_current_user_id)
):
    """
    搜索菜谱（反向查询）

    输入菜名，返回食材清单和做法
    """
    llm_service = LLMService()

    try:
        result = await llm_service.search_recipe(query)
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"菜谱搜索失败: {str(e)}"
        )

    return {
        "success": True,
        "data": result
    }


@router.get("/favorites")
async def get_favorites(
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """获取收藏列表"""
    result = await db.execute(
        select(Favorite)
        .where(Favorite.user_id == user_id)
        .order_by(Favorite.created_at.desc())
    )
    favorites = result.scalars().all()

    return {
        "success": True,
        "data": favorites
    }


@router.get("/{recipe_id}")
async def get_recipe(
    recipe_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """获取菜谱详情"""
    result = await db.execute(
        select(Recipe).where(Recipe.id == recipe_id)
    )
    recipe = result.scalar_one_or_none()

    if not recipe:
        raise HTTPException(status_code=404, detail="菜谱不存在")

    return {
        "success": True,
        "data": {
            "id": recipe.id,
            "name": recipe.name,
            "difficulty": recipe.difficulty,
            "cooking_time": recipe.cooking_time,
            "cuisine": recipe.cuisine,
            "servings": recipe.servings,
            "ingredients": recipe.ingredients_json or [],
            "missing_ingredients": recipe.missing_ingredients_json or [],
            "steps": recipe.steps or [],
            "nutrition": recipe.nutrition or {},
            "tips": recipe.tips,
        }
    }


@router.post("/{recipe_id}/favorite")
async def favorite_recipe(
    recipe_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """收藏菜谱"""
    result = await db.execute(
        select(Favorite)
        .where(Favorite.user_id == user_id, Favorite.recipe_id == recipe_id)
    )
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=400,
            detail="已收藏该菜谱"
        )

    favorite = Favorite(user_id=user_id, recipe_id=recipe_id)
    db.add(favorite)
    await db.commit()

    return {"success": True, "message": "收藏成功"}


@router.delete("/{recipe_id}/favorite")
async def unfavorite_recipe(
    recipe_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db)
):
    """取消收藏"""
    result = await db.execute(
        select(Favorite)
        .where(Favorite.user_id == user_id, Favorite.recipe_id == recipe_id)
    )
    favorite = result.scalar_one_or_none()

    if not favorite:
        raise HTTPException(
            status_code=404,
            detail="未收藏该菜谱"
        )

    await db.delete(favorite)
    await db.commit()

    return {"success": True, "message": "取消收藏成功"}
