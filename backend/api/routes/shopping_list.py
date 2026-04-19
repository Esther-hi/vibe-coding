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
from models.todo import TodoList, TodoItem
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


# --- Todo List endpoints ---

@router.get("/todo")
async def get_todo_lists(user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(TodoList).where(TodoList.user_id == user_id).order_by(TodoList.created_at.desc())
    )
    todo_lists = result.scalars().all()
    response = []
    for tl in todo_lists:
        items_result = await db.execute(select(TodoItem).where(TodoItem.todo_list_id == tl.id))
        items = items_result.scalars().all()
        response.append({
            "id": tl.id,
            "recipe_names": tl.recipe_names,
            "servings": tl.servings,
            "status": tl.status,
            "total_items": len(items),
            "pending_items": sum(1 for i in items if not i.is_purchased),
            "created_at": tl.created_at.isoformat() if tl.created_at else None,
        })
    return {"success": True, "data": response}


@router.get("/todo/{todo_id}")
async def get_todo_detail(todo_id: str, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TodoList).where(TodoList.id == todo_id, TodoList.user_id == user_id))
    todo = result.scalars().first()
    if not todo:
        raise HTTPException(status_code=404, detail="待办不存在")
    items_result = await db.execute(select(TodoItem).where(TodoItem.todo_list_id == todo_id))
    items = items_result.scalars().all()
    return {
        "success": True,
        "data": {
            "id": todo.id,
            "recipe_names": todo.recipe_names,
            "servings": todo.servings,
            "status": todo.status,
            "items": [
                {
                    "id": i.id,
                    "ingredient_name": i.ingredient_name,
                    "quantity": i.quantity,
                    "is_purchased": i.is_purchased,
                }
                for i in items
            ],
        },
    }


class TodoCreateRequest(BaseModel):
    recipe_names: list
    servings: str
    items: list


@router.post("/todo")
async def create_todo(
    request: TodoCreateRequest,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    import uuid
    todo_id = str(uuid.uuid4())
    todo = TodoList(
        id=todo_id,
        user_id=user_id,
        recipe_names=request.recipe_names,
        servings=request.servings,
        status="pending",
    )
    db.add(todo)
    for item in request.items:
        todo_item = TodoItem(
            id=str(uuid.uuid4()),
            todo_list_id=todo_id,
            user_id=user_id,
            ingredient_name=item["name"],
            quantity=item["quantity"],
        )
        db.add(todo_item)
    await db.commit()
    return {"success": True, "data": {"todo_id": todo_id}}


@router.put("/todo/{todo_id}/status")
async def update_todo_status(
    todo_id: str, status: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(TodoList).where(TodoList.id == todo_id, TodoList.user_id == user_id))
    todo = result.scalars().first()
    if not todo:
        raise HTTPException(status_code=404, detail="待办不存在")
    todo.status = status
    await db.commit()
    return {"success": True}


@router.put("/todo/item/{item_id}")
async def toggle_todo_item(
    item_id: str, is_purchased: bool = True,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(TodoItem).where(TodoItem.id == item_id, TodoItem.user_id == user_id))
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=404, detail="物品不存在")
    item.is_purchased = is_purchased
    await db.commit()
    return {"success": True}


@router.delete("/todo/{todo_id}")
async def delete_todo(
    todo_id: str,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(TodoList).where(TodoList.id == todo_id, TodoList.user_id == user_id))
    todo = result.scalars().first()
    if not todo:
        raise HTTPException(status_code=404, detail="待办不存在")
    items_result = await db.execute(select(TodoItem).where(TodoItem.todo_list_id == todo_id))
    for item in items_result.scalars().all():
        await db.delete(item)
    await db.delete(todo)
    await db.commit()
    return {"success": True}
