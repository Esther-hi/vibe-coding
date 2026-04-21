"""
通义千问多模态视觉服务
"""
import json
import re
from typing import Dict
from dashscope import MultiModalConversation

from core.config import settings


class VisionService:
    """通义千问多模态视觉服务"""

    def __init__(self):
        self.api_key = settings.DASHSCOPE_API_KEY
        self.model = settings.QWEN_VL_MODEL

    async def recognize_ingredients(self, image_base64: str) -> Dict:
        """
        使用 qwen-vl-max 识别图片中的食材

        Args:
            image_base64: Base64 编码的图片

        Returns:
            识别结果字典
        """
        messages = [
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": """请仔细分析这张图片，识别出所有可见的食材。

                        按照以下 JSON 格式返回（只返回JSON，不要其他文字）：
                        {
                            "ingredients": [
                                {
                                    "name": "食材名称",
                                    "category": "分类（蔬菜/肉类/水果/蛋奶/调料/其他）",
                                    "estimated_quantity": "估计数量",
                                    "freshness": "新鲜度（新鲜/一般/即将过期）",
                                    "confidence": 0.95,
                                    "location": "图片中的位置描述"
                                }
                            ],
                            "overall_freshness": "整体新鲜度评价",
                            "storage_suggestions": "存储建议"
                        }

                        注意事项：
                        1. 只识别确定看到的食材，不确定的不列出
                        2. confidence 表示置信度（0-1之间）
                        3. 如果无法识别，返回空列表
                        """
                    },
                    {
                        "type": "image",
                        "image": f"data:image/jpeg;base64,{image_base64}"
                    }
                ]
            }
        ]

        response = MultiModalConversation.call(
            model=self.model,
            messages=messages,
            api_key=self.api_key
        )

        if response.status_code == 200:
            content = response.output.choices[0].message.content
            # 新版 DashScope SDK content 可能是 list 而非 str
            if isinstance(content, list):
                text_parts = []
                for item in content:
                    if isinstance(item, dict):
                        text_parts.append(item.get("text", ""))
                    elif isinstance(item, str):
                        text_parts.append(item)
                content = "".join(text_parts)
            elif not isinstance(content, str):
                content = str(content)
            return self._parse_response(content)
        else:
            raise Exception(f"API 调用失败: {response.code} - {response.message}")

    def _parse_response(self, content: str) -> Dict:
        """解析 LLM 返回的内容"""
        try:
            # 提取 JSON 部分
            json_str = self._extract_json(content)
            return json.loads(json_str)
        except Exception as e:
            # 如果解析失败，返回默认结构
            return {
                "ingredients": [],
                "overall_freshness": "未知",
                "storage_suggestions": f"解析失败: {str(e)}",
                "raw_content": content
            }

    def _extract_json(self, text: str) -> str:
        """从文本中提取 JSON"""
        # 尝试匹配花括号包裹的内容
        match = re.search(r'\{[\s\S]*\}', text)
        return match.group(0) if match else "{}"
