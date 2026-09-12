param(
    [switch]$SkipTests,
    [switch]$SkipFlutterBuild,
    [switch]$SkipSidecarBuild,
    [string]$Flutter,
    [string]$Python = 'python'
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspace = (Resolve-Path (Join-Path $project '..')).Path
$flutter = if ($Flutter) { $Flutter } else {
    # 优先使用独立安装的新版 Flutter SDK（flutter-<版本>），旧目录仅作回退。
    $candidates = @(
        (Join-Path $workspace '.tooling\flutter-3.47.1\bin\flutter.bat'),
        (Join-Path $workspace '.tooling\flutter\bin\flutter.bat')
    )
    $found = $candidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
    if (-not $found) { throw "未找到可用的 Flutter SDK，请用 -Flutter 显式指定路径" }
    $found
}
if (-not (Test-Path -LiteralPath $flutter -PathType Leaf)) {
    throw "Flutter executable not found: $flutter"
}
$flutterRoot = (Resolve-Path (Join-Path (Split-Path -Parent $flutter) '..')).Path
$env:PUB_CACHE = Join-Path $workspace '.tooling\pub-cache'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:GIT_CONFIG_COUNT = '2'
$env:GIT_CONFIG_KEY_0 = 'safe.directory'
$env:GIT_CONFIG_VALUE_0 = ($flutterRoot -replace '\\', '/')
$env:GIT_CONFIG_KEY_1 = 'safe.directory'
$env:GIT_CONFIG_VALUE_1 = ($project -replace '\\', '/')

$versionLine = (Select-String -LiteralPath (Join-Path $project 'pubspec.yaml') -Pattern '^version:\s*').Line
$version = (($versionLine -replace '^version:\s*', '') -split '\+')[0]
if (-not $version) { throw '无法从 pubspec.yaml 读取版本号' }

if (-not $SkipFlutterBuild) {
    try {
        Push-Location $project

        & $flutter clean
        if ($LASTEXITCODE -ne 0) { throw 'flutter clean 失败' }
        & $flutter pub get
        if ($LASTEXITCODE -ne 0) { throw 'flutter pub get 失败' }
        if (-not $SkipTests) {
            & $flutter analyze
            if ($LASTEXITCODE -ne 0) { throw 'flutter analyze 失败' }
            & $flutter test
            if ($LASTEXITCODE -ne 0) { throw 'flutter test 失败' }
        }
        & $flutter build windows --release --dart-define=APP_VERSION=$version
        if ($LASTEXITCODE -ne 0) { throw 'flutter build windows --release 失败' }
    } finally {
        Pop-Location -ErrorAction SilentlyContinue
    }
}

$release = Join-Path $project 'build\windows\x64\runner\Release'
$exe = Join-Path $release 'personal_exam_app.exe'
$omrBridge = Join-Path $release 'paper_omr_bridge.exe'
$thirdPartyNotices = Join-Path $release 'THIRD_PARTY_NOTICES.md'
$sqliteDll = Join-Path $release 'sqlite3.dll'
$nativeAssetsManifest = Join-Path $release 'data\flutter_assets\NativeAssetsManifest.json'
foreach ($requiredFile in @($exe, $sqliteDll, $nativeAssetsManifest)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Windows 发布产物缺少必需文件：$requiredFile"
    }
}
$projectBridgeSource = Join-Path $project 'tool\paper_omr_bridge'
if (-not (Test-Path -LiteralPath (Join-Path $projectBridgeSource 'paper_omr_bridge.py') -PathType Leaf)) {
    throw 'paper OMR bridge source is missing.'
}
if (-not $SkipSidecarBuild) {
    & (Join-Path $projectBridgeSource 'build_sidecar.ps1') -OutputPath $omrBridge -Python $Python
    if ($LASTEXITCODE -ne 0) { throw 'paper OMR sidecar build failed' }
} elseif (-not (Test-Path -LiteralPath $omrBridge -PathType Leaf)) {
    throw 'Cannot skip the paper OMR sidecar build because the executable is missing.'
}
$omrBridgeSource = Join-Path $release 'paper-omr-bridge-source'
Copy-Item -LiteralPath (Join-Path $project 'LICENSE') -Destination (Join-Path $release 'LICENSE') -Force
& $Python (Join-Path $projectBridgeSource 'collect_licenses.py') `
    --runtime (Join-Path $projectBridgeSource 'runtime-build') `
    --output (Join-Path $release 'licenses\python')
