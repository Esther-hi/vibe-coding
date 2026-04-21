"""
厨房助手主 Agent
"""
from langchain_classic.agents import AgentExecutor, create_react_agent
from langchain_classic.prompts import PromptTemplate
from langchain_core.language_models.llms import LLM
from typing import Dict, List, Optional
from dashscope import Generation

from core.config import settings
from agents.tools.ingredient_recognition_tool import IngredientRecognitionTool
from agents.tools.recipe_generation_tool import RecipeGenerationTool
from agents.tools.shopping_list_tool import ShoppingListTool


class DashScopeLLM(LLM):
    """直接调用 DashScope Generation API 的 LangChain LLM 封装"""

    api_key: str = ""
    model_name: str = "qwen-turbo"

    @property
    def _llm_type(self) -> str:
        return "dashscope"

    def _call(self, prompt: str, stop=None, **kwargs) -> str:
        response = Generation.call(
            model=self.model_name,
            prompt=prompt,
            api_key=self.api_key,
            temperature=0.8,
            top_p=0.9,
            max_tokens=1500,
        )
        if response.status_code == 200:
            return response.output.text
        raise Exception(f"DashScope API 调用失败: {response.code}")


class KitchenAssistantAgent:
    """
    主厨房助手 Agent - 负责意图识别和任务分发
    """

    def __init__(self, api_key: str = None):
        self.api_key = api_key or settings.DASHSCOPE_API_KEY
        self.tools = self._init_tools()
        self.agent = self._create_agent()

    def _init_tools(self) -> List:
        """初始化所有工具"""
        return [
            IngredientRecognitionTool(),
            RecipeGenerationTool(),
            ShoppingListTool(),
        ]

    def _create_agent(self):
        """创建 ReAct Agent"""
        llm = DashScopeLLM(api_key=self.api_key, model_name=settings.QWEN_TEXT_MODEL)

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
        return AgentExecutor(
            agent=agent,
            tools=self.tools,
            verbose=True,
            max_iterations=5,
            handle_parsing_errors=True,
        )

    async def process_request(self, user_input: str, context: Dict = None) -> Dict:
        """
        处理用户请求

        Args:
            user_input: 用户输入
            context: 上下文信息

        Returns:
            处理结果
        """
        if self.agent:
            try:
                result = await self.agent.ainvoke({"input": user_input})
                return {"intent": "chat", "result": result.get("output", str(result))}
            except Exception as e:
                return {"intent": "error", "result": str(e)}

        # Fallback: simple intent detection
        intent = self._detect_intent(user_input)

        if intent == "ingredient_recognition":
            return {"intent": "ingredient_recognition", "result": "请上传图片"}

        elif intent == "recipe_generation":
            return {"intent": "recipe_generation", "result": "请告诉我你有哪些食材"}

        elif intent == "shopping_list":
            return {"intent": "shopping_list", "result": "请提供菜谱信息"}

        else:
            return {"intent": "unknown", "result": "请描述您的需求"}

    def _detect_intent(self, user_input: str) -> str:
        """简单意图识别"""
        text = user_input.lower()

        if any(kw in text for kw in ["识别", "食材", "拍照", "冰箱"]):
            return "ingredient_recognition"
        elif any(kw in text for kw in ["菜谱", "做什么", "推荐", "菜"]):
            return "recipe_generation"
        elif any(kw in text for kw in ["购物", "买", "清单"]):
            return "shopping_list"
        else:
            return "unknown"
