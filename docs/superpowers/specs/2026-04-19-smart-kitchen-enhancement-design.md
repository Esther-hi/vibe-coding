# 智能厨房助手 — 功能增强 & 前端设计升级设计文档

日期: 2026-04-19

## 概述

对智能厨房助手项目进行全面增强，分三个阶段推进：先补全功能、再加新功能、最后统一升级UI风格。

推进策略：**功能先行**，最后统一UI。

---

## Phase 1: 补全现有功能

### 1.1 登录/注册系统重构

**注册页** — 单一表单，所有字段必填：
- 用户名
- 手机号（+86前缀）
- 短信验证码
- 密码
- 确认密码

手机号用于后续密码找回，注册时必须验证。

**登录页** — 双模式切换（Tab切换）：
- 验证码登录：手机号 + 短信验证码
- 密码登录：用户名/手机号 + 密码

**忘记密码页**：
- 输入注册手机号
- 获取验证码验证身份
- 设置新密码

**后端改动**：
- 修改 User 模型，增加 phone 字段（唯一约束）
- 新增 `SmsCode` 模型（存储验证码，带过期时间和用途标记）
- 新增 `/auth/send-code` 接口（发送短信验证码）
- 新增 `/auth/verify-code` 接口（验证验证码）
- 修改 `/auth/register` 接口，接受 username + phone + code + password
- 修改 `/auth/login` 接口，支持 username/phone + password 或 phone + code 两种模式
- 新增 `/auth/reset-password` 接口（手机号验证码重置密码）
- 验证码存储：SQLite 表（6位数字码，5分钟过期，1分钟内不可重发）

**短信发送方案**：
- 开发阶段：仅存储验证码到数据库，日志打印验证码，不实际发送短信
- 生产阶段：接入阿里云短信服务（SMS）

### 1.2 底部导航重构

将首页改为底部三Tab导航（BottomNavigationBar），替代当前右上角头像入口：
- **搜索/首页** Tab — 当前首页内容
- **待办** Tab — 新增的采购待办页面
- **我的** Tab — 个人中心页面

移除首页AppBar中的头像图标入口。

**路由改动**：
- 使用 `StatefulShellRoute` 包裹底部导航
- Tab切换不触发路由变化，仅在 Tab 内部页面切换时变化路由

### 1.3 个人中心完善

**我的页面展示**：
- 用户头像 + 用户名
- 手机号（脱敏显示，如 138****1234）
- 功能入口列表：
  - 口味偏好设置
  - 识别历史 → 新页面，展示 `/ingredients/history` 数据（含食材名称、识别时间）
  - 收藏菜谱 → 复用收藏页面
  - 通知设置（placeholder）
  - 帮助中心（placeholder）
  - 关于我们
- 退出登录按钮 → 调用 `authProvider.logout()`，清除本地 token，跳转登录页

**Auth 集成修复**：
- 登录成功后调用 `/auth/me` 获取用户信息
- AuthState 增加 phone 字段
- 所有用户信息持久化到 Hive

### 1.4 收藏系统

**菜谱详情页**：
- 右上角添加心形收藏按钮
- 调用 `POST/DELETE /recipes/{id}/favorite` 切换收藏状态
- 收藏状态在 provider 中管理

**收藏页面**：
- 展示收藏菜谱列表（卡片形式，含菜谱名、份量、时间、难度）
- 点击进入菜谱详情
- 空状态：心形图标 + "暂无收藏"
- 从个人中心入口进入

### 1.5 购物清单增强 + 待办系统

**购物清单页改动** — 底部双按钮：
- **加入待办** — 将当前购物清单保存到待办列表，返回首页，显示SnackBar提示"已加入待办，可在待办页面查看"
- **开始采购** — 进入采购流程（当前已有的勾选流程），全部采购完成后进入烹饪

**新增待办页面（Todo Tab）**：
- 展示所有待办采购项，每项显示：菜谱名、份量、食材数量/待购买数量、状态标签（待采购/采购中）
- 操作按钮：继续采购（进入对应购物清单）、删除
- 待办为空时显示引导文字

**后端改动**：
- 新增 `TodoList` 和 `TodoItem` 模型
- 新增 `/shopping-list/todo` 相关 CRUD 端点
- 修改购物清单生成逻辑，支持多菜谱合并

### 1.6 推荐页多选菜谱

**菜谱推荐列表页改动**：
- 每张菜谱卡片增加复选框
- 支持多选（默认选中第一道）
- 底部显示已选数量和提示"缺失食材将合并到购物清单"
- 按钮文案改为"查看详情并生成购物清单"
- 选中单道菜时保持原有流程（进入详情页）
- 选中多道菜时，进入合并购物清单页

---

## Phase 2: 新功能

### 2.1 步骤计时器

**烹饪页改动**：
- 后端 `llm_service.py` 的 recipe generation prompt 增加指令：在步骤中包含明确时间标记，格式如 `[timer:3m]`
- 前端解析步骤文本中的时间标记，在对应步骤旁显示 ⏱ 时钟按钮

**计时器交互**：
- 点击 ⏱ 按钮展开圆形倒计时面板（底部Sheet或页面内展开）
- 显示：圆形进度环 + 倒计时数字 + 步骤描述
- 操作：暂停/继续、取消
- 计时结束：声音提示 + 弹窗提醒"这一步完成啦！"
- 支持同时运行多个计时器

### 2.2 全局AI美食助手（LangChain Agent）

**架构决策**：采用方案B — 主流程（拍照→推荐→购物→烹饪）仍直接调用 Service，AI 助手聊天走 LangChain ReAct Agent。

