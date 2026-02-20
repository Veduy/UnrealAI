---
description: 투명 배경 PNG 이미지 생성 (Two-Pass Alpha Extraction)
allowed-tools: Bash(powershell:*), Bash(python*), Read
argument-hint: <프롬프트> (예: 고양이 캐릭터 아이콘)
---

텍스트 프롬프트로 **투명 배경 PNG**를 생성한다. **`.env` 파일을 직접 읽지 말 것.**

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
6. **배경 지시 제거**: 사용자 프롬프트에서 배경 관련 언급(배경색, background, 배경 등)을 모두 제거한다.
7. **회색 배경 강제**: 프롬프트 끝에 `"on a plain solid neutral gray (#808080) background"` 를 자동 추가한다.

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
| 언급 없음 | 기본 `-AspectRatio "1:1"` 추가 (스프라이트/아이콘 기본값) |

## 실행

스크립트 경로를 찾아 실행한다. 이 커맨드 파일과 같은 디렉토리의 `scripts/transparent.ps1`을 사용한다.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<이 .md 파일이 있는 디렉토리>/scripts/transparent.ps1" -Prompt "강화된 프롬프트" [-ImageSize "2K"] [-AspectRatio "1:1"]
```

`-ImageSize`와 `-AspectRatio`는 사용자가 명시한 경우에만 추가. 단, `-AspectRatio`는 사용자가 명시하지 않아도 기본 `"1:1"` 을 추가한다.

## 실행 후

출력에서 `최종 투명 PNG: ...` 경로를 확인하고, Read 도구로 해당 이미지를 표시한다.

중간 결과물(base, white, black)도 출력에 경로가 표시되므로 사용자에게 안내한다.

사용자 요청: $ARGUMENTS
