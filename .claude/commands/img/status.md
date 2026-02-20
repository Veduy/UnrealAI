---
description: Gemini API 키 상태 및 최근 이미지 확인
allowed-tools: Bash(powershell:*)
argument-hint: (인자 없음)
---

API 키 상태와 최근 이미지를 확인한다. **`.env` 파일을 직접 읽지 말 것.**

## 실행

스크립트 경로를 찾아 실행한다. 이 커맨드 파일과 같은 디렉토리의 `scripts/status.ps1`을 사용한다.

```
powershell -NoProfile -ExecutionPolicy Bypass -File "<이 .md 파일이 있는 디렉토리>/scripts/status.ps1"
```

## 키 미설정 시 안내

> 1. [Google AI Studio](https://aistudio.google.com/apikey)에서 API 키를 발급하세요.
> 2. 프로젝트 루트에 `.env` 파일을 생성하세요:
>    ```
>    GEMINI_API_KEY=your-api-key-here
>    GEMINI_MODEL=gemini-2.5-flash-image
>    GEMINI_IMAGE_SIZE=1K
>    GEMINI_ASPECT_RATIO=1:1
>    NANO_BANANA_OUTPUT=./
>    ```
>
> **GEMINI_MODEL** 선택 가능 모델:
> | 모델 | 특징 |
> |------|------|
> | `gemini-2.5-flash-image` | 기본값. 빠르고 저렴 |
> | `gemini-3-pro-image-preview` | 최고 품질. 텍스트 렌더링 우수, 느리고 비쌈 |
>
> **GEMINI_IMAGE_SIZE** 이미지 크기 (gemini-3 모델 권장):
> | 값 | 설명 |
> |----|------|
> | 미설정 | API 기본값 |
> | `1K` | 1024px 급 (저렴) |
> | `2K` | 2048px 급 |
> | `4K` | 4096px 급 (비쌈, $0.24/장) |
>
> **GEMINI_ASPECT_RATIO** 이미지 비율:
> | 값 | 용도 |
> |----|------|
> | 미설정 | API 기본값 (보통 1:1) |
> | `1:1` | 정사각형 (아이콘, 스티커) |
> | `16:9` | 가로 와이드 (타이틀, 배경) |
> | `9:16` | 세로 (모바일 배경) |
> | `4:3` | 가로 (일반) |
> | `3:4` | 세로 (일반) |
>
> **NANO_BANANA_OUTPUT** 출력 경로:
> - `./` → 프로젝트 루트
> - `./assets/img` → 프로젝트 내 하위 폴더
> - 미설정 → `%APPDATA%\nano-banana\`
>
> `.env`는 `.gitignore`에 등록되어 있어 커밋되지 않습니다.

사용자 요청: $ARGUMENTS
