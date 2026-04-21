# 智能聊天助手 Agent 设计思路

## 1. Agent 架构设计

### 为什么需要 Agent？

用户在聊天窗口可能问各种问题，需求类型完全不同：

- "冰箱里有西红柿和鸡蛋，能做什么菜？" → 需要生成菜谱
- "帮我列个购物清单" → 需要生成购物清单
- "这道菜怎么做更好吃？" → 普通聊天就行

如果只靠一个 LLM，它只能"说话"，不能调用项目里已有的功能（菜谱生成、购物清单等）。**Agent 的作用就是让 LLM 能"动手"，不只是"动嘴"。**

### ReAct 模式

本项目的 Agent 采用 ReAct（Reasoning + Acting）模式：

```
用户提问
  ↓
LLM 思考：这个问题该用什么工具？   ← Thought
  ↓
LLM 决定：我要调用 recipe_generation ← Action
  ↓
工具执行，返回结果                 ← Observation
  ↓
LLM 看到结果，组织成自然语言回答    ← Final Answer
```

类比：像一个厨师接到客人点单后，先想"该用什么厨具"，然后拿起炒锅去做菜，最后把成品端给客人。

### 四个关键角色

#### 工具（Tools）— 厨具

注册了三个工具：

| 工具 | 功能 |
|------|------|
| `IngredientRecognitionTool` | 识别食材（需要图片） |
| `RecipeGenerationTool` | 根据食材生成菜谱 |
| `ShoppingListTool` | 根据菜谱生成购物清单 |

每个工具继承 LangChain 的 `BaseTool`，包含：
- `description`：告诉 LLM 这个工具是干什么的
- `_arun`：实际执行的代码

#### LLM — 厨师的大脑

使用 `ChatTongyi`（通义千问 qwen-turbo），负责：
- 理解用户意图
- 决定调用哪个工具、传什么参数
- 把工具返回的结果整理成自然语言

#### Prompt 模板 — 厨师的工作手册

定义了 ReAct 的格式规范，告诉 LLM 必须按以下格式思考和回答：

```
Thought: 思考下一步该做什么
Action: 工具名称
Action Input: 工具输入参数（JSON格式）
Observation: 工具返回结果
... (重复 Thought/Action/Action Input/Observation)
Thought: 我现在知道最终答案了
Final Answer: 最终答案
```

#### AgentExecutor — 厨房调度员

把 LLM + 工具 + Prompt 组装在一起，循环执行"思考→行动→观察"，最多 5 轮（`max_iterations=5`），直到得到最终答案。

### 完整调用链路

```
用户发消息
  → ChatService.chat()
    → KitchenAssistantAgent.process_request()
      → AgentExecutor.ainvoke()
        → LLM 思考该用什么工具
        → 调用对应 Tool._arun()
        → LLM 根据结果给出最终回答
    ← 返回回答文本
  ← 保存到数据库
← 返回给用户
```

### 已知问题

LLM 输出格式不稳定。ReAct 要求 LLM 严格按 `Thought: ... Action: ...` 格式输出，但 Qwen 模型有时直接输出自然语言，导致 AgentExecutor 解析失败抛异常。又因为没有设置 `handle_parsing_errors`，不会自动重试，整个请求就挂了。

---

## 2. 为什么没有 RAG 和 MCP

### RAG — 给 LLM 一个"参考书"

RAG（Retrieval-Augmented Generation）的思路：LLM 回答之前，先去一个知识库里检索相关资料，把资料塞进 prompt 里，让它"开卷考试"。

```
用户问："红烧肉怎么做？"
  ↓
去菜谱数据库检索到 3 篇相关菜谱文档
  ↓
把这些文档 + 用户问题 一起发给 LLM
  ↓
LLM 基于这些文档回答
```

**本项目为什么没用 RAG？**

因为"知识"不是文档，而是**实时生成的**。菜谱是 LLM 根据用户提供的食材当场创作的，不是从固定菜谱库里查的：

```
当前数据流：用户给食材 → LLM 现场编菜谱 → 返回
RAG 数据流：用户问问题 → 去库里查已有菜谱 → 返回
```

**什么时候该加 RAG？**

当需要做"根据用户收藏的菜谱推荐类似菜品"这类功能时 — 把收藏的菜谱存成向量，检索出来作为上下文喂给 LLM。

### MCP — 统一的"插座标准"

MCP（Model Context Protocol）是 Anthropic 提出的一个协议，解决的问题是：**每个 AI 应用都要自己写一套对接工具的代码，重复劳动。**

```
没有 MCP（当前项目）：
  Agent → LangChain BaseTool → RecipeGenerationTool（Python 类）
  Agent → LangChain BaseTool → ShoppingListTool（Python 类）
  换一个框架就要全部重写

有 MCP：
  Agent → MCP Client → MCP Server（标准协议，任何框架都能对接）
```

**本项目为什么没用 MCP？**

因为这是一个独立的小项目，工具只有 3 个，且都跑在同一个 Python 进程里，用 LangChain 的 `BaseTool` 直接调用就够了。MCP 更适合：
- 工具很多、需要动态增减的场景
- 多个 AI 应用共享同一套工具
- Claude Desktop、IDE 插件这类需要连接外部服务的场景

### 总结

| | RAG | MCP |
|--|-----|-----|
| 解决什么问题 | LLM 缺知识 | 工具对接不标准 |
| 本项目需要吗 | 暂时不需要，菜谱是实时生成的 | 暂时不需要，3 个工具直接写就够了 |
| 什么时候该加 | 要做"菜谱搜索""个性化推荐"时 | 工具变多、需要跨服务复用时 |

---

## 3. LangChain、ReAct、RAG 之间的关系

三者不是同一层面的东西，而是可以自由组合的：

| 概念 | 解决什么问题 | 类比 |
|------|-------------|------|
| **LangChain** | 怎么把 LLM、工具、数据流组装成完整应用 | 厨房的管理系统（灶台、菜单本、传菜窗口） |
| **ReAct** | LLM 怎么思考和行动的**策略** | 厨师的工作方式（先想→再做→看结果→再想） |
| **RAG** | LLM 知识不够时怎么**补知识** | 厨房旁边的一本参考食谱大全 |

### 组合关系

```
LangChain（框架）
  ├── 可以用 ReAct 模式来调度工具调用
  ├── 也可以用 RAG 来补充知识
  └── 也可以同时用 ReAct + RAG
```

### 三种典型搭配

```
# 只有 ReAct：LLM 自己思考 + 调工具
用户提问 → LLM 思考 → 调用工具 → 得到答案

# 只有 RAG：LLM 先查资料再回答
用户提问 → 检索文档 → 把文档塞进 prompt → LLM 回答

# ReAct + RAG 一起用：LLM 思考后，决定去查资料，再回答
用户提问 → LLM 思考"我需要查一下" → 调用检索工具（RAG）
         → 看到检索结果 → 整理成最终回答
```

第三种情况就是 ReAct 把 RAG 当成了一个"工具"来调用。

### 对应到本项目

```
当前架构：
  LangChain ──→ 框架，用来组装 Agent
  ReAct     ──→ 策略，LLM 按思考→行动→观察循环
  RAG       ──→ 没用，因为知识是 LLM 实时生成的，不需要查文档库

未来扩展（如增加"根据用户历史偏好推荐菜谱"）：
  LangChain ──→ 框架不变
  ReAct     ──→ 策略不变，多加一个检索工具
  RAG       ──→ 新增，把用户历史菜谱建成向量索引
```

**一句话总结**：LangChain 是框架，ReAct 是运行策略，RAG 是知识补充方式。它们在不同层面，可以自由组合。
