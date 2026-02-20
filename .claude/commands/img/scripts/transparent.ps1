param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,
    [string]$ImageSize,
    [string]$AspectRatio
)

$ErrorActionPreference = "Stop"

# === Step 0: Python 의존성 체크 ===
Write-Output "[Step 0] Python 의존성 확인 중..."
$pyCheck = & python -c "from PIL import Image; import numpy; print('OK')" 2>&1
if ($pyCheck -ne "OK") {
    Write-Error "Python, Pillow, numpy가 필요합니다. pip install Pillow numpy"
    exit 1
}
Write-Output "[Step 0] Python 의존성 확인 완료."

# --- .env 탐색: $PSScriptRoot에서 상위로 올라가며 .env 파일 찾기 ---
function Find-EnvFile {
    $dir = $PSScriptRoot
    while ($dir) {
        $candidate = Join-Path $dir ".env"
        if (Test-Path $candidate) { return $candidate }
        $parent = Split-Path $dir -Parent
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

$envFile = Find-EnvFile
if (-not $envFile) {
    Write-Error ".env 파일이 없습니다. /img:status 를 실행하세요."
    exit 1
}
$projectRoot = Split-Path $envFile -Parent

# === .env 파싱 ===
$apiKey = $null
$outPath = $null
$model = $null
$imageSize = $null
$aspectRatio = $null
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^GEMINI_API_KEY=(.+)$') { $apiKey = $matches[1].Trim() }
    if ($_ -match '^NANO_BANANA_OUTPUT=(.+)$') { $outPath = $matches[1].Trim() }
    if ($_ -match '^GEMINI_MODEL=(.+)$') { $model = $matches[1].Trim() }
    if ($_ -match '^GEMINI_IMAGE_SIZE=(.+)$') { $imageSize = $matches[1].Trim() }
    if ($_ -match '^GEMINI_ASPECT_RATIO=(.+)$') { $aspectRatio = $matches[1].Trim() }
}
if (-not $apiKey) {
    Write-Error ".env 파일에 GEMINI_API_KEY가 없습니다."
    exit 1
}
if (-not $model) { $model = "gemini-2.5-flash-image" }

# --- 출력 디렉토리 결정 ---
if ($outPath) {
    if ($outPath.StartsWith("./") -or $outPath.StartsWith(".\")) {
        $outDir = Join-Path $projectRoot ($outPath.Substring(2))
    } elseif ([IO.Path]::IsPathRooted($outPath)) {
        $outDir = $outPath
    } else {
        $outDir = Join-Path $projectRoot $outPath
    }
} else {
    $outDir = Join-Path $env:APPDATA "nano-banana"
}
if (-not (Test-Path $outDir -PathType Container)) {
    if (Test-Path $outDir -PathType Leaf) { Remove-Item $outDir -Force }
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}

# --- 파라미터 > .env 우선순위 ---
$finalSize = if ($ImageSize) { $ImageSize } elseif ($imageSize) { $imageSize } else { $null }
$finalRatio = if ($AspectRatio) { $AspectRatio } elseif ($aspectRatio) { $aspectRatio } else { $null }

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$scriptDir = $PSScriptRoot

# ============================================================
# Step 1: Base 생성 (generate)
# ============================================================
Write-Output ""
Write-Output "[Step 1] Base 이미지 생성 중..."

$tempReq1 = Join-Path $env:TEMP "img_trans_req1_$timestamp.json"
$tempResp1 = Join-Path $env:TEMP "img_trans_resp1_$timestamp.json"

$genConfig = @{ responseModalities = @("TEXT", "IMAGE") }
$imgConfig = @{}
if ($finalSize) { $imgConfig["imageSize"] = $finalSize }
if ($finalRatio) { $imgConfig["aspectRatio"] = $finalRatio }
if ($imgConfig.Count -gt 0) { $genConfig["imageConfig"] = $imgConfig }

$reqBody = @{
    contents = @(@{
        parts = @(@{ text = $Prompt })
    })
    generationConfig = $genConfig
} | ConvertTo-Json -Depth 10 -Compress

[IO.File]::WriteAllText($tempReq1, $reqBody, [Text.Encoding]::UTF8)

Write-Output "Gemini API 호출 중... (모델: $model)"
$resp = & curl.exe -s -X POST `
    "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" `
    -H "x-goog-api-key: $apiKey" `
    -H "Content-Type: application/json" `
    -d "@$tempReq1"

[IO.File]::WriteAllText($tempResp1, $resp, [Text.Encoding]::UTF8)

$json = $resp | ConvertFrom-Json
if (-not $json.candidates) {
    Write-Output "API 에러 응답:"
    Write-Output $resp
    Remove-Item $tempReq1 -ErrorAction SilentlyContinue
    Remove-Item $tempResp1 -ErrorAction SilentlyContinue
    exit 1
}

$parts = $json.candidates[0].content.parts
$baseFile = $null
foreach ($part in $parts) {
    if ($part.text) {
        Write-Output "AI 응답: $($part.text)"
    }
    if ($part.inlineData) {
        $baseFile = Join-Path $outDir "transparent_${timestamp}_base.png"
        $bytes = [Convert]::FromBase64String($part.inlineData.data)
        [IO.File]::WriteAllBytes($baseFile, $bytes)
        Write-Output "Base 이미지 저장됨: $baseFile"
    }
}

Remove-Item $tempReq1 -ErrorAction SilentlyContinue
Remove-Item $tempResp1 -ErrorAction SilentlyContinue

if (-not $baseFile) {
    Write-Error "[Step 1] 응답에 이미지가 없습니다."
    exit 1
}

# ============================================================
# Step 2: White 배경 변환 (edit)
# ============================================================
Write-Output ""
Write-Output "[Step 2] White 배경 변환 중..."

$tempReq2 = Join-Path $env:TEMP "img_trans_req2_$timestamp.json"
$tempResp2 = Join-Path $env:TEMP "img_trans_resp2_$timestamp.json"

$imgBytes = [IO.File]::ReadAllBytes($baseFile)
$imgBase64 = [Convert]::ToBase64String($imgBytes)

$whitePrompt = "Change ONLY the background to pure solid white (#FFFFFF). Do NOT move, resize, rotate, or modify the subject in any way. Keep every detail of the subject pixel-perfect identical. The subject must remain in the exact same position."

$genConfig2 = @{ responseModalities = @("TEXT", "IMAGE") }
$imgConfig2 = @{}
if ($finalSize) { $imgConfig2["imageSize"] = $finalSize }
if ($finalRatio) { $imgConfig2["aspectRatio"] = $finalRatio }
if ($imgConfig2.Count -gt 0) { $genConfig2["imageConfig"] = $imgConfig2 }

$reqBody2 = @{
    contents = @(@{
        parts = @(
            @{ text = $whitePrompt }
            @{ inlineData = @{ mimeType = "image/png"; data = $imgBase64 } }
        )
    })
    generationConfig = $genConfig2
} | ConvertTo-Json -Depth 10 -Compress

[IO.File]::WriteAllText($tempReq2, $reqBody2, [Text.Encoding]::UTF8)

Write-Output "Gemini API 호출 중... (모델: $model, white 배경 변환)"
$resp2 = & curl.exe -s -X POST `
    "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" `
    -H "x-goog-api-key: $apiKey" `
    -H "Content-Type: application/json" `
    -d "@$tempReq2"

[IO.File]::WriteAllText($tempResp2, $resp2, [Text.Encoding]::UTF8)

$json2 = $resp2 | ConvertFrom-Json
if (-not $json2.candidates) {
    Write-Output "API 에러 응답:"
    Write-Output $resp2
    Remove-Item $tempReq2 -ErrorAction SilentlyContinue
    Remove-Item $tempResp2 -ErrorAction SilentlyContinue
    exit 1
}

$parts2 = $json2.candidates[0].content.parts
$whiteFile = $null
foreach ($part in $parts2) {
    if ($part.text) {
        Write-Output "AI 응답: $($part.text)"
    }
    if ($part.inlineData) {
        $whiteFile = Join-Path $outDir "transparent_${timestamp}_white.png"
        $bytes = [Convert]::FromBase64String($part.inlineData.data)
        [IO.File]::WriteAllBytes($whiteFile, $bytes)
        Write-Output "White 배경 이미지 저장됨: $whiteFile"
    }
}

Remove-Item $tempReq2 -ErrorAction SilentlyContinue
Remove-Item $tempResp2 -ErrorAction SilentlyContinue

if (-not $whiteFile) {
    Write-Error "[Step 2] 응답에 이미지가 없습니다."
    exit 1
}

# ============================================================
# Step 3: Black 배경 변환 (edit)
# ============================================================
Write-Output ""
Write-Output "[Step 3] Black 배경 변환 중..."

$tempReq3 = Join-Path $env:TEMP "img_trans_req3_$timestamp.json"
$tempResp3 = Join-Path $env:TEMP "img_trans_resp3_$timestamp.json"

$blackPrompt = "Change ONLY the background to pure solid black (#000000). Do NOT move, resize, rotate, or modify the subject in any way. Keep every detail of the subject pixel-perfect identical. The subject must remain in the exact same position."

$genConfig3 = @{ responseModalities = @("TEXT", "IMAGE") }
$imgConfig3 = @{}
if ($finalSize) { $imgConfig3["imageSize"] = $finalSize }
if ($finalRatio) { $imgConfig3["aspectRatio"] = $finalRatio }
if ($imgConfig3.Count -gt 0) { $genConfig3["imageConfig"] = $imgConfig3 }

$reqBody3 = @{
    contents = @(@{
        parts = @(
            @{ text = $blackPrompt }
            @{ inlineData = @{ mimeType = "image/png"; data = $imgBase64 } }
        )
    })
    generationConfig = $genConfig3
} | ConvertTo-Json -Depth 10 -Compress

[IO.File]::WriteAllText($tempReq3, $reqBody3, [Text.Encoding]::UTF8)

Write-Output "Gemini API 호출 중... (모델: $model, black 배경 변환)"
$resp3 = & curl.exe -s -X POST `
    "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" `
    -H "x-goog-api-key: $apiKey" `
    -H "Content-Type: application/json" `
    -d "@$tempReq3"

[IO.File]::WriteAllText($tempResp3, $resp3, [Text.Encoding]::UTF8)

$json3 = $resp3 | ConvertFrom-Json
if (-not $json3.candidates) {
    Write-Output "API 에러 응답:"
    Write-Output $resp3
    Remove-Item $tempReq3 -ErrorAction SilentlyContinue
    Remove-Item $tempResp3 -ErrorAction SilentlyContinue
    exit 1
}

$parts3 = $json3.candidates[0].content.parts
$blackFile = $null
foreach ($part in $parts3) {
    if ($part.text) {
        Write-Output "AI 응답: $($part.text)"
    }
    if ($part.inlineData) {
        $blackFile = Join-Path $outDir "transparent_${timestamp}_black.png"
        $bytes = [Convert]::FromBase64String($part.inlineData.data)
        [IO.File]::WriteAllBytes($blackFile, $bytes)
        Write-Output "Black 배경 이미지 저장됨: $blackFile"
    }
}

Remove-Item $tempReq3 -ErrorAction SilentlyContinue
Remove-Item $tempResp3 -ErrorAction SilentlyContinue

if (-not $blackFile) {
    Write-Error "[Step 3] 응답에 이미지가 없습니다."
    exit 1
}

# ============================================================
# Step 4: Alpha 추출 (python)
# ============================================================
Write-Output ""
Write-Output "[Step 4] Alpha 채널 추출 중..."

$finalFile = Join-Path $outDir "transparent_${timestamp}.png"

& python "$scriptDir\alpha_extract.py" "$whiteFile" "$blackFile" "$finalFile"

if ($LASTEXITCODE -ne 0) {
    Write-Error "[Step 4] Alpha 추출 실패."
    exit 1
}

Write-Output ""
Write-Output "최종 투명 PNG: $finalFile"
