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
$projectRoot = if ($envFile) { Split-Path $envFile -Parent } else { $null }

Write-Output "=== Gemini API 상태 ==="
Write-Output ""

# --- .env 파싱 ---
$apiKey = $null
$outPath = $null
$model = $null
$imageSize = $null
$aspectRatio = $null
if ($envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^GEMINI_API_KEY=(.+)$') { $apiKey = $matches[1].Trim() }
        if ($_ -match '^NANO_BANANA_OUTPUT=(.+)$') { $outPath = $matches[1].Trim() }
        if ($_ -match '^GEMINI_MODEL=(.+)$') { $model = $matches[1].Trim() }
        if ($_ -match '^GEMINI_IMAGE_SIZE=(.+)$') { $imageSize = $matches[1].Trim() }
        if ($_ -match '^GEMINI_ASPECT_RATIO=(.+)$') { $aspectRatio = $matches[1].Trim() }
    }
} else {
    Write-Output ".env 파일 없음"
}
if (-not $model) { $model = "gemini-2.5-flash-image" }

# --- API 키 확인 (값은 출력하지 않음) ---
if ($apiKey) {
    Write-Output "GEMINI_API_KEY: 설정됨 (길이: $($apiKey.Length))"
} else {
    Write-Output "GEMINI_API_KEY: 미설정"
}

# --- 출력 디렉토리 결정 ---
if ($outPath -and $projectRoot) {
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

Write-Output "GEMINI_MODEL: $model"
Write-Output "GEMINI_IMAGE_SIZE: $(if ($imageSize) { $imageSize } else { '미설정 (API 기본값)' })"
Write-Output "GEMINI_ASPECT_RATIO: $(if ($aspectRatio) { $aspectRatio } else { '미설정 (API 기본값)' })"
Write-Output ""
Write-Output ".env 위치: $(if ($envFile) { $envFile } else { '찾을 수 없음' })"
Write-Output "NANO_BANANA_OUTPUT: $(if ($outPath) { $outPath } else { '미설정 (기본값: %APPDATA%\nano-banana)' })"
Write-Output "출력 디렉토리: $outDir"
Write-Output ""

# --- 최근 이미지 목록 ---
if (Test-Path $outDir) {
    $files = Get-ChildItem "$outDir\*" -Include *.png,*.jpg,*.jpeg,*.webp |
        Sort-Object LastWriteTime -Descending | Select-Object -First 5
    if ($files) {
        Write-Output "최근 이미지 ($($files.Count)개):"
        $files | Format-Table Name, @{L='Size(KB)';E={[math]::Round($_.Length/1024,1)}}, LastWriteTime -AutoSize
    } else {
        Write-Output "이미지 파일 없음"
    }
} else {
    Write-Output "출력 디렉토리 없음 (아직 이미지를 생성하지 않음)"
}