**入口**：
- 首页右下角悬浮按钮（FAB）
- 所有页面均可访问（放在底部导航之上的层级）

**对话页面**：
- 全屏聊天界面
- 顶部：标题"美食助手" + AI标识
- 消息气泡：AI消息（浅色背景左侧）+ 用户消息（主色背景右侧）
- 底部：输入框 + 发送按钮

**Agent 架构**：
```
用户输入 → ChatTongyi (qwen-turbo) → ReAct Agent → Tools
                                                    ├─ IngredientRecognitionTool（食材知识查询）
                                                    ├─ RecipeGenerationTool（菜谱推荐）
                                                    └─ ShoppingListTool（购物建议）
```

**Agent 实现要点**：
- 升级 langchain 依赖至 0.3+ 版本
- 使用 `ChatTongyi`（from langchain_community.chat_models）替代之前返回 None 的写法
- 修复 `_create_agent()` 方法，构建真正的 AgentExecutor
- Agent Tools 调用已有的 VisionService 和 LLMService
- 支持多轮对话上下文（会话历史存 SQLite）

**后端改动**：
- 升级 `requirements.txt` 中 langchain 相关依赖版本
- 重写 `kitchen_assistant_agent.py` 的 `_create_agent()` 方法
- 新增 `/api/v1/chat` 路由，调用 Agent
- 新增 `ChatMessage` 模型存储对话历史
- Tools 与现有 Service 层对接

---

## Phase 3: UI设计升级

### 3.1 设计风格：中度手绘 + 温暖厨房感

**使用 `frontend-design` skill 实现前端设计。**

**色彩体系**：
- Primary: `#E8734A`（温暖橙）
- Warm: `#F4A261`（暖黄）
- Deep: `#C1440E`（深棕橙）
- Surface: `#FFF8F0`（奶油白背景）
- Card: `#FEF3E2`（浅米色卡片）
- Text: `#3D2C2C`（深棕色文字）
- Secondary Text: `#8B7355`（棕灰色）
- Success: `#2A9D8F`（青绿）
- Accent: `#E76F51`（珊瑚红）

**手绘风格元素（中度）**：
- 描边按钮（2px solid border, 大圆角 16-24px）
- 卡片使用大圆角（18-24px）+ 浅描边
- 输入框使用手绘风格圆角
- 使用 emoji 作为图标基础，减少标准 icon 依赖
- 标题加粗增加手绘质感
- 卡片阴影使用柔和扩散

**交互动效**：
- 按钮点击：弹性缓动曲线（Curves.elasticOut）
- 卡片出现：从下方滑入 + 渐显
- 页面转场：淡入淡出 + 轻微上移（像翻开食谱本）
- 完成烹饪/收藏时：小星星粒子庆祝效果
- 计时器：圆形进度环动画

### 3.2 深色模式

适配深色模式：
- Surface: `#1A1512`（深棕黑）
- Card: `#2D2420`（深棕）
- Text: `#F5EDE4`（暖白）
- 保持温暖色调，不使用纯黑/纯白

---

## 文件影响范围

### 后端新增/修改
- `models/` — 新增 TodoList, TodoItem, ChatMessage, SmsCode 模型；User 增加 phone 字段
- `api/routes/auth.py` — 新增 send-code, verify-code, reset-password 端点
- `api/routes/chat.py` — 新增 AI 对话端点（走 LangChain Agent）
- `api/routes/shopping_list.py` — 新增待办相关端点
- `agents/kitchen_assistant_agent.py` — 修复 _create_agent()，接入 ChatTongyi
- `services/llm_service.py` — 修改 recipe prompt 增加计时标记
- `database/__init__.py` — 新表初始化
- `requirements.txt` — 升级 langchain 依赖

### 前端新增/修改
- `core/theme/app_theme.dart` — 全新主题（色彩、圆角、描边风格）
- `core/router/app_router.dart` — StatefulShellRoute + 新路由
- `data/models/` — 新增 todo, chat 模型
- `data/datasources/remote/api_client.dart` — 新增 API 端点
- `data/repositories/` — 新增 chat, todo 仓库
- `presentation/providers/` — 新增 chat, todo, favorites provider
- `presentation/screens/auth/` — 重构登录/注册页
- `presentation/screens/home/` — 移除右上角头像，适配底部导航
- `presentation/screens/todo/` — 新增待办页面
- `presentation/screens/profile/` — 完善个人中心
- `presentation/screens/favorites/` — 完善收藏页面
- `presentation/screens/recipe/` — 多选菜谱 + 合并购物清单
- `presentation/screens/shopping_list/` — 双按钮 + 待办集成
- `presentation/screens/cooking/` — 步骤计时器
- `presentation/screens/chat/` — 新增AI助手对话页
- `presentation/widgets/` — 计时器组件、底部导航组件

---

## 实施顺序

按 Phase 1 → Phase 2 → Phase 3 顺序推进。

**Phase 1（约5-7天）**：
1. 后端模型 + 数据库变更（User.phone, TodoList, TodoItem, SmsCode）
2. 登录/注册重构（后端+前端）
3. 底部导航 + 路由重构
4. 个人中心完善
5. 收藏系统
6. 多选菜谱 + 购物清单增强 + 待办系统

**Phase 2（约3-5天）**：
1. 升级 LangChain 依赖 + 修复 Agent
2. 步骤计时器（后端prompt修改 + 前端计时器组件）
3. 全局AI美食助手（Agent接入 + 对话路由 + 前端对话页）

**Phase 3（约3-5天）**：
1. 主题系统重构（色彩、圆角、描边）
2. 全页面UI统一升级（使用 frontend-design skill）
3. 交互动效添加
4. 深色模式适配
