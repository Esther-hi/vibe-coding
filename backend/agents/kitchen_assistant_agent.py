"""
厨房助手主 Agent
"""
from langchain.agents import AgentExecutor, create_react_agent
from langchain.prompts import PromptTemplate
from typing import Dict, List, Any

from core.config import settings
from agents.tools.ingredient_recognition_tool import IngredientRecognitionTool
from agents.tools.recipe_generation_tool import RecipeGenerationTool
from agents.tools.shopping_list_tool import ShoppingListTool


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
        prompt = PromptTemplate.from_template(
            """你是一个专业的厨房助手，帮助用户处理食材识别、菜谱推荐等问题。

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

        # 由于通义千问暂不支持 LangChain 直接集成，这里使用简化版本
        # 实际使用时直接调用各个 Tool
        return None

    async def process_request(self, user_input: str, context: Dict = None) -> Dict:
        """
        处理用户请求

        Args:
            user_input: 用户输入
            context: 上下文信息

        Returns:
            处理结果
        """
        # 简单的意图识别
        intent = self._detect_intent(user_input)

        if intent == "ingredient_recognition":
            # 食材识别
            tool = IngredientRecognitionTool()
            return {"intent": "ingredient_recognition", "result": "请上传图片"}

        elif intent == "recipe_generation":
            # 菜谱生成
            tool = RecipeGenerationTool()
            ingredients = context.get("ingredients", []) if context else []
            result = await tool._arun(ingredients=ingredients)
            return {"intent": "recipe_generation", "result": result}

        elif intent == "shopping_list":
            # 购物清单
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
