# Smart Kitchen Assistant Enhancement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enhance the Smart Kitchen Assistant with new features (auth, todo, multi-select recipes, timer, AI assistant) and upgrade the UI to a hand-drawn warm kitchen style.

**Architecture:** Three-phase approach: (1) Complete existing features — auth, nav, profile, favorites, shopping list todo, multi-select recipes; (2) Add new features — step timer, AI chat assistant via LangChain Agent; (3) Upgrade UI to hand-drawn warm style using `frontend-design` skill. Backend is FastAPI + SQLAlchemy async + DashScope. Frontend is Flutter + Riverpod + GoRouter.

**Tech Stack:** Python 3.9+, FastAPI, SQLAlchemy (async + aiosqlite), DashScope (qwen-vl-max, qwen-turbo), LangChain 0.3+, Flutter 3.0+, Riverpod, GoRouter, Dio, Hive

**Spec:** `docs/superpowers/specs/2026-04-19-smart-kitchen-enhancement-design.md`

---

## File Structure

### Backend — New Files
- `backend/models/sms_code.py` — SMS verification code model
- `backend/models/todo.py` — TodoList + TodoItem models
- `backend/models/chat_message.py` — Chat message model for AI assistant
- `backend/api/routes/chat.py` — AI assistant chat endpoint
- `backend/services/sms_service.py` — SMS verification code service
- `backend/services/chat_service.py` — Chat service wrapping LangChain Agent

### Backend — Modified Files
- `backend/models/user.py` — Add `phone` field
- `backend/models/__init__.py` — Export new models
- `backend/api/routes/auth.py` — New endpoints: send-code, verify-code, reset-password; modify register/login
- `backend/api/routes/shopping_list.py` — Add todo CRUD endpoints
- `backend/api/routes/recipes.py` — Modify generate to support timer markers in steps
- `backend/services/llm_service.py` — Update recipe prompt to include `[timer:Xm]` markers
- `backend/agents/kitchen_assistant_agent.py` — Fix `_create_agent()` with ChatTongyi
- `backend/database/__init__.py` — Ensure new models registered
- `backend/requirements.txt` — Upgrade langchain to 0.3+
- `backend/core/config.py` — Add SMS-related settings

### Frontend — New Files
- `app/lib/core/widgets/bottom_nav_shell.dart` — Shell widget with BottomNavigationBar
- `app/lib/data/models/todo.dart` — TodoList + TodoItem models
- `app/lib/data/models/chat_message.dart` — Chat message model
- `app/lib/data/repositories/todo_repository.dart` — Todo API calls
- `app/lib/data/repositories/chat_repository.dart` — Chat API calls
- `app/lib/presentation/providers/todo_provider.dart` — Todo state management
- `app/lib/presentation/providers/chat_provider.dart` — Chat state management
- `app/lib/presentation/providers/favorites_provider.dart` — Favorites state management
- `app/lib/presentation/screens/todo/todo_screen.dart` — Todo tab page
- `app/lib/presentation/screens/chat/chat_screen.dart` — AI assistant chat page
- `app/lib/presentation/widgets/timer_widget.dart` — Circular countdown timer

### Frontend — Modified Files
- `app/lib/core/router/app_router.dart` — StatefulShellRoute + new routes
- `app/lib/core/theme/app_theme.dart` — New warm color scheme + hand-drawn style
- `app/lib/core/config/api_config.dart` — New API endpoints
- `app/lib/data/datasources/local/local_storage.dart` — Implement saveUserData/getUserData
- `app/lib/data/datasources/remote/api_client.dart` — Add new HTTP methods if needed
- `app/lib/data/models/recipe.dart` — Add timer info to steps
- `app/lib/data/repositories/auth_repository.dart` — New auth methods (send-code, phone login, reset)
- `app/lib/presentation/providers/auth_provider.dart` — Add phone, fix user data loading
- `app/lib/presentation/providers/recipe_provider.dart` — Multi-select support
- `app/lib/presentation/providers/shopping_list_provider.dart` — Todo integration
- `app/lib/presentation/screens/auth/login_screen.dart` — Dual-mode login/register with phone
- `app/lib/presentation/screens/home/home_screen.dart` — Remove profile icon, add FAB for AI assistant
- `app/lib/presentation/screens/profile/profile_screen.dart` — Full implementation with real data
- `app/lib/presentation/screens/favorites/favorites_screen.dart` — Full implementation
- `app/lib/presentation/screens/recipe/recipe_list_screen.dart` — Multi-select checkboxes
- `app/lib/presentation/screens/recipe/recipe_detail_screen.dart` — Favorite button
- `app/lib/presentation/screens/shopping_list/shopping_list_screen.dart` — Dual buttons (todo/start)
- `app/lib/presentation/screens/cooking/cooking_screen.dart` — Timer integration
- `app/lib/main.dart` — No change needed (router handles shell)

---

## Phase 1: Complete Existing Features

### Task 1: Backend — Add phone to User model + SmsCode model

**Files:**
- Modify: `backend/models/user.py`
- Create: `backend/models/sms_code.py`
- Modify: `backend/models/__init__.py`

- [ ] **Step 1: Add `phone` field to User model**

In `backend/models/user.py`, add after the `email` field:

```python
phone = Column(String(20), unique=True, nullable=True, index=True)
```

Make `email` nullable (change `nullable=False` to `nullable=True`) since phone is now the primary contact.

- [ ] **Step 2: Create SmsCode model**

Create `backend/models/sms_code.py`:

