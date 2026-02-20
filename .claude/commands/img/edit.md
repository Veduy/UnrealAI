---
description: 기존 이미지를 편집 (Gemini API)
allowed-tools: Bash(powershell:*), Read
argument-hint: <이미지경로> "<편집지시>" (예: output.png "모자를 추가해줘")
---

기존 이미지를 편집한다. **`.env` 파일을 직접 읽지 말 것.**

## 인자 파싱

첫 번째 인자: 이미지 파일 경로 (절대경로)
나머지: 편집 프롬프트 (+ 크기/비율 힌트)

## 프롬프트 강화

사용자의 편집 지시를 그대로 전달하지 않는다. 아래 규칙으로 **영어 프롬프트**를 작성한 뒤 전달한다.

### 강화 규칙

1. **영어로 변환**: 편집 지시를 영어로 작성.
2. **변경 범위 명시**: 무엇을 유지하고 무엇을 바꿀지 구체적으로 기술. 예: `Keep the overall composition and style. Change only the ...`
3. **한국어 텍스트 수정 시**: 정확한 글자를 `""` 안에 명시하고 `spelled exactly as shown` 을 반드시 붙인다.
4. **스타일 일관성**: `Maintain the same art style, color palette, and lighting as the original image.` 를 기본 포함.

### 크기/비율 파싱

`/img:generate`와 동일. 사용자가 크기·비율을 언급하면 `-ImageSize`, `-AspectRatio` 파라미터로 전달.

## 실행

스크립트 경로를 찾아 실행한다. 이 커맨드 파일과 같은 디렉토리의 `scripts/edit.ps1`을 사용한다.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<이 .md 파일이 있는 디렉토리>/scripts/edit.ps1" -ImagePath "이미지경로" -Prompt "강화된 편집 지시" [-ImageSize "2K"] [-AspectRatio "16:9"]
```

## 실행 후

출력에서 `이미지 저장됨: ...` 경로를 확인하고, Read 도구로 해당 이미지를 표시한다.

사용자 요청: $ARGUMENTS
