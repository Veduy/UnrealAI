---
description: 텍스트 프롬프트로 이미지 생성 (Gemini API)
allowed-tools: Bash(powershell:*)
argument-hint: <프롬프트> (예: 고양이 빵집 타이틀 16:9 4K)
---

텍스트 프롬프트로 이미지를 생성한다. **`.env` 파일을 직접 읽지 말 것.**

## 프롬프트 강화

사용자의 요청을 그대로 전달하지 않는다. 아래 규칙으로 **영어 프롬프트**를 작성한 뒤 전달한다.

### 강화 규칙

1. **영어로 변환**: 모든 프롬프트는 영어로 작성. 한국어 텍스트가 이미지에 필요하면 `with Korean text "텍스트"` 형태로 명시.
2. **구체적 묘사 추가**: 사용자가 간략히 요청해도 다음을 보충:
   - 화면 구성 (전경/중경/배경 레이어)
   - 조명과 분위기 (lighting, mood)
   - 아트 스타일 (예: cel-shaded, watercolor, pixel art, semi-chibi)
   - 색감/팔레트 (warm tones, pastel, vibrant)
3. **한국어 텍스트 정확성**: 이미지 내 한국어가 필요하면 정확한 글자를 `""` 안에 명시하고, `spelled exactly as shown` 을 반드시 붙인다.
4. **부정 지시**: 원치 않는 요소가 있으면 `Do NOT include ...` 로 명시.
5. **품질 부스터**: 마지막에 `high quality, detailed, professional illustration` 등 품질 키워드를 추가.

### 크기/비율 파싱

사용자 요청에서 크기·비율 힌트가 있으면 별도 파라미터로 전달한다. **프롬프트 텍스트에는 크기/비율을 넣지 않는다.**

| 사용자 표현 | 파라미터 |
|------------|---------|
| "4K", "고해상도" | `-ImageSize "4K"` |
| "2K" | `-ImageSize "2K"` |
| "1K", "작게" | `-ImageSize "1K"` |
| "16:9", "와이드", "가로" | `-AspectRatio "16:9"` |
| "9:16", "세로" | `-AspectRatio "9:16"` |
| "4:3" | `-AspectRatio "4:3"` |
| "3:4" | `-AspectRatio "3:4"` |
| "정사각형", "1:1" | `-AspectRatio "1:1"` |
| 언급 없음 | 파라미터 생략 (.env 기본값 사용) |

## 실행

스크립트 경로를 찾아 실행한다. 이 커맨드 파일과 같은 디렉토리의 `scripts/generate.ps1`을 사용한다.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<이 .md 파일이 있는 디렉토리>/scripts/generate.ps1" -Prompt "강화된 프롬프트" [-ImageSize "2K"] [-AspectRatio "16:9"]
```

`-ImageSize`와 `-AspectRatio`는 사용자가 명시한 경우에만 추가.

## 실행 후

출력에서 `이미지 저장됨: ...` 경로를 확인하고, Read 도구로 해당 이미지를 표시한다.

사용자 요청: $ARGUMENTS
