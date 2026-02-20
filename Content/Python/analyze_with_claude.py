"""
독립적인 Claude 이미지 분석 스크립트
====================================
UE5 외부에서 실행되는 Python 스크립트.
이미지를 Claude API로 분석하고 JSON 결과를 반환한다.

사용법:
    python analyze_with_claude.py <image_path> <prompt> <api_key>
"""

import sys
import json
import base64
import os
from pathlib import Path

def analyze_image(image_path, prompt, api_key):
    """이미지를 Claude API로 분석한다."""
    try:
        # 이미지 파일 확인
        if not os.path.exists(image_path):
            return {"error": f"Image file not found: {image_path}"}

        # API 키 확인
        if not api_key:
            return {"error": "API key is required"}

        # anthropic 임포트
        try:
            from anthropic import Anthropic
        except ImportError:
            return {"error": "anthropic module not installed. Run: pip install anthropic"}

        # 이미지 읽기 및 인코딩
        with open(image_path, "rb") as f:
            image_data = base64.standard_b64encode(f.read()).decode("utf-8")

        # 파일 확장자로 미디어 타입 결정
        _, ext = os.path.splitext(image_path)
        ext = ext.lower()

        media_type_map = {
            ".png": "image/png",
            ".jpg": "image/jpeg",
            ".jpeg": "image/jpeg",
            ".gif": "image/gif",
            ".webp": "image/webp",
        }

        media_type = media_type_map.get(ext)
        if not media_type:
            return {"error": f"Unsupported image format: {ext}"}

        # Claude API 호출
        client = Anthropic(api_key=api_key)
        message = client.messages.create(
            model="claude-3-5-sonnet-20241022",
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": media_type,
                                "data": image_data,
                            },
                        },
                        {
                            "type": "text",
                            "text": prompt,
                        },
                    ],
                }
            ],
        )

        # 응답 추출
        response_text = message.content[0].text if message.content else ""
        return {
            "success": True,
            "analysis": response_text,
        }

    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    if len(sys.argv) != 4:
        result = {"error": "Usage: python analyze_with_claude.py <image_path> <prompt> <api_key>"}
    else:
        image_path = sys.argv[1]
        prompt = sys.argv[2]
        api_key = sys.argv[3]
        result = analyze_image(image_path, prompt, api_key)

    # JSON 결과를 stdout에 출력
    print(json.dumps(result))