```python
from datetime import datetime
from sqlalchemy import Column, String, Boolean, DateTime
from database import Base


class SmsCode(Base):
    __tablename__ = "sms_codes"

    id = Column(String, primary_key=True)
    phone = Column(String(20), nullable=False, index=True)
    code = Column(String(6), nullable=False)
    purpose = Column(String(20), nullable=False)  # "register", "login", "reset_password"
    is_used = Column(Boolean, default=False)
    expires_at = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 3: Register new model in `__init__.py`**

In `backend/models/__init__.py`, add imports:

```python
from .sms_code import SmsCode
from .todo import TodoList, TodoItem
from .chat_message import ChatMessage

__all__ = [
    "User", "Recipe", "Favorite", "Ingredient",
    "RecognitionHistory", "ShoppingListItem",
    "SmsCode", "TodoList", "TodoItem", "ChatMessage",
]
```

- [ ] **Step 4: Verify database init picks up new models**

In `backend/database/__init__.py`, confirm that `init_db()` imports all models before `create_all`. Add at top:

```python
import models  # noqa: F401 — ensures all models are registered with Base
```

- [ ] **Step 5: Commit**

```bash
git add backend/models/user.py backend/models/sms_code.py backend/models/__init__.py backend/database/__init__.py
git commit -m "feat: add phone field to User, create SmsCode model"
```

---

### Task 2: Backend — SMS verification service

**Files:**
- Create: `backend/services/sms_service.py`
- Modify: `backend/core/config.py`

- [ ] **Step 1: Add SMS config settings**

In `backend/core/config.py`, add to the `Settings` class:

```python
SMS_CODE_LENGTH: int = 6
SMS_CODE_EXPIRE_MINUTES: int = 5
SMS_CODE_RESEND_INTERVAL_SECONDS: int = 60
SMS_ENABLED: bool = False  # Set True when integrating real SMS provider
```

- [ ] **Step 2: Create SMS service**

Create `backend/services/sms_service.py`:

```python
import random
import string
from datetime import datetime, timedelta
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from models.sms_code import SmsCode
from core.config import settings


class SmsService:
    def generate_code(self) -> str:
        return "".join(random.choices(string.digits, k=settings.SMS_CODE_LENGTH))

    async def send_code(self, phone: str, purpose: str, db: AsyncSession) -> str:
        now = datetime.utcnow()
        cutoff = now - timedelta(seconds=settings.SMS_CODE_RESEND_INTERVAL_SECONDS)

        result = await db.execute(
            select(SmsCode)
            .where(SmsCode.phone == phone, SmsCode.purpose == purpose, SmsCode.created_at > cutoff)
            .order_by(SmsCode.created_at.desc())
        )
        recent = result.scalars().first()
        if recent:
            raise ValueError("验证码发送过于频繁，请稍后再试")

        code = self.generate_code()
        sms_code = SmsCode(
            id=str(__import__("uuid").uuid4()),
            phone=phone,
            code=code,
            purpose=purpose,
            expires_at=now + timedelta(minutes=settings.SMS_CODE_EXPIRE_MINUTES),
        )
        db.add(sms_code)
        await db.commit()

        if not settings.SMS_ENABLED:
            print(f"[DEV] SMS code for {phone} ({purpose}): {code}")

        return code

    async def verify_code(self, phone: str, code: str, purpose: str, db: AsyncSession) -> bool:
        now = datetime.utcnow()
        result = await db.execute(
            select(SmsCode)
            .where(
                SmsCode.phone == phone,
                SmsCode.code == code,
                SmsCode.purpose == purpose,
                SmsCode.is_used == False,
                SmsCode.expires_at > now,
            )
            .order_by(SmsCode.created_at.desc())
        )
        sms_code = result.scalars().first()
        if not sms_code:
            return False
        sms_code.is_used = True
        await db.commit()
        return True
```

- [ ] **Step 3: Commit**

```bash
git add backend/services/sms_service.py backend/core/config.py
git commit -m "feat: add SMS verification code service"
```

---

### Task 3: Backend — Refactor auth routes for phone + password

**Files:**
- Modify: `backend/api/routes/auth.py`

- [ ] **Step 1: Update Pydantic schemas and add new endpoints**

Replace the schemas and add new endpoints. The key changes:
- `UserRegister` schema: add `phone`, `code` fields; make `email` optional
- `UserLogin` schema: add optional `phone`, `code` fields for SMS login
- New schema: `SendCodeRequest` with `phone` and `purpose`
- New schema: `ResetPasswordRequest` with `phone`, `code`, `new_password`
- New endpoint: `POST /send-code`
- New endpoint: `POST /reset-password`
- Modify `/register` to verify SMS code and store phone
- Modify `/login` to support both password and SMS code login
- Modify `/me` to include `phone` in response

Key code for new schemas:

```python
class SendCodeRequest(BaseModel):
    phone: str
    purpose: str = "register"  # register, login, reset_password

class UserRegister(BaseModel):
    username: str
    phone: str
    code: str
    password: str
    email: Optional[EmailStr] = None

class UserLogin(BaseModel):
    username: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    code: Optional[str] = None

class ResetPasswordRequest(BaseModel):
    phone: str
    code: str
    new_password: str

class UserResponse(BaseModel):
    id: str
    username: str
    email: Optional[str] = None
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    class Config:
        from_attributes = True
```

Key code for `/send-code`:

```python
@router.post("/send-code")
async def send_code(request: SendCodeRequest, db: AsyncSession = Depends(get_db)):
    sms_service = SmsService()
    try:
        await sms_service.send_code(request.phone, request.purpose, db)
    except ValueError as e:
        raise HTTPException(status_code=429, detail=str(e))
    return {"success": True, "message": "验证码已发送"}
