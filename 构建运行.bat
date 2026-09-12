@echo off
rem 本文件必须保存为 ANSI/GBK 编码：cmd 按 System ANSI 代码页解码批处理，存成 UTF-8 会乱码
title 个人刷题 - Windows 构建运行，不打包
setlocal
cd /d "%~dp0"

rem 不打包的构建运行：pub get 后直接 build + 启动，不生成 dist\
rem 与 tool\build_windows_release.ps1 相同的环境隔离：本地 Flutter SDK 与 pub 缓存，不改系统 PATH
rem 用法：无参数 = Release 构建后启动应用；参数 debug = flutter run 开发模式，支持热重载

for %%i in ("%~dp0..") do set "WORKSPACE=%%~fi"
set "PROJECT=%~dp0"
if "%PROJECT:~-1%"=="\" set "PROJECT=%PROJECT:~0,-1%"
set "FLUTTER=%WORKSPACE%\.tooling\flutter-3.47.1\bin\flutter.bat"
if not exist "%FLUTTER%" set "FLUTTER=%WORKSPACE%\.tooling\flutter\bin\flutter.bat"
set "PUB_CACHE=%WORKSPACE%\.tooling\pub-cache"
set "FLUTTER_SUPPRESS_ANALYTICS=true"
set "GIT_CONFIG_COUNT=3"
set "GIT_CONFIG_KEY_0=safe.directory"
set "GIT_CONFIG_VALUE_0=%WORKSPACE:\=/%/.tooling/flutter-3.47.1"
set "GIT_CONFIG_KEY_1=safe.directory"
set "GIT_CONFIG_VALUE_1=%WORKSPACE:\=/%/.tooling/flutter"
set "GIT_CONFIG_KEY_2=safe.directory"
set "GIT_CONFIG_VALUE_2=%PROJECT:\=/%"

set "EXE=%~dp0build\windows\x64\runner\Release\personal_exam_app.exe"

if not exist "%FLUTTER%" (
    echo [错误] 找不到本地 Flutter SDK：%FLUTTER%
    pause
    exit /b 1
)

rem 从 pubspec.yaml 读取版本号并注入 APP_VERSION，与正式包显示一致
set "APPVER="
for /f "tokens=2 delims=+ " %%v in ('findstr /b /l /c:"version:" pubspec.yaml') do set "APPVER=%%v"
set "DARTDEFINE="
if not "%APPVER%"=="" set "DARTDEFINE=--dart-define=APP_VERSION=%APPVER%"

echo ==============================================
echo  个人刷题 Windows 构建运行，不打包
echo  无参数：Release 构建后直接启动应用
echo  传 debug：flutter run 开发模式，支持热重载
echo ==============================================
echo  Flutter：%FLUTTER%
echo  版本号：%APPVER%
echo.

echo [1/2] flutter pub get ...
call "%FLUTTER%" pub get
if errorlevel 1 (
    echo [失败] pub get 未通过，见上方日志。
    pause
    exit /b 1
)

if /i "%~1"=="debug" goto :debug

echo.
echo [2/2] flutter build windows --release ...
call "%FLUTTER%" build windows --release %DARTDEFINE%
if errorlevel 1 (
    echo [失败] Release 构建未通过，见上方日志。
    pause
    exit /b 1
)

if not exist "%EXE%" (
    echo [错误] 构建产物缺失：%EXE%
    pause
    exit /b 1
)

echo.
echo 构建完成，正在启动：%EXE%
start "" "%EXE%"
exit /b 0

:debug
echo.
echo [2/2] flutter run -d windows 开发模式，按 q 或关闭窗口结束。
call "%FLUTTER%" run -d windows %DARTDEFINE%
if errorlevel 1 pause
exit /b %ERRORLEVEL%
