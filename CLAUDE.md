# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

智能厨房助手 (Smart Kitchen Assistant) — a mobile app that helps users identify ingredients from photos, generate recipe recommendations, and manage shopping lists. The core user flow: photo/manual ingredient input → recipe recommendation → shopping list → cooking guide.

## 技术栈

- **Backend**: Python 3.9+, FastAPI, SQLAlchemy (async + aiosqlite), LangChain, Alibaba DashScope (通义千问 qwen-vl-max for vision, qwen-turbo for text)
- **Frontend**: Flutter 3.0+, Riverpod (state management), GoRouter (routing), Dio (HTTP), Hive (local storage)
- **Database**: SQLite via aiosqlite (auto-created on startup, no migrations in use)

## 工作流程

当开始一个任务时，首先需要判断是小项目，还是中项目，还是大项目，必需根据不同的项目调用相关skill。否则，任务不进行。

### **小项目流程**

满足以下大部分条件时 走小项目流程

- 单人可完成
- 改动集中在 1 到 3 个文件
- 半天到 1 天内可完成
- 风险低
- 回滚成本低

默认调用

- `brainstorming`
- `systematic-debugging`
- `verification-before-completion`

默认不调用

- `writing-plans`
- `using-git-worktrees`
- `subagent-driven-development`
- `test-driven-development`
- `requesting-code-review`

执行要求

- 先澄清目标和边界
- 直接执行最小改动
- 完成前必须验证

### **中项目流程**

满足以下大部分条件时 走中项目流程

- 涉及多个模块
- 需要 2 到 5 天推进
- 需要阶段计划
- 有一定回归风险
- 需要和同事或产品对齐

默认调用

- `brainstorming`
- `writing-plans`
- `executing-plans`
- `requesting-code-review`
- `verification-before-completion`

按需调用

- `systematic-debugging`
- `test-driven-development`

执行要求

- 必须先写可执行 plan
- 必须分阶段推进
- 每一阶段结束后要做复核

### **大项目流程**

满足以下大部分条件时 走大项目流程

- 跨模块
- 跨团队
- 周期长
- 风险高
- 回滚成本高
- 需要并行推进

默认调用

- `brainstorming`
- `using-git-worktrees`
- `writing-plans`
- `subagent-driven-development`
- `test-driven-development`
- `requesting-code-review`
- `finishing-a-development-branch`
- `verification-before-completion`

执行要求

- 不允许跳过 plan
- 不允许跳过验证
- 不允许省略 review
- 并行推进时必须明确边界

### **流程升级规则**

如果任务执行过程中出现以下任一情况 要主动升级流程层级

- 改动范围扩大
- 风险明显升高
- 需要额外协作
- 需要隔离工作区
- 需要测试闭环

### **Done When**

任务只有在以下条件满足时 才能视为完成

- 目标已实现
- 没有突破任务边界
- 已给出验证证据
- 风险和未完成项已说明

如果没有验证证据 不能直接宣称完成

## Architecture

### Backend Structure

```
backend/
  main.py                  # FastAPI entry, CORS, lifespan (strips proxy env vars for DashScope)
  core/
    config.py              # Pydantic BaseSettings, loads from .env
    security.py            # JWT auth (HS256), bcrypt, falls back to "default_user" if no token
  api/routes/
    auth.py                # /register, /login, /me
    ingredients.py         # /recognize (image upload → qwen-vl-max), /history
    recipes.py             # /generate, /search (reverse lookup), /{id}, /favorites
    shopping_list.py       # /generate, /, /{id} (toggle/delete)
  services/
    vision_service.py      # DashScope MultiModalConversation (qwen-vl-max)
    llm_service.py         # DashScope Generation (qwen-turbo), _extract_json helper
  agents/                  # LangChain ReAct agent — NOT wired into routes
    kitchen_assistant_agent.py  # Intent classifier + dispatch (unused by routes)
    tools/                 # Three BaseTool wrappers around services (unused by routes)
  models/                  # SQLAlchemy models: User, Recipe, Favorite, Ingredient, RecognitionHistory, ShoppingListItem
  database/__init__.py     # Async engine, get_db dependency, init_db (create_all)
```

**Key architectural note**: Routes call `VisionService` and `LLMService` directly. The `agents/` layer exists as a LangChain abstraction but is not wired into any route — the agent executor returns `None` because Qwen lacks direct LangChain integration.

### Frontend Structure

```
app/lib/
  main.dart                # ProviderScope + MaterialApp.router
  core/
    config/api_config.dart # Base URL and endpoint constants
    router/app_router.dart # GoRouter flat route table
    theme/app_theme.dart   # Material 3, green primary, light/dark themes
  data/
    datasources/
      local/local_storage.dart      # Hive box for auth token persistence
      remote/api_client.dart        # Dio wrapper with Bearer token interceptor
    models/                         # ingredient.dart, recipe.dart, shopping_list_item.dart
    repositories/                   # auth, ingredient, recipe, shopping_list
  presentation/
    providers/                      # Riverpod StateNotifierProviders (auth, ingredient, recipe, shopping_list)
    screens/                        # auth, home, camera, ingredients, recipe, cooking, shopping_list, favorites, profile
    widgets/                        # recommendation_condition_dialog.dart
```

**Provider dependency chain**: `localStorageProvider` → `apiClientProvider` → repository providers → StateNotifierProviders.

### User Flow (Route Path)

`/login` → `/` (home) → `/ingredients/input` → `/ingredients/confirm` → `/recommendation-conditions` → `/recipes` → `/recipes/:id` → `/shopping-list` → `/cooking` → back to `/`

## Important Details

- Auth falls back to `"default_user"` when no JWT is provided (`auto_error=False`), so endpoints work without login during development.
- `main.py` strips all proxy environment variables on startup to avoid DashScope connectivity issues.
- LLM responses are parsed via regex JSON extraction (`\{[\s\S]*\}`) in both `vision_service.py` and `llm_service.py`.
- Database uses UUID strings as primary keys. Tables are auto-created on startup via `init_db()` — no Alembic migrations are actively used.
- Favorites and Profile screens are placeholder/empty-state only.
- The `prototype/v1-wireframe.html` is a standalone wireframe for the V1 UI.
- PRD is at `PRD_V1.0.md`.
