param(
    [Parameter(Mandatory=$true)]
    [string]$Prompt,
    [string]$ImageSize,
    [string]$AspectRatio
)

$ErrorActionPreference = "Stop"

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

# --- .env 파싱 ---
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

# --- 요청 JSON 생성 ---
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempReq = Join-Path $env:TEMP "img_req_$timestamp.json"
$tempResp = Join-Path $env:TEMP "img_resp_$timestamp.json"

# --- 파라미터 > .env 우선순위 ---
$finalSize = if ($ImageSize) { $ImageSize } elseif ($imageSize) { $imageSize } else { $null }
$finalRatio = if ($AspectRatio) { $AspectRatio } elseif ($aspectRatio) { $aspectRatio } else { $null }

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

[IO.File]::WriteAllText($tempReq, $reqBody, [Text.Encoding]::UTF8)

# --- API 호출 ---
Write-Output "Gemini API 호출 중... (모델: $model)"
$resp = & curl.exe -s -X POST `
    "https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent" `
    -H "x-goog-api-key: $apiKey" `
    -H "Content-Type: application/json" `
    -d "@$tempReq"

[IO.File]::WriteAllText($tempResp, $resp, [Text.Encoding]::UTF8)

# --- 응답 파싱 ---
$json = $resp | ConvertFrom-Json
if (-not $json.candidates) {
    Write-Output "API 에러 응답:"
    Write-Output $resp
    exit 1
}

$parts = $json.candidates[0].content.parts
$saved = $false
foreach ($part in $parts) {
    if ($part.text) {
        Write-Output "AI 응답: $($part.text)"
    }
    if ($part.inlineData) {
        $outFile = Join-Path $outDir "generated_$timestamp.png"
        $bytes = [Convert]::FromBase64String($part.inlineData.data)
        [IO.File]::WriteAllBytes($outFile, $bytes)
        Write-Output "이미지 저장됨: $outFile"
        $saved = $true
    }
}

if (-not $saved) {
    Write-Output "응답에 이미지가 없습니다."
}

# --- 정리 ---
Remove-Item $tempReq -ErrorAction SilentlyContinue
Remove-Item $tempResp -ErrorAction SilentlyContinue