```

Key code for modified `/register`:

```python
@router.post("/register")
async def register(user_data: UserRegister, db: AsyncSession = Depends(get_db)):
    sms_service = SmsService()
    if not await sms_service.verify_code(user_data.phone, user_data.code, "register", db):
        raise HTTPException(status_code=400, detail="验证码无效或已过期")

    existing = await db.execute(select(User).where(User.username == user_data.username))
    if existing.scalars().first():
        raise HTTPException(status_code=400, detail="用户名已存在")

    existing_phone = await db.execute(select(User).where(User.phone == user_data.phone))
    if existing_phone.scalars().first():
        raise HTTPException(status_code=400, detail="手机号已注册")

    user = User(
        username=user_data.username,
        phone=user_data.phone,
        email=user_data.email,
        password_hash=get_password_hash(user_data.password),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return UserResponse.model_validate(user)
```

Key code for modified `/login`:

```python
@router.post("/login")
async def login(user_data: UserLogin, db: AsyncSession = Depends(get_db)):
    user = None

    if user_data.phone and user_data.code:
        # SMS code login
        sms_service = SmsService()
        if not await sms_service.verify_code(user_data.phone, user_data.code, "login", db):
            raise HTTPException(status_code=401, detail="验证码无效或已过期")
        result = await db.execute(select(User).where(User.phone == user_data.phone))
        user = result.scalars().first()
        if not user:
            raise HTTPException(status_code=401, detail="用户不存在")

    elif user_data.username and user_data.password:
        # Password login (username or phone number)
        result = await db.execute(
            select(User).where(
                (User.username == user_data.username) | (User.phone == user_data.username)
            )
        )
        user = result.scalars().first()
        if not user or not verify_password(user_data.password, user.password_hash):
            raise HTTPException(status_code=401, detail="用户名或密码错误")

    else:
        raise HTTPException(status_code=400, detail="请提供登录凭证")

    access_token = create_access_token(data={"sub": user.id})
    return {"access_token": access_token}
```

- [ ] **Step 2: Commit**

```bash
git add backend/api/routes/auth.py
git commit -m "feat: refactor auth for phone+password dual login, SMS verification"
```

---

### Task 4: Backend — TodoList + TodoItem models

**Files:**
- Create: `backend/models/todo.py`

- [ ] **Step 1: Create todo models**

Create `backend/models/todo.py`:

```python
from datetime import datetime
from sqlalchemy import Column, String, Integer, Boolean, DateTime, JSON
from database import Base


class TodoList(Base):
    __tablename__ = "todo_lists"

    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    recipe_names = Column(JSON, default=[])  # ["番茄炒蛋", "紫菜蛋花汤"]
    servings = Column(String, nullable=True)
    status = Column(String(20), default="pending")  # pending, shopping, completed
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class TodoItem(Base):
    __tablename__ = "todo_items"

    id = Column(String, primary_key=True)
    todo_list_id = Column(String, nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    ingredient_name = Column(String(100), nullable=False)
    quantity = Column(String(50), nullable=False)
    is_purchased = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 2: Commit**

```bash
git add backend/models/todo.py
git commit -m "feat: add TodoList and TodoItem models"
```

---

### Task 5: Backend — Todo CRUD endpoints

**Files:**
- Modify: `backend/api/routes/shopping_list.py`

- [ ] **Step 1: Add todo endpoints to shopping list route**

Add these endpoints to `backend/api/routes/shopping_list.py`:

```python
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


@router.post("/todo")
async def create_todo(
    recipe_names: List[str],
    servings: str,
    items: List[dict],
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    todo_id = str(__import__("uuid").uuid4())
    todo = TodoList(
        id=todo_id,
        user_id=user_id,
        recipe_names=recipe_names,
        servings=servings,
        status="pending",
    )
    db.add(todo)
    for item in items:
        todo_item = TodoItem(
            id=str(__import__("uuid").uuid4()),
            todo_list_id=todo_id,
            user_id=user_id,
            ingredient_name=item["name"],
            quantity=item["quantity"],
        )
        db.add(todo_item)
    await db.commit()
    return {"success": True, "data": {"todo_id": todo_id}}


@router.put("/todo/{todo_id}/status")
async def update_todo_status(todo_id: str, status: str, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TodoList).where(TodoList.id == todo_id, TodoList.user_id == user_id))
    todo = result.scalars().first()
    if not todo:
        raise HTTPException(status_code=404, detail="待办不存在")
    todo.status = status
    await db.commit()
    return {"success": True}


@router.put("/todo/item/{item_id}")
async def toggle_todo_item(item_id: str, is_purchased: bool = True, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(TodoItem).where(TodoItem.id == item_id, TodoItem.user_id == user_id))
    item = result.scalars().first()
    if not item:
        raise HTTPException(status_code=404, detail="物品不存在")
    item.is_purchased = is_purchased
    await db.commit()
    return {"success": True}


@router.delete("/todo/{todo_id}")
async def delete_todo(todo_id: str, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
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
```

Add necessary imports at top:
```python
from models.todo import TodoList, TodoItem
```

- [ ] **Step 2: Commit**

```bash
git add backend/api/routes/shopping_list.py
git commit -m "feat: add todo list CRUD endpoints"
```

---

### Task 6: Frontend — Update LocalStorage to persist user data

**Files:**
- Modify: `app/lib/data/datasources/local/local_storage.dart`

- [ ] **Step 1: Implement saveUserData and getUserData**

Replace the stub methods:

```dart
Future<void> saveUserData(Map<String, dynamic> userData) async {
  final encoded = jsonEncode(userData);
  await _box?.put(_userKey, encoded);
}

Future<Map<String, dynamic>?> getUserData() async {
  final encoded = _box?.get(_userKey);
  if (encoded == null) return null;
  return jsonDecode(encoded) as Map<String, dynamic>;
}
```

Add import at top:
```dart
import 'dart:convert';
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/data/datasources/local/local_storage.dart
git commit -m "feat: implement user data persistence in LocalStorage"
```

---

### Task 7: Frontend — Update API config and auth repository

**Files:**
- Modify: `app/lib/core/config/api_config.dart`
- Modify: `app/lib/data/repositories/auth_repository.dart`

- [ ] **Step 1: Add new API endpoints to ApiConfig**

```dart
// Auth - new
static const String sendCode = '/auth/send-code';
static const String resetPassword = '/auth/reset-password';

// Todo
static const String todoList = '/shopping-list/todo';

// Chat
static const String chat = '/chat';
```

- [ ] **Step 2: Add new methods to AuthRepository**

```dart
Future<Map<String, dynamic>> sendCode({required String phone, String purpose = 'register'}) async {
  final response = await _apiClient.post(ApiConfig.sendCode, data: {'phone': phone, 'purpose': purpose});
  return response.data;
}

Future<Map<String, dynamic>> loginWithPhone({required String phone, required String code}) async {
  final response = await _apiClient.post(ApiConfig.login, data: {'phone': phone, 'code': code});
  return response.data;
}

Future<Map<String, dynamic>> loginWithPassword({required String username, required String password}) async {
  final response = await _apiClient.post(ApiConfig.login, data: {'username': username, 'password': password});
  return response.data;
}

Future<Map<String, dynamic>> registerWithPhone({required String username, required String phone, required String code, required String password}) async {
  final response = await _apiClient.post(ApiConfig.register, data: {'username': username, 'phone': phone, 'code': code, 'password': password});
  return response.data;
}

Future<Map<String, dynamic>> resetPassword({required String phone, required String code, required String newPassword}) async {
  final response = await _apiClient.post(ApiConfig.resetPassword, data: {'phone': phone, 'code': code, 'new_password': newPassword});
  return response.data;
}
```

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/config/api_config.dart app/lib/data/repositories/auth_repository.dart
git commit -m "feat: add phone auth and todo API endpoints"
```

---

### Task 8: Frontend — Update AuthState and AuthProvider

**Files:**
- Modify: `app/lib/presentation/providers/auth_provider.dart`

- [ ] **Step 1: Add phone field and fix user data loading**

Update `AuthState` to add `phone`:

```dart
class AuthState {
  final bool isAuthenticated;
  final String? token;
  final String? userId;
  final String? username;
  final String? email;
  final String? phone;
  AuthState({this.isAuthenticated = false, this.token, this.userId, this.username, this.email, this.phone});
  AuthState copyWith({bool? isAuthenticated, String? token, String? userId, String? username, String? email, String? phone}) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        token: token ?? this.token,
        userId: userId ?? this.userId,
        username: username ?? this.username,
        email: email ?? this.email,
        phone: phone ?? this.phone,
      );
}
```

Add `_loadUserData()` method to `AuthNotifier`:

```dart
Future<void> _loadUserData() async {
  try {
    final userData = await _authRepository.getCurrentUser();
    state = state.copyWith(
      userId: userData['id'],
      username: userData['username'],
      email: userData['email'],
      phone: userData['phone'],
    );
    await _localStorage.saveUserData({
      'id': userData['id'],
      'username': userData['username'],
      'email': userData['email'],
      'phone': userData['phone'],
    });
  } catch (_) {}
}
```

Call `_loadUserData()` after successful login in the `login()` method, right after setting the token.

Add new methods:

```dart
Future<bool> loginWithPhone(String phone, String code) async {
  try {
    final response = await _authRepository.loginWithPhone(phone: phone, code: code);
    final token = response['access_token'];
    await _localStorage.saveToken(token);
    state = state.copyWith(isAuthenticated: true, token: token);
    await _loadUserData();
    return true;
  } catch (_) { return false; }
}

Future<bool> sendCode(String phone, String purpose) async {
  try {
    await _authRepository.sendCode(phone: phone, purpose: purpose);
    return true;
  } catch (_) { return false; }
}

Future<bool> registerWithPhone(String username, String phone, String code, String password) async {
  try {
    await _authRepository.registerWithPhone(username: username, phone: phone, code: code, password: password);
    return await loginWithPhone(phone, code);
  } catch (_) { return false; }
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/providers/auth_provider.dart
git commit -m "feat: add phone auth methods and fix user data loading"
```

---

### Task 9: Frontend — Rewrite login/register screen

**Files:**
- Modify: `app/lib/presentation/screens/auth/login_screen.dart`

- [ ] **Step 1: Rewrite with dual-mode login, unified register, forgot password**

The screen should have:
- Top toggle: 登录 / 注册 ( segmented control)
- Login mode toggle: 验证码登录 / 密码登录 (underline tabs)
- Login - SMS mode: phone input + code input + send code button + login button
- Login - Password mode: username/phone input + password input + login button + "忘记密码?" link
- Register: username + phone + code + password + confirm password + register button
- Forgot password dialog/page: phone + code + new password + confirm + reset button
- Countdown timer on send code button (60s)
- Form validation for all fields

This is a substantial UI rewrite. Key state variables:

```dart
bool _isLogin = true;
bool _isSmsLogin = true;
bool _isLoading = false;
String? _errorMessage;
int _countdown = 0;

final _usernameController = TextEditingController();
final _phoneController = TextEditingController();
final _codeController = TextEditingController();
final _passwordController = TextEditingController();
final _confirmPasswordController = TextEditingController();
```

The send code button should start a 60-second countdown:

```dart
Future<void> _sendCode(String purpose) async {
  if (_countdown > 0) return;
  final phone = _phoneController.text.trim();
  if (phone.isEmpty || phone.length != 11) {
    setState(() => _errorMessage = '请输入正确的手机号');
    return;
  }
  await ref.read(authProvider.notifier).sendCode(phone, purpose);
  setState(() => _countdown = 60);
  _timer = Timer.periodic(Duration(seconds: 1), (t) {
    setState(() => _countdown--);
    if (_countdown <= 0) t.cancel();
  });
}
```

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/screens/auth/login_screen.dart
git commit -m "feat: rewrite login/register with phone+password dual mode"
```

---

### Task 10: Frontend — Bottom navigation with StatefulShellRoute

**Files:**
- Create: `app/lib/core/widgets/bottom_nav_shell.dart`
- Modify: `app/lib/core/router/app_router.dart`
- Modify: `app/lib/presentation/screens/home/home_screen.dart`

- [ ] **Step 1: Create bottom nav shell widget**

Create `app/lib/core/widgets/bottom_nav_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const BottomNavShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: const Color(0xFFE8734A),
        child: const Icon(Icons.smart_toy, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '搜索'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: '待办'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Rewrite router with StatefulShellRoute**

Rewrite `app_router.dart` to use `StatefulShellRoute.indexedStack`:

```dart
import 'package:go_router/go_router.dart';
import '../widgets/bottom_nav_shell.dart';
// ... all screen imports ...

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => BottomNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            GoRoute(path: '/ingredients/input', builder: (context, state) {
              final isManual = state.uri.queryParameters['mode'] == 'manual';
              return IngredientInputScreen(isManual: isManual);
            }),
            GoRoute(path: '/ingredients/confirm', builder: (context, state) => const IngredientConfirmScreen()),
            GoRoute(path: '/recommendation-conditions', builder: (context, state) {
              final ingredients = state.extra as List<String>? ?? [];
              return RecommendationConditionDialog(ingredients: ingredients);
            }),
            GoRoute(path: '/recipes', builder: (context, state) => const RecipeListScreen()),
            GoRoute(path: '/recipes/:id', builder: (context, state) {
              final id = state.pathParameters['id']!;
              return RecipeDetailScreen(recipeId: id);
            }),
            GoRoute(path: '/shopping-list', builder: (context, state) => const ShoppingListScreen()),
            GoRoute(path: '/cooking', builder: (context, state) => const CookingScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/todo', builder: (context, state) => const TodoScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
    ],
  );
}
```

- [ ] **Step 3: Update HomeScreen to remove profile icon**

Remove the profile icon button from HomeScreen's AppBar. The scaffold should have no AppBar actions:

```dart
appBar: AppBar(title: const Text('智能厨房助手')),
```

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/widgets/bottom_nav_shell.dart app/lib/core/router/app_router.dart app/lib/presentation/screens/home/home_screen.dart
git commit -m "feat: add bottom navigation with three tabs and StatefulShellRoute"
```