if ($LASTEXITCODE -ne 0) { throw 'Cannot collect sidecar dependency license texts.' }
New-Item -ItemType Directory -Path $omrBridgeSource -Force | Out-Null
foreach ($bridgeSourceFile in @('paper_omr_bridge.py', 'requirements.lock', 'constraints.lock', 'build_sidecar.ps1', 'collect_licenses.py', 'test_paper_omr_contract.py', 'test_paper_omr_synthetic.py')) {
    Copy-Item -LiteralPath (Join-Path $projectBridgeSource $bridgeSourceFile) `
        -Destination (Join-Path $omrBridgeSource $bridgeSourceFile) -Force
}
Copy-Item -LiteralPath (Join-Path $project 'THIRD_PARTY_NOTICES.md') -Destination $thirdPartyNotices -Force
foreach ($requiredFile in @($omrBridge, $thirdPartyNotices)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Windows runtime is missing paper OMR material: $requiredFile"
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $omrBridgeSource 'paper_omr_bridge.py') -PathType Leaf)) {
    throw 'Windows runtime is missing the corresponding paper OMR bridge source.'
}
foreach ($sourceFile in @(
    (Join-Path $projectBridgeSource 'requirements.lock'),
    (Join-Path $projectBridgeSource 'constraints.lock')
)) {
    if ((Get-Content -LiteralPath $sourceFile -Raw) -match '(?i)(pymupdf|fitz)') {
        throw "Forbidden PDF dependency found: $sourceFile"
    }
}
$forbiddenRuntimeNames = Get-ChildItem -LiteralPath $release -Recurse -File |
    Where-Object { $_.Name -match '(?i)(pymupdf|fitz)' }
if ($forbiddenRuntimeNames) {
    throw "Forbidden PDF runtime material found: $($forbiddenRuntimeNames.FullName -join ', ')"
}
$nativeAssetsText = Get-Content -LiteralPath $nativeAssetsManifest -Raw
if ($nativeAssetsText -notmatch 'package:sqlite3/src/ffi/libsqlite3\.g\.dart' -or
    $nativeAssetsText -notmatch 'sqlite3\.dll') {
    throw 'Windows NativeAssetsManifest.json 缺少 sqlite3.dll 映射，停止生成发布包'
}
$distRoot = Join-Path $project 'dist'
$packageName = "ExamPractice-Windows-x64-$version"
$packageDir = Join-Path $distRoot $packageName
$packageZip = Join-Path $distRoot "$packageName.zip"
$stageDir = Join-Path $distRoot ".stage-$([guid]::NewGuid().ToString('N'))"
$stageZip = Join-Path $distRoot ".stage-$([guid]::NewGuid().ToString('N')).zip"
New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
try {
    Copy-Item -Path (Join-Path $release '*') -Destination $stageDir -Recurse -Force
    Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $stageZip -CompressionLevel Optimal
    foreach ($target in @($packageDir, $packageZip)) {
        $full = [IO.Path]::GetFullPath($target)
        if (-not $full.StartsWith(([IO.Path]::GetFullPath($distRoot) + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) {
            throw "分发目标不在 dist 内：$full"
        }
    }
    if (Test-Path -LiteralPath $packageDir) { Remove-Item -LiteralPath $packageDir -Recurse -Force }
    if (Test-Path -LiteralPath $packageZip) { Remove-Item -LiteralPath $packageZip -Force }
    Move-Item -LiteralPath $stageDir -Destination $packageDir
    Move-Item -LiteralPath $stageZip -Destination $packageZip
} finally {
    if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
    if (Test-Path -LiteralPath $stageZip) { Remove-Item -LiteralPath $stageZip -Force }
}

Get-Item -LiteralPath $exe
Get-Item -LiteralPath $packageZip
