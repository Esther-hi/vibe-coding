from .auth import router as auth_router
from .ingredients import router as ingredients_router
from .recipes import router as recipes_router
from .shopping_list import router as shopping_list_router

# 为了方便导入，使用简单名称
auth = type('Module', (), {'router': auth_router})()
ingredients = type('Module', (), {'router': ingredients_router})()
recipes = type('Module', (), {'router': recipes_router})()
shopping_list = type('Module', (), {'router': shopping_list_router})()