---

### Task 11: Frontend — Profile screen with real data

**Files:**
- Modify: `app/lib/presentation/screens/profile/profile_screen.dart`

- [ ] **Step 1: Implement profile with real user data and working actions**

Convert from `StatelessWidget` to `ConsumerWidget`. Display real username and phone (masked). Wire up logout to `authProvider.logout()`. Add navigation to favorites. Other menu items can show placeholder dialogs.

Key structure:
- User info card: watch `authProvider` for username/phone
- Phone masking: `138****1234`
- Menu items with icons and onTap handlers
- Logout button calls `ref.read(authProvider.notifier).logout()` then `context.go('/login')`

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/screens/profile/profile_screen.dart
git commit -m "feat: implement profile screen with real user data and logout"
```

---

### Task 12: Frontend — Favorites provider and screen

**Files:**
- Create: `app/lib/presentation/providers/favorites_provider.dart`
- Modify: `app/lib/presentation/screens/favorites/favorites_screen.dart`
- Modify: `app/lib/presentation/screens/recipe/recipe_detail_screen.dart`

- [ ] **Step 1: Create favorites provider**

Create `app/lib/presentation/providers/favorites_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/recipe_repository.dart';
import '../../data/models/recipe.dart';
import 'api_client_provider.dart';

class FavoritesState {
  final List<Recipe> favorites;
  final bool isLoading;
  final String? error;
  FavoritesState({this.favorites = const [], this.isLoading = false, this.error});
  FavoritesState copyWith({List<Recipe>? favorites, bool? isLoading, String? error}) =>
      FavoritesState(favorites: favorites ?? this.favorites, isLoading: isLoading ?? this.isLoading, error: error);
}

