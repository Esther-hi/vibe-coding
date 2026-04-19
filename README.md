# 智能厨房助手

基于 LangChain + 通义千问的智能厨房助手 App，帮助用户识别食材、生成菜谱、管理购物清单。

---

## 功能特点

- **拍照识别食材** - 拍摄冰箱照片，自动识别里面的食材
- **智能菜谱推荐** - 根据已有食材推荐合适的菜谱
- **反向查询** - 输入菜名，查询所需食材清单
- **收藏管理** - 收藏喜欢的菜谱
- **购物清单** - 一键生成购物清单

---

## 技术栈

| 后端 | 前端 |
|------|------|
| Python 3.9+ | Flutter 3.0+ |
| FastAPI | Riverpod (状态管理) |
| LangChain | GoRouter (路由) |
| 通义千问 API | |
| SQLAlchemy | |

---

## 快速开始

### 一、后端启动步骤

#### 1. 进入后端目录

```bash
cd E:\Claude_cook\backend
```

#### 2. 创建虚拟环境

```bash
python -m venv venv
```

#### 3. 激活虚拟环境

```bash
# Windows
venv\Scripts\activate

# 激活成功后，终端前面会显示 (venv)
```

#### 4. 安装依赖

```bash
pip install -r requirements.txt
```

#### 5. 配置 API Key

```bash
# 复制环境变量模板
copy .env.example .env
```

编辑 `.env` 文件，填入你的通义千问 API Key：

```env
DASHSCOPE_API_KEY=sk-xxxxxxxxxxxxxxxx
```

**获取 API Key 方法：**
1. 访问 https://dashscope.console.aliyun.com/
2. 登录阿里云账号
3. 点击左侧「API-KEY 管理」
4. 点击「创建新的 API-KEY」

#### 6. 启动服务

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

启动成功后显示：
```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

#### 7. 验证服务

- 访问 http://localhost:8000 查看欢迎信息
- 访问 http://localhost:8000/docs 查看 API 文档

---

### 二、前端启动步骤

#### 1. 确保已安装 Flutter

```bash
flutter --version
```

如果未安装，请访问 https://flutter.dev/ 下载安装。

#### 2. 进入前端目录

```bash
cd E:\Claude_cook\app
```

#### 3. 安装依赖

```bash
flutter pub get
```

#### 4. 运行应用

```bash
flutter run
```

---

## 项目结构

```
E:\Claude_cook\
│
├── backend/                          # 后端代码
│   ├── main.py                       # FastAPI 入口
│   ├── requirements.txt              # Python 依赖
│   ├── .env.example                  # 环境变量模板
│   │
│   ├── core/                         # 核心模块
│   │   ├── config.py                 # 配置管理
│   │   └── security.py               # JWT 认证
│   │
│   ├── api/routes/                   # API 路由
│   │   ├── auth.py                   # 用户认证
│   │   ├── ingredients.py            # 食材识别
│   │   ├── recipes.py                # 菜谱相关
│   │   └── shopping_list.py          # 购物清单
│   │
│   ├── agents/                       # LangChain Agent
│   │   ├── kitchen_assistant_agent.py
│   │   └── tools/                    # Agent Tools
│   │
│   ├── models/                       # 数据库模型
│   │   ├── user.py
│   │   ├── recipe.py
│   │   └── ingredient.py
│   │
│   └── services/                     # 服务层
│       ├── vision_service.py         # 通义千问多模态
│       └── llm_service.py            # 文本生成
│
├── app/                              # Flutter 前端
│   ├── pubspec.yaml                  # Flutter 依赖
│   └── lib/
│       ├── main.dart                 # 应用入口
│       │
│       ├── core/                     # 核心配置
│       │   ├── router/               # 路由
│       │   └── theme/                # 主题
│       │
│       ├── data/                     # 数据层
│       │   ├── models/               # 数据模型
│       │   └── datasources/          # 数据源
│       │
│       └── presentation/             # UI 层
│           ├── screens/              # 页面
│           └── widgets/              # 组件
│
└── README.md
```

---

## API 接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/api/v1/auth/register` | POST | 用户注册 |
| `/api/v1/auth/login` | POST | 用户登录 |
| `/api/v1/ingredients/recognize` | POST | 拍照识别食材 |
| `/api/v1/recipes/generate` | POST | 生成菜谱推荐 |
| `/api/v1/recipes/search` | GET | 搜索菜谱 |
| `/api/v1/recipes/{id}/favorite` | POST | 收藏菜谱 |
| `/api/v1/shopping-list/generate` | POST | 生成购物清单 |

完整 API 文档：http://localhost:8000/docs

---

## 常见问题

### Q: pip install 很慢怎么办？

使用国内镜像：

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

### Q: 启动报错 "ModuleNotFoundError"？

确保已激活虚拟环境，并重新安装依赖：

```bash
venv\Scripts\activate
pip install -r requirements.txt
```

### Q: API Key 无效？

1. 确认 API Key 是否正确复制（无多余空格）
2. 确认阿里云账户是否已开通通义千问服务
3. 检查账户余额是否充足

---

## 后续规划

- [ ] 语音交互功能
- [ ] 火候识别
- [ ] 智能计时器
- [ ] 社区分享功能
- [ ] 营养追踪

---

## License

MIT
