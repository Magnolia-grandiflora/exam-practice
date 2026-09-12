param(
    [switch]$SkipTests,
    [string]$AndroidToolchain = '',
    [string]$Flutter = ''
)

$ErrorActionPreference = 'Stop'
$project = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$workspace = (Resolve-Path (Join-Path $project '..')).Path
$AndroidToolchain = if ($AndroidToolchain) {
    (Resolve-Path -LiteralPath $AndroidToolchain).Path
} else {
    Join-Path $workspace '.android-toolchain'
}
$flutterRoot = if ($Flutter) { (Resolve-Path -LiteralPath $Flutter).Path } else {
    # 优先使用独立安装的新版 Flutter SDK（flutter-<版本>），旧目录仅作回退。
    $candidates = @(
        (Join-Path $workspace '.tooling\flutter-3.47.1'),
        (Join-Path $workspace '.tooling\flutter')
    )
    $found = $candidates | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'bin\flutter.bat') -PathType Leaf } | Select-Object -First 1
    if (-not $found) { throw "未找到可用的 Flutter SDK，请用 -Flutter 显式指定路径" }
    $found
}
$dart = Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'
$flutterTools = Join-Path $flutterRoot 'bin\cache\flutter_tools.snapshot'
$sdk = Join-Path $AndroidToolchain 'sdk'
$jdk = Join-Path $AndroidToolchain 'jdk\jdk-17.0.20+8'
$gradleHome = Join-Path $AndroidToolchain 'gradle-home'

foreach ($required in @(
    (Join-Path $flutterRoot 'bin\cache\flutter_tools.snapshot'),
    (Join-Path $flutterRoot 'bin\cache\dart-sdk\bin\dart.exe'),
    $sdk,
    $jdk,
    $gradleHome
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Android 构建依赖不存在：$required"
    }
}
try {
    $env:FLUTTER_ROOT = $flutterRoot
    $env:FLUTTER_ALREADY_LOCKED = 'true'
    $env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
    $env:PUB_CACHE = Join-Path $workspace '.tooling\pub-cache'
    $env:GIT_CONFIG_COUNT = '2'
    $env:GIT_CONFIG_KEY_0 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_0 = ($flutterRoot -replace '\\', '/')
    $env:GIT_CONFIG_KEY_1 = 'safe.directory'
    $env:GIT_CONFIG_VALUE_1 = ($project -replace '\\', '/')
    $env:ANDROID_HOME = $sdk
    $env:ANDROID_SDK_ROOT = $sdk
    $env:JAVA_HOME = $jdk
    $env:GRADLE_USER_HOME = $gradleHome

    Push-Location $project
    $versionLine = (Select-String -LiteralPath (Join-Path $project 'pubspec.yaml') -Pattern '^version:\s*').Line
    $version = (($versionLine -replace '^version:\s*', '') -split '\+')[0]
    if (-not $version) { throw '无法从 pubspec.yaml 读取版本号' }
    & $dart $flutterTools clean
    if ($LASTEXITCODE -ne 0) { throw 'flutter clean 失败' }
    & $dart $flutterTools pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get 失败' }
    if (-not $SkipTests) {
        & $dart $flutterTools analyze
        if ($LASTEXITCODE -ne 0) { throw 'flutter analyze 失败' }
        & $dart $flutterTools test
        if ($LASTEXITCODE -ne 0) { throw 'flutter test 失败' }
    }
    & $dart $flutterTools build apk --release --dart-define=APP_VERSION=$version
    if ($LASTEXITCODE -ne 0) { throw 'flutter build apk --release 失败' }
} finally {
    Pop-Location -ErrorAction SilentlyContinue
}

$source = Join-Path $project 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path -LiteralPath $source)) { throw "APK 未生成：$source" }
$dist = Join-Path $project 'dist'
$target = Join-Path $dist "ExamPractice-Android-$version-test-signed.apk"
New-Item -ItemType Directory -Path $dist -Force | Out-Null
Copy-Item -LiteralPath $source -Destination $target -Force

Get-Item -LiteralPath $target
Get-FileHash -LiteralPath $target -Algorithm SHA256