class FavoritesNotifier extends StateNotifier<FavoritesState> {
  final RecipeRepository _repo;
  final Set<String> _favoriteIds = {};
  FavoritesNotifier(this._repo) : super(FavoritesState()) { loadFavorites(); }

  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _repo.getFavorites();
      final List list = response['data'] ?? [];
      final recipes = list.map((e) => Recipe.fromJson(e)).toList();
      _favoriteIds.clear();
      _favoriteIds.addAll(recipes.map((r) => r.id));
      state = state.copyWith(favorites: recipes, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  bool isFavorite(String recipeId) => _favoriteIds.contains(recipeId);

  Future<void> toggleFavorite(String recipeId) async {
    if (_favoriteIds.contains(recipeId)) {
      await _repo.unfavoriteRecipe(recipeId);
      _favoriteIds.remove(recipeId);
    } else {
      await _repo.favoriteRecipe(recipeId);
      _favoriteIds.add(recipeId);
    }
    await loadFavorites();
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>(
  (ref) => FavoritesNotifier(RecipeRepository(apiClient: ref.watch(apiClientProvider))),
);
```

Add `unfavoriteRecipe` to `RecipeRepository` if not present:

```dart
Future<Map<String, dynamic>> unfavoriteRecipe(String recipeId) async {
  final response = await _apiClient.delete(ApiConfig.favoriteRecipe.replaceAll('{id}', recipeId));
  return response.data;
}
```

- [ ] **Step 2: Implement favorites screen**

Show list of favorite recipes as cards. Empty state when no favorites. Tap card to go to recipe detail.

- [ ] **Step 3: Add favorite button to recipe detail screen**

Add a heart icon button in the AppBar. Watch `favoritesProvider` for state. On tap, call `favoritesProvider.toggleFavorite(recipeId)`.

- [ ] **Step 4: Commit**

```bash
git add app/lib/presentation/providers/favorites_provider.dart app/lib/presentation/screens/favorites/favorites_screen.dart app/lib/presentation/screens/recipe/recipe_detail_screen.dart
git commit -m "feat: implement favorites system with provider, screen, and detail button"
```

---

### Task 13: Frontend — Todo models, repository, and provider

**Files:**
- Create: `app/lib/data/models/todo.dart`
- Create: `app/lib/data/repositories/todo_repository.dart`
- Create: `app/lib/presentation/providers/todo_provider.dart`

- [ ] **Step 1: Create todo models**

Create `app/lib/data/models/todo.dart`:

```dart
class TodoItem {
  final String id;
  final String ingredientName;
  final String quantity;
  final bool isPurchased;
  TodoItem({required this.id, required this.ingredientName, required this.quantity, this.isPurchased = false});
  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
    id: json['id'], ingredientName: json['ingredient_name'],
    quantity: json['quantity'], isPurchased: json['is_purchased'] ?? false,
  );
  TodoItem copyWith({bool? isPurchased}) => TodoItem(
    id: id, ingredientName: ingredientName, quantity: quantity, isPurchased: isPurchased ?? this.isPurchased,
  );
}

class TodoListModel {
  final String id;
  final List<String> recipeNames;
  final String? servings;
  final String status;
  final int totalItems;
  final int pendingItems;
  TodoListModel({required this.id, required this.recipeNames, this.servings, required this.status, required this.totalItems, required this.pendingItems});
  factory TodoListModel.fromJson(Map<String, dynamic> json) => TodoListModel(
    id: json['id'], recipeNames: List<String>.from(json['recipe_names'] ?? []),
    servings: json['servings'], status: json['status'] ?? 'pending',
    totalItems: json['total_items'] ?? 0, pendingItems: json['pending_items'] ?? 0,
  );
}
```

- [ ] **Step 2: Create todo repository**

Create `app/lib/data/repositories/todo_repository.dart` with methods: `getTodoLists()`, `getTodoDetail(id)`, `createTodo(recipeNames, servings, items)`, `toggleTodoItem(itemId, isPurchased)`, `updateTodoStatus(todoId, status)`, `deleteTodo(todoId)`.

- [ ] **Step 3: Create todo provider**

Create `app/lib/presentation/providers/todo_provider.dart` with `TodoState` holding list of `TodoListModel`, selected todo detail, loading/error states. Methods: `loadTodoLists()`, `createTodo(...)`, `toggleItem(...)`, `deleteTodo(...)`.

- [ ] **Step 4: Commit**

```bash
git add app/lib/data/models/todo.dart app/lib/data/repositories/todo_repository.dart app/lib/presentation/providers/todo_provider.dart
git commit -m "feat: add todo models, repository, and provider"
```

---

### Task 14: Frontend — Todo screen

**Files:**
- Create: `app/lib/presentation/screens/todo/todo_screen.dart`

- [ ] **Step 1: Implement todo screen**

ConsumerWidget that watches `todoProvider`. Shows:
- List of todo cards with recipe name, item counts, status badge (待采购/采购中)
- Each card: "继续采购"/"开始采购" button + "删除" button
- Continue/start shopping navigates to shopping list loaded from todo detail
- Empty state with guidance text

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/screens/todo/todo_screen.dart
git commit -m "feat: add todo screen with shopping task list"
```

---

### Task 15: Frontend — Shopping list dual buttons + todo integration

**Files:**
- Modify: `app/lib/presentation/screens/shopping_list/shopping_list_screen.dart`
- Modify: `app/lib/presentation/providers/shopping_list_provider.dart`

- [ ] **Step 1: Add "加入待办" and "开始采购" buttons**

Replace the existing bottom section with two buttons side by side:
- "📋 加入待办" — outlined style, calls todo provider to save current shopping list
- "🛒 开始采购" — filled style, enters the current purchase flow (existing behavior)

After joining todo, show SnackBar "已加入待办，可在待办页面查看" and navigate back.

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/screens/shopping_list/shopping_list_screen.dart app/lib/presentation/providers/shopping_list_provider.dart
git commit -m "feat: add dual buttons to shopping list (todo + start shopping)"
```

---

### Task 16: Frontend — Multi-select recipes

**Files:**
- Modify: `app/lib/presentation/providers/recipe_provider.dart`
- Modify: `app/lib/presentation/screens/recipe/recipe_list_screen.dart`
- Modify: `app/lib/presentation/screens/recipe/recipe_detail_screen.dart`

- [ ] **Step 1: Add multi-select to RecipeState**

Add `selectedRecipeIds: Set<String>` to `RecipeState`. Add methods `toggleRecipeSelection(id)`, `clearSelection()`. Default: first recipe is selected.

- [ ] **Step 2: Update recipe list screen with checkboxes**

Each recipe card gets a checkbox/selection indicator. Bottom shows "已选 N 道菜 · 缺失食材将合并到购物清单". Button: "查看详情并生成购物清单". Single selection → detail page. Multiple → merged shopping list.

- [ ] **Step 3: Update recipe detail for merged flow**

When multiple recipes selected, the detail page shows all selected recipes with their ingredients merged. Missing ingredients are combined.

- [ ] **Step 4: Commit**

```bash
git add app/lib/presentation/providers/recipe_provider.dart app/lib/presentation/screens/recipe/recipe_list_screen.dart app/lib/presentation/screens/recipe/recipe_detail_screen.dart
git commit -m "feat: add multi-select recipes with merged shopping list"
```

---

## Phase 2: New Features

### Task 17: Backend — Update recipe prompt for timer markers

**Files:**
- Modify: `backend/services/llm_service.py`

- [ ] **Step 1: Add timer instruction to recipe prompt**

In `_build_recipe_prompt()`, add to the steps requirement:

```
步骤要求：每个步骤是具体的操作说明。如果某步骤涉及等待时间（如"腌制"、"炖煮"、"翻炒"等），请在步骤文本末尾标注时间，格式为 [timer:Xm]，其中 X 是分钟数。例如："将排骨放入冷水锅中焯水，撇去浮沫 [timer:5m]"。没有明确时间的步骤不需要标注。
```

Also update the JSON format spec to show steps as strings (not objects), so the timer marker stays in the text.

- [ ] **Step 2: Commit**

```bash
git add backend/services/llm_service.py
git commit -m "feat: add timer markers to recipe generation prompt"
```

---

### Task 18: Frontend — Step timer widget

**Files:**
- Create: `app/lib/presentation/widgets/timer_widget.dart`
- Modify: `app/lib/presentation/screens/cooking/cooking_screen.dart`
- Modify: `app/lib/data/models/recipe.dart`

- [ ] **Step 1: Parse timer markers in Recipe model**

Add a helper to extract timer info from step text:

```dart
class StepInfo {
  final String text;
  final int? timerMinutes;
  StepInfo({required this.text, this.timerMinutes});

  static StepInfo parse(String stepText) {
    final regex = RegExp(r'\[timer:(\d+)m\]');
    final match = regex.firstMatch(stepText);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      final cleanText = stepText.replaceAll(regex, '').trim();
      return StepInfo(text: cleanText, timerMinutes: minutes);
    }
    return StepInfo(text: stepText);
  }
}
```

- [ ] **Step 2: Create circular timer widget**

Build a widget with:
- Circular progress indicator (CustomPaint with arc)
- Large time display in center
- Pause/Resume and Cancel buttons
- Callback when timer completes (sound + snackbar)

Use `AnimationController` for smooth progress ring.

- [ ] **Step 3: Integrate timer into cooking screen**

Parse each step with `StepInfo.parse()`. Show ⏱ icon next to steps with timer. Tapping shows the timer widget as a bottom sheet. When timer ends, show dialog "这一步完成啦！".

- [ ] **Step 4: Commit**

```bash
git add app/lib/presentation/widgets/timer_widget.dart app/lib/presentation/screens/cooking/cooking_screen.dart app/lib/data/models/recipe.dart
git commit -m "feat: add step timer with circular countdown"
```

---

### Task 19: Backend — Upgrade LangChain and fix Agent

**Files:**
- Modify: `backend/requirements.txt`
- Modify: `backend/agents/kitchen_assistant_agent.py`

- [ ] **Step 1: Upgrade LangChain dependencies**

Update `requirements.txt`:
```
langchain>=0.3.0
langchain-community>=0.3.0
langchain-core>=0.3.0
# Remove langgraph==0.0.20 (not needed for this)
```

- [ ] **Step 2: Fix `_create_agent()` in KitchenAssistantAgent**

Replace the method that returns None with:

```python
from langchain_community.chat_models import ChatTongyi
from langchain.agents import AgentExecutor, create_react_agent

def _create_agent(self):
    llm = ChatTongyi(
        model="qwen-turbo",
        dashscope_api_key=self.api_key,
    )
    prompt = PromptTemplate.from_template(
        """你是一个温暖、专业的美食助手，帮助用户解决各种关于做菜的问题。

可用工具:
{tools}

工具名称: {tool_names}

使用格式:
Thought: 思考下一步该做什么
Action: 工具名称
Action Input: 工具输入参数（JSON格式）
Observation: 工具返回结果
... (重复 Thought/Action/Action Input/Observation)
Thought: 我现在知道最终答案了
Final Answer: 最终答案

用户输入: {input}

{agent_scratchpad}
"""
    )
    agent = create_react_agent(llm, self.tools, prompt)
    return AgentExecutor(agent=agent, tools=self.tools, verbose=True, max_iterations=5)
```

- [ ] **Step 3: Commit**

```bash
git add backend/requirements.txt backend/agents/kitchen_assistant_agent.py
git commit -m "feat: upgrade LangChain and fix Agent with ChatTongyi"
```

---

### Task 20: Backend — Chat model, service, and route

**Files:**
- Create: `backend/models/chat_message.py`
- Create: `backend/services/chat_service.py`
- Create: `backend/api/routes/chat.py`
- Modify: `backend/main.py` (register chat router)

- [ ] **Step 1: Create ChatMessage model**

```python
class ChatMessage(Base):
    __tablename__ = "chat_messages"
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    session_id = Column(String, nullable=False, index=True)
    role = Column(String(20), nullable=False)  # "user" or "assistant"
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
```

- [ ] **Step 2: Create chat service**

Wraps `KitchenAssistantAgent`. Loads recent chat history from DB, passes as context, calls agent, saves response.

- [ ] **Step 3: Create chat route**

```python
@router.post("/")
async def chat(request: ChatRequest, user_id: str = Depends(get_current_user_id), db: AsyncSession = Depends(get_db)):
    # Save user message
    # Call agent with history context
    # Save assistant response
    # Return response
```

- [ ] **Step 4: Register chat router in main.py**

```python
from api.routes.chat import router as chat_router
app.include_router(chat_router, prefix=settings.API_V1_PREFIX + "/chat", tags=["chat"])
```

- [ ] **Step 5: Commit**

```bash
git add backend/models/chat_message.py backend/services/chat_service.py backend/api/routes/chat.py backend/main.py
git commit -m "feat: add AI chat assistant with LangChain Agent"
```

---

### Task 21: Frontend — Chat screen

**Files:**
- Create: `app/lib/data/models/chat_message.dart`
- Create: `app/lib/data/repositories/chat_repository.dart`
- Create: `app/lib/presentation/providers/chat_provider.dart`
- Create: `app/lib/presentation/screens/chat/chat_screen.dart`

- [ ] **Step 1: Create chat message model and repository**

Simple model with `role` (user/assistant) and `content`. Repository sends POST to `/chat` with message and session_id.

- [ ] **Step 2: Create chat provider**

Manages message list, sends messages, receives responses. Auto-generates session_id.

- [ ] **Step 3: Create chat screen**

Full-screen chat UI:
- AppBar: "美食助手" with back button
- Message list: bubbles with different styling for user/assistant
- Input bar at bottom: TextField + send button
- Auto-scroll to bottom on new message
- Loading indicator while waiting for AI response

- [ ] **Step 4: Commit**

```bash
git add app/lib/data/models/chat_message.dart app/lib/data/repositories/chat_repository.dart app/lib/presentation/providers/chat_provider.dart app/lib/presentation/screens/chat/chat_screen.dart
git commit -m "feat: add AI chat assistant screen"
```

---

## Phase 3: UI Design Upgrade

### Task 22: Theme system — Warm hand-drawn color scheme

**Files:**
- Modify: `app/lib/core/theme/app_theme.dart`

- [ ] **Step 1: Implement new theme with warm colors and hand-drawn style**

Use `frontend-design` skill for this task. Key changes:
- Replace green primary with `#E8734A` warm orange
- Large border radius (16-24px) on all components
- Outlined button style with 2px border
- Cream white background `#FFF8F0`
- Deep brown text `#3D2C2C`
- Card style with `#FEF3E2` background and subtle border
- Rounded input fields
- Custom floating action button styling
- Dark theme with warm brown tones

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/theme/app_theme.dart
git commit -m "feat: new warm hand-drawn theme"
```

---

### Task 23: All screens UI pass — Hand-drawn style

**Files:**
- Modify: all screen files in `app/lib/presentation/screens/`
- Modify: `app/lib/core/widgets/bottom_nav_shell.dart`

- [ ] **Step 1: Apply hand-drawn style to all screens**

Use `frontend-design` skill. For each screen:
- Replace standard buttons with outlined warm-style buttons
- Add emoji icons where appropriate
- Use rounded cards with warm borders
- Apply cream backgrounds
- Add subtle animations (elastic curves on buttons, slide-in for cards)
- Consistent spacing and visual rhythm

Screens to update:
- HomeScreen
- LoginScreen
- ProfileScreen
- FavoritesScreen
- RecipeListScreen
- RecipeDetailScreen
- ShoppingListScreen
- CookingScreen
- TodoScreen
- ChatScreen
- BottomNavShell

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/ app/lib/core/widgets/
git commit -m "feat: apply hand-drawn warm style to all screens"
```

---

### Task 24: Animations and effects

**Files:**
- Modify: relevant screen files and widgets

- [ ] **Step 1: Add animations**

Use `frontend-design` skill:
- Button taps: `Curves.elasticOut` scale animation
- Card appearance: slide-up + fade-in with `AnimationController`
- Page transitions: custom `PageRouteBuilder` with fade + slide-up
- Cooking completion: particle/confetti celebration effect
- Timer widget: smooth circular progress animation

- [ ] **Step 2: Commit**

```bash
git add app/lib/presentation/ app/lib/core/router/
git commit -m "feat: add hand-drawn animations and celebration effects"
```

---

### Task 25: Dark mode adaptation

**Files:**
- Modify: `app/lib/core/theme/app_theme.dart`

- [ ] **Step 1: Implement warm dark theme**

Dark theme colors:
- Surface: `#1A1512` (warm black)
- Card: `#2D2420` (dark brown)
- Text: `#F5EDE4` (warm white)
- Primary stays `#E8734A`
- Borders use dark warm tones

- [ ] **Step 2: Commit**

```bash
git add app/lib/core/theme/app_theme.dart
git commit -m "feat: add warm dark mode theme"
```

---

## Self-Review

**1. Spec coverage check:**

| Spec Requirement | Task |
|-----------------|------|
| Phone + password registration | Task 1, 2, 3, 7, 8, 9 |
| Dual-mode login (SMS + password) | Task 3, 7, 8, 9 |
| Forgot password via phone | Task 3, 7, 9 |
| Bottom 3-tab navigation | Task 10 |
| Profile with real data + logout | Task 6, 8, 11 |
| Favorites system | Task 12 |
| Shopping list dual buttons | Task 15 |
| Todo system (backend + frontend) | Task 4, 5, 13, 14 |
| Multi-select recipes | Task 16 |
| Step timer | Task 17, 18 |
| AI assistant (LangChain Agent) | Task 19, 20, 21 |
| Warm hand-drawn UI | Task 22, 23, 24 |
| Dark mode | Task 25 |

**2. Placeholder scan:** No TBDs, no TODOs, all steps have code or specific instructions.

**3. Type consistency:** All model fields, method signatures, and property names are consistent across tasks. `TodoItem.ingredientName` matches the JSON key `ingredient_name` in fromJson. `FavoritesNotifier.toggleFavorite(recipeId)` matches the method call in recipe_detail_screen.

**No gaps found. Plan is complete.**
