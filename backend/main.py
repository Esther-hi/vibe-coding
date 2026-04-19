"""
智能厨房助手 - FastAPI 主入口
"""
import os
os.environ['NO_PROXY'] = '*'
os.environ.pop('HTTP_PROXY', None)
os.environ.pop('HTTPS_PROXY', None)
os.environ.pop('http_proxy', None)
os.environ.pop('https_proxy', None)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from core.config import settings
from api.routes import auth, ingredients, recipes, shopping_list
from api.routes.chat import router as chat_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时初始化数据库
    print("[启动] 智能厨房助手启动中...")
    from database import init_db
    await init_db()
    print("[完成] 数据库初始化完成")
    yield
    print("[关闭] 智能厨房助手已关闭")


app = FastAPI(
    title="智能厨房助手 API",
    description="基于 LangChain + 通义千问的智能厨房助手后端服务",
    version="1.0.0",
    lifespan=lifespan
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境需限制
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth.router, prefix=f"{settings.API_V1_PREFIX}/auth", tags=["认证"])
app.include_router(ingredients.router, prefix=f"{settings.API_V1_PREFIX}/ingredients", tags=["食材识别"])
app.include_router(recipes.router, prefix=f"{settings.API_V1_PREFIX}/recipes", tags=["菜谱"])
app.include_router(shopping_list.router, prefix=f"{settings.API_V1_PREFIX}/shopping-list", tags=["购物清单"])
app.include_router(chat_router, prefix=settings.API_V1_PREFIX + "/chat", tags=["chat"])


@app.get("/")
async def root():
    """根路径"""
    return {
        "message": "智能厨房助手 API",
        "docs": "/docs",
        "version": "1.0.0"
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
