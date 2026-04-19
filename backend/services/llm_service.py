"""
通义千问文本生成服务
"""
import json
import re
from typing import List, Dict, Optional
from dashscope import Generation

from core.config import settings


class LLMService:
    """通义千问文本生成服务"""

    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.model = settings.QWEN_TEXT_MODEL

    async def generate_recipes(
        self,
        ingredients: List[str],
        people_count: int = 2,
        preferences: Optional[Dict] = None,
        count: int = 3
    ) -> Dict:
        """
        根据食材生成菜谱

        Args:
            ingredients: 食材列表
            people_count: 用餐人数
            preferences: 用户偏好
            count: 推荐数量

        Returns:
            菜谱推荐结果
        """
        prompt = self._build_recipe_prompt(ingredients, people_count, preferences, count)

        response = Generation.call(
            model=self.model,
            prompt=prompt,
            api_key=self.api_key,
            temperature=0.8,
            top_p=0.9,
            max_tokens=3000
        )

        if response.status_code == 200:
            content = response.output.text
            return self._parse_recipe_response(content)
        else:
            raise Exception(f"API 调用失败: {response.code}")

    def _build_recipe_prompt(
        self,
        ingredients: List[str],
        people_count: int,
        preferences: Optional[Dict],
        count: int
    ) -> str:
        """构建菜谱生成提示词"""
        pref_str = f"用餐人数：{people_count} 人\n"
        if preferences:
            if preferences.get("taste"):
                pref_str += f"口味偏好：{preferences['taste']}\n"
            if preferences.get("difficulty"):
                pref_str += f"难度要求：{preferences['difficulty']}\n"
            if preferences.get("cooking_time"):
                pref_str += f"时间限制：{preferences['cooking_time']}分钟内\n"

        return f"""你是一位经验丰富的厨师，请根据以下食材推荐 {count} 道菜谱。

可用食材：{', '.join(ingredients)}

{pref_str}

请严格按照以下 JSON 格式返回（只返回JSON，不要其他文字）：
{{
    "recipes": [
        {{
            "name": "菜名",
            "difficulty": "简单/中等/困难",
            "cooking_time": 预计时间（分钟）,
            "cuisine": "菜系",
            "servings": "{people_count}人份",
            "ingredients": [
                {{"name": "食材名", "quantity": "用量（根据{people_count}人估算）", "is_available": true/false}}
            ],
            "missing_ingredients": [
                {{"name": "缺少的食材名", "quantity": "需要购买的用量"}}
            ],
            "steps": ["详细步骤1", "详细步骤2"],
            "nutrition": {{
                "calories": "热量（kcal，按{people_count}人总量）",
                "protein": "蛋白质（g）",
                "carbs": "碳水（g）",
                "fat": "脂肪（g）"
            }},
            "tips": "烹饪小贴士"
        }}
    ]
}}

要求：
1. 优先使用已有食材
2. 食材用量必须根据{people_count}人估算（如{people_count}人用{people_count * 2}个鸡蛋）
3. 缺少食材也需标注建议购买量
4. 步骤要详细、可操作，适合家庭制作
5. 营养信息要尽量准确
6. 考虑营养均衡
"""

    def _parse_recipe_response(self, content: str) -> Dict:
        """解析菜谱响应"""
        try:
            json_str = self._extract_json(content)
            return json.loads(json_str)
        except Exception as e:
            return {
                "recipes": [],
                "error": str(e),
                "raw_content": content
            }

    async def search_recipe(self, query: str) -> Dict:
        """
        搜索菜谱（反向查询）

        Args:
            query: 菜名或关键词

        Returns:
            菜谱信息
        """
        prompt = f"""请搜索并提供菜谱"{query}"的详细信息。

请严格按照以下 JSON 格式返回（只返回JSON，不要其他文字）：
{{
    "name": "{query}",
    "difficulty": "简单/中等/困难",
    "cooking_time": 预计时间（分钟）,
    "cuisine": "菜系",
    "ingredients": [
        {{"name": "食材名", "quantity": "用量", "is_required": "必需/可选"}}
    ],
    "steps": ["详细步骤1", "详细步骤2"],
    "nutrition": {{
        "calories": "热量（kcal）",
        "protein": "蛋白质（g）",
        "carbs": "碳水（g）",
        "fat": "脂肪（g）"
    }},
    "tips": "烹饪小贴士"
}}
"""

        response = Generation.call(
            model=self.model,
            prompt=prompt,
            api_key=self.api_key,
            temperature=0.7,
            max_tokens=2000
        )

        if response.status_code == 200:
            content = response.output.text
            return self._parse_recipe_response(content)
        else:
            raise Exception(f"API 调用失败: {response.code}")

    async def generate_shopping_list(
        self,
        recipe_name: str,
        missing_ingredients: List[Dict],
        available_ingredients: List[str]
    ) -> Dict:
        """
        生成购物清单

        Args:
            recipe_name: 菜谱名称
            missing_ingredients: 缺少的食材
            available_ingredients: 已有食材

        Returns:
            购物清单
        """
        missing_str = "\n".join([
            f"- {item.get('name', '')}: {item.get('quantity', '')}"
            for item in missing_ingredients
        ])

        prompt = f"""为菜谱"{recipe_name}"生成购物清单。

缺少的食材：
{missing_str}

已有食材：{', '.join(available_ingredients)}

请返回 JSON 格式：
{{
    "shopping_list": [
        {{
            "name": "食材名",
            "quantity": "建议购买量",
            "estimated_price": "预估价格（元）",
            "purchase_location": "建议购买地点（超市/菜市场）",
            "storage_tip": "保存建议"
        }}
    ],
    "total_estimated_cost": "总预估花费（元）",
    "shopping_tips": "购物小贴士"
}}
"""

        response = Generation.call(
            model=self.model,
            prompt=prompt,
            api_key=self.api_key,
            temperature=0.5,
            max_tokens=1500
        )

        if response.status_code == 200:
            content = response.output.text
            json_str = self._extract_json(content)
            return json.loads(json_str)
        else:
            raise Exception(f"API 调用失败: {response.code}")

    def _extract_json(self, text: str) -> str:
        """从文本中提取 JSON"""
        match = re.search(r'\{[\s\S]*\}', text)
        return match.group(0) if match else "{}"
