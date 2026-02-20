---
description: 마지막 생성/편집 이미지를 계속 편집 (Gemini API)
allowed-tools: Bash(powershell:*), Read
argument-hint: <편집지시> (예: "배경을 파란색으로 바꿔줘 16:9")
---

가장 최근 이미지를 찾아 편집한다. **`.env` 파일을 직접 읽지 말 것.**

## 프롬프트 강화

`/img:edit`와 동일한 강화 규칙 적용:

1. **영어로 변환**
2. **변경 범위 명시**: 유지할 것과 바꿀 것을 구체적으로 기술.
3. **한국어 텍스트 수정 시**: `"정확한 글자" spelled exactly as shown`
4. **스타일 일관성**: `Maintain the same art style, color palette, and lighting.`

### 크기/비율 파싱

`/img:generate`와 동일. 사용자가 크기·비율을 언급하면 `-ImageSize`, `-AspectRatio` 파라미터로 전달.

## 실행

스크립트 경로를 찾아 실행한다. 이 커맨드 파일과 같은 디렉토리의 `scripts/continue.ps1`을 사용한다.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<이 .md 파일이 있는 디렉토리>/scripts/continue.ps1" -Prompt "강화된 편집 지시" [-ImageSize "2K"] [-AspectRatio "16:9"]
```

## 실행 후

출력에서 `이미지 저장됨: ...` 경로를 확인하고, Read 도구로 해당 이미지를 표시한다.

사용자 요청: $ARGUMENTS
