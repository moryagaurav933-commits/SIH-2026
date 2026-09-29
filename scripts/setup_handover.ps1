# ==============================================================================
# Krishi-Saarthi — Handover Developer Environment Setup (Windows PowerShell)
# Sets up Python virtualenv, installs required dependencies, and verifies models.
# ==============================================================================

[CmdletBinding()]
param(
  [switch]$SkipPip
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
if (-not $root) { $root = (Get-Location).Path }

Write-Host "==================================================================" -ForegroundColor Green
Write-Host "  KRISHI-SAARTHI - DEVELOPER HANDOVER SETUP [V1 + V2 MODELS]      " -ForegroundColor Green
Write-Host "==================================================================" -ForegroundColor Green
Write-Host "Project Root: $root" -ForegroundColor DarkGray

# ── 1. Check Model Checkpoints ───────────────────────────────────────────────
Write-Host "[1/5] Checking Required Model Checkpoints..." -ForegroundColor Cyan
$v1Model = Join-Path $root "ai_module\best_model_final.pth"
$v2Model = Join-Path $root "ai_module\models\v2\best_model_v2.pth"
$v1Classes = Join-Path $root "ai_module\class_names.json"
$v2Classes = Join-Path $root "ai_module\models\v2\class_names_v2.json"

$missingFiles = @()
if (-not (Test-Path -LiteralPath $v1Model)) { $missingFiles += "ai_module\best_model_final.pth" }
if (-not (Test-Path -LiteralPath $v2Model)) { $missingFiles += "ai_module\models\v2\best_model_v2.pth" }
if (-not (Test-Path -LiteralPath $v1Classes)) { $missingFiles += "ai_module\class_names.json" }
if (-not (Test-Path -LiteralPath $v2Classes)) { $missingFiles += "ai_module\models\v2\class_names_v2.json" }

if ($missingFiles.Count -gt 0) {
  Write-Host "[FAIL] Missing required model files:" -ForegroundColor Red
  foreach ($f in $missingFiles) { Write-Host "   - $f" -ForegroundColor Red }
  Write-Host "Please ensure you have checked out the correct branch: handover/ml-v2-integration" -ForegroundColor Yellow
  exit 1
}

Write-Host "   [PASS] V1 Model present: $([Math]::Round((Get-Item $v1Model).Length / 1MB, 2)) MB" -ForegroundColor Green
Write-Host "   [PASS] V2 Model present: $([Math]::Round((Get-Item $v2Model).Length / 1MB, 2)) MB" -ForegroundColor Green

# ── 2. Probe Python 3.10+ ────────────────────────────────────────────────────
Write-Host "`n[2/5] Detecting Python 3.10+..." -ForegroundColor Cyan
$candidates = @("py -3.11", "py -3.12", "py -3.10", "python")
foreach ($searchRoot in @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)}, "C:\")) {
  if (-not $searchRoot) { continue }
  foreach ($ver in @("Python313", "Python312", "Python311", "Python310")) {
    foreach ($rel in @("Programs\Python\$ver\python.exe", "Python$($ver.Substring(6))\python.exe")) {
      $candidates += Join-Path $searchRoot $rel
    }
  }
}

$foundPython = $null
foreach ($cand in $candidates) {
  try {
    if ($cand -match '\.exe$') {
      if (-not (Test-Path -LiteralPath $cand)) { continue }
      $v = & $cand --version 2>&1
    } else {
      $v = & ([scriptblock]::Create($cand + " --version")) 2>&1
    }
    if ($LASTEXITCODE -eq 0 -and ($v -join ' ') -match '3\.(1[0-9]|[2-9])') {
      $foundPython = $cand
      break
    }
  } catch { }
}

if (-not $foundPython) {
  Write-Host "[FAIL] No Python 3.10+ found." -ForegroundColor Red
  Write-Host "Please install Python 3.11 from https://www.python.org/downloads/" -ForegroundColor Yellow
  Write-Host "and TICK 'Add python.exe to PATH' during installation." -ForegroundColor Yellow
  exit 1
}

Write-Host "   [PASS] Found Python: $foundPython" -ForegroundColor Green

# ── 3. Virtual Environment ───────────────────────────────────────────────────
Write-Host "`n[3/5] Setting up Virtual Environment (.venv311)..." -ForegroundColor Cyan
$venvDir = Join-Path $root ".venv311"
$pyVenv = Join-Path $venvDir "Scripts\python.exe"

if (-not (Test-Path -LiteralPath $pyVenv)) {
  Write-Host "   Creating virtual environment at $venvDir ..." -ForegroundColor DarkGray
  if ($foundPython -match '\.exe$') {
    & $foundPython -m venv $venvDir
  } else {
    & ([scriptblock]::Create($foundPython + " -m venv $venvDir"))
  }
  Write-Host "   Virtual environment created." -ForegroundColor Green
} else {
  Write-Host "   Existing virtual environment detected at $venvDir." -ForegroundColor DarkGray
}

# ── 4. Dependencies ──────────────────────────────────────────────────────────
Write-Host "`n[4/5] Checking / Installing Dependencies..." -ForegroundColor Cyan
$reqs = Join-Path $root "backend\requirements.txt"
if ($SkipPip) {
  Write-Host "   Skipping pip install as requested (-SkipPip)." -ForegroundColor DarkGray
} elseif (Test-Path -LiteralPath $reqs) {
  Write-Host "   Upgrading pip and installing requirements from $reqs ..." -ForegroundColor DarkGray
  & $pyVenv -m pip install --upgrade pip --quiet
  & $pyVenv -m pip install -r $reqs --quiet
  Write-Host "   Dependencies up to date." -ForegroundColor Green
} else {
  Write-Host "   [WARN] backend\requirements.txt not found." -ForegroundColor Yellow
}

# Auto-create backend\.env if missing
$envFile = Join-Path $root "backend\.env"
$envExample = Join-Path $root "backend\.env.example"
if (-not (Test-Path -LiteralPath $envFile) -and (Test-Path -LiteralPath $envExample)) {
  Copy-Item $envExample $envFile -Force
  Write-Host "   Created backend\.env from template." -ForegroundColor DarkGray
}

# ── 5. Run Model Verification ────────────────────────────────────────────────
Write-Host "`n[5/5] Running Model Verification..." -ForegroundColor Cyan
$verifyScript = Join-Path $root "scripts\verify_models.py"
& $pyVenv $verifyScript

if ($LASTEXITCODE -eq 0) {
  Write-Host "`n==================================================================" -ForegroundColor Green
  Write-Host "  SETUP COMPLETE! Environment is ready for ML V2 integration.      " -ForegroundColor Green
  Write-Host "==================================================================" -ForegroundColor Green
  Write-Host "Next steps:" -ForegroundColor Cyan
  Write-Host "  1. Read START_HERE.md and HANDOVER.md" -ForegroundColor White
  Write-Host "  2. Test V1 prediction:  .\.venv311\Scripts\python.exe ai_module\predict.py <image>" -ForegroundColor White
  Write-Host "  3. Test V2 prediction:  .\.venv311\Scripts\python.exe ai_module\predict_v2.py <image> [crop]" -ForegroundColor White
  Write-Host "  4. Start full app:      .\run_app.ps1" -ForegroundColor White
} else {
  Write-Host "`n[FAIL] Model verification reported errors. See above." -ForegroundColor Red
  exit 1
}
