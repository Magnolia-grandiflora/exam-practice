param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath,
    [string]$Python = 'python'
)

$ErrorActionPreference = 'Stop'
$bridge = $PSScriptRoot
$runtime = Join-Path $bridge 'runtime-build'
if ((Get-Content -LiteralPath (Join-Path $bridge 'requirements.lock') -Raw) -match '(?i)pymupdf|fitz') {
    throw 'PyMuPDF/Fitz is forbidden from the sidecar runtime.'
}
if ((Get-Content -LiteralPath (Join-Path $bridge 'constraints.lock') -Raw) -match '(?i)pymupdf|fitz') {
    throw 'PyMuPDF/Fitz is forbidden from the sidecar runtime constraints.'
}
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
& $Python -m pip install --upgrade --target $runtime `
    --constraint (Join-Path $bridge 'constraints.lock') `
    --requirement (Join-Path $bridge 'requirements.lock')
if ($LASTEXITCODE -ne 0) { throw 'Cannot install pinned sidecar build requirements.' }
$work = Join-Path $bridge '.build'
Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $work -Force | Out-Null
try {
    $previousPythonPath = $env:PYTHONPATH
    $env:PYTHONPATH = $runtime
    & $Python -m PyInstaller --noconfirm --clean --onefile --name paper_omr_bridge `
        --distpath (Join-Path $work 'dist') --workpath (Join-Path $work 'work') `
        --specpath (Join-Path $work 'spec') --paths $runtime `
        (Join-Path $bridge 'paper_omr_bridge.py')
    if ($LASTEXITCODE -ne 0) { throw 'PyInstaller failed.' }
    $built = Join-Path $work 'dist\paper_omr_bridge.exe'
    if (-not (Test-Path -LiteralPath $built -PathType Leaf)) { throw 'Sidecar executable was not produced.' }
    & $built --self-test
    if ($LASTEXITCODE -ne 0) { throw 'Sidecar self-test failed.' }
    $destination = [IO.Path]::GetFullPath($OutputPath)
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $built -Destination $destination -Force
    if ([Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($destination)) -match '(?i)(pymupdf|fitz)') {
        throw 'PyMuPDF/Fitz marker found in packaged sidecar.'
    }
} finally {
    $env:PYTHONPATH = $previousPythonPath
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
