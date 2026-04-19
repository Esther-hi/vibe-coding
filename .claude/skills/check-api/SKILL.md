---
name: check-api
description: 测试后端 API 接口，检查是否正常运行并返回正确响应
disable-model-invocation: true
allowed-tools: Bash(curl *)
argument-hint: "[endpoint] [method]"
---

## API 接口测试

测试后端 API 接口: $ARGUMENTS

### 步骤

1. 先检查后端服务是否在运行：
   - 执行 `curl -s http://localhost:8000/health`
   - 如果无响应，提示用户先启动后端：`cd E:\Claude_cook\backend && .\venv\Scripts\activate && uvicorn main:app --reload`

2. 解析参数：
   - `$0` = 接口路径（如 `/api/v1/recipes/generate`）
   - `$1` = 请求方法（默认 GET）

3. 如果需要认证（非 /health 和 / 根路径）：
   - 先用测试账号登录获取 Token：
    `curl -s -X POST http://localhost:8000/api/v1/auth/login -H "Content-Type: application/json" -d "{\"username\":\"testuser\",\"password\":\"test123456\"}"`
   - 从响应中提取 access_token

4. 发送请求：
   - GET: `curl -s http://localhost:8000<endpoint> -H "Authorization: Bearer <token>"`
   - POST: `curl -s -X POST http://localhost:8000<endpoint> -H "Content-Type: application/json" -H "Authorization: Bearer <token>" --data-raw "<body>"`

5. 报告结果：
   - 状态码
   - 响应内容（格式化 JSON）
   - 是否符合预期
