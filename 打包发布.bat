@echo off
rem 本文件必须保存为 ANSI/GBK 编码：cmd 按 System ANSI 代码页解码批处理，存成 UTF-8 会乱码
title 个人刷题 - Windows 打包发布
setlocal
cd /d "%~dp0"

rem 一键打包：实际流程复用 tool\build_windows_release.ps1
rem 即 clean、pub get、test、build windows --release、sidecar 打包、dist\ 目录与 zip
rem 额外参数原样透传给 ps1，例如：-SkipTests -SkipSidecarBuild

set "PS1=%~dp0tool\build_windows_release.ps1"

if not exist "%PS1%" (
    echo [错误] 找不到发布脚本：%PS1%
    pause
    exit /b 1
)

rem sidecar 打包使用工作区独立的 Python 3.14 venv（.tooling\py3147-sidecar-venv）
rem 命令行参数里已带 -Python 时不重复注入
set "PYSIDECAR=%~dp0..\.tooling\py3147-sidecar-venv\Scripts\python.exe"
set "PYARG="
if exist "%PYSIDECAR%" set "PYARG=-Python "%PYSIDECAR%""
echo(%*|findstr /i /c:"-Python" >nul
if not errorlevel 1 (
    set "PYARG="
) else (
    if not exist "%PYSIDECAR%" echo [警告] 未找到 sidecar venv Python，sidecar 打包可能失败：%PYSIDECAR%
)

echo ==============================================
echo  个人刷题 Windows 打包发布
echo  流程：clean、pub get、test、build windows、dist 打包
echo  可透传参数，例如：-SkipTests
echo ==============================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %PYARG% %*
set "EC=%ERRORLEVEL%"

if not "%EC%"=="0" (
    echo.
    echo [失败] 打包未完成，退出码 %EC%，原因见上方日志。
    pause
    exit /b %EC%
)

echo.
echo [完成] 发布包已输出到 dist\ 目录。
pause
exit /b 0
