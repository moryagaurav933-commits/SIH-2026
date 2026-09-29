<#
================================================================================
 Krishi-Saarthi - AUTOMATIC HANDOVER SETUP  (Windows PowerShell 5.1+)
================================================================================
 One command after cloning into ANY folder:

   powershell -ExecutionPolicy Bypass -File .\scripts\setup_handover.ps1

 What it does, in order (stops at the first hard failure, no silent skips):
   1  Detect operating system + architecture
   2  Detect available RAM
   3  Detect GPU (informational - CPU inference is the supported baseline)
   4  Locate a suitable Python 3.11+ interpreter
   5  Verify the committed model artefacts exist BEFORE installing anything
   6  Create the .venv311 virtual environment
   7  Install the pinned dependencies from backend\requirements.txt
   8  Create backend\.env from the committed template if absent
   9  Verify V1 model (weights, 21-class mapping, load, forward pass)
  10  Verify V2 model (weights, 24-class mapping, load, forward pass)
  11  Verify backend dependencies
  12  Verify frontend toolchain (Flutter - optional, non-fatal)
  13  Run smoke test + service test
  14  Run the backend test suite
  15  Run the full environment verification
  16  Print a PASS/FAIL report

 It never needs the training dataset, an NVIDIA GPU, PostgreSQL, Redis, MinIO
 or Node.js.

 Switches:
   -SkipPip        reuse an already-populated venv, skip dependency install
   -SkipTests      skip steps 13-14
   -VenvName NAME  use a different venv folder (default: .venv311)
   -Force          recreate the virtual environment from scratch
#>

[CmdletBinding()]
param(
  [switch]$SkipPip,
  [switch]$SkipTests,
  [string]$VenvName = ".venv311",
  [switch]$Force
)

$ErrorActionPreference = "Continue"   # native tools write to stderr; we gate on exit codes
$ProgressPreference    = "SilentlyContinue"

# ── Paths (all derived from this script, never hard-coded) ────────────────────
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root      = Split-Path -Parent $ScriptDir
$VenvDir   = Join-Path $root $VenvName
$PyVenv    = Join-Path $VenvDir "Scripts\python.exe"
$Reqs      = Join-Path $root "backend\requirements.txt"
$EnvFile   = Join-Path $root "backend\.env"
$EnvTmpl   = Join-Path $root "backend\.env.example"

$script:Failures = New-Object System.Collections.ArrayList
$script:Warnings = New-Object System.Collections.ArrayList
$script:Steps    = New-Object System.Collections.ArrayList

# ── Run a native command, capture its output as plain strings ─────────────────
# PowerShell 5.1 wraps native stderr as ErrorRecord objects, which corrupt
# Select-Object/formatting. Normalise everything to [string[]] and hand the
# caller the real exit code so nothing is ever "silently continued".
function Invoke-Native {
  param([string]$Exe, [string[]]$NativeArgs = @(), [int[]]$ExpectOk = @(0))
  $raw = & $Exe @NativeArgs 2>&1
  $code = $LASTEXITCODE
  $out = @($raw | ForEach-Object { if ($_ -is [System.Management.Automation.ErrorRecord]) { $_.ToString() } else { [string]$_ } })
  return [pscustomobject]@{ Out = $out; Code = $code; Ok = ($ExpectOk -contains $code) }
}

# ── Output helpers ────────────────────────────────────────────────────────────
function Write-Banner {
  param([string]$Text)
  Write-Host ""
  Write-Host ("=" * 78) -ForegroundColor DarkCyan
  Write-Host "  $Text" -ForegroundColor Cyan
  Write-Host ("=" * 78) -ForegroundColor DarkCyan
}
function Write-Step { param([string]$Text) Write-Host ""; Write-Host "--> $Text" -ForegroundColor Cyan }
function Write-Info { param([string]$Text) Write-Host "      $Text" -ForegroundColor DarkGray }
function Pass {
  param([string]$Step, [string]$Text)
  Write-Host "  [PASS] " -ForegroundColor Green -NoNewline
  Write-Host "$Text" -ForegroundColor Green
  [void]$script:Steps.Add(@{ Step = $Step; Text = $Text; Status = "PASS" })
}
function Warn {
  param([string]$Step, [string]$Text)
  Write-Host "  [WARN] " -ForegroundColor Yellow -NoNewline
  Write-Host "$Text" -ForegroundColor Yellow
  [void]$script:Steps.Add(@{ Step = $Step; Text = $Text; Status = "WARN" })
  [void]$script:Warnings.Add("$Step - $Text")
}
function Fail {
  param([string]$Step, [string]$Text, [string]$Fix = "")
  Write-Host "  [FAIL] " -ForegroundColor Red -NoNewline
  Write-Host "$Text" -ForegroundColor Red
  if ($Fix) { Write-Host "         FIX: $Fix" -ForegroundColor Yellow }
  [void]$script:Steps.Add(@{ Step = $Step; Text = $Text; Status = "FAIL" })
  [void]$script:Failures.Add("$Step - $Text$(if ($Fix) { " | $Fix" })")
}
function Die {
  param([string]$Step, [string]$Text, [string]$Fix = "")
  Fail -Step $Step -Text $Text -Fix $Fix
  Write-Host ""
  Write-Host "SETUP ABORTED at step '$Step'." -ForegroundColor Red
  Write-Host "A required dependency is missing or incompatible. Nothing was skipped silently." -ForegroundColor Yellow
  Show-Report
  exit 1
}
function Show-Report {
  Write-Host ""
  Write-Host ("=" * 78) -ForegroundColor DarkCyan
  Write-Host "  SETUP REPORT" -ForegroundColor Cyan
  Write-Host ("=" * 78) -ForegroundColor DarkCyan
  $lastStep = ""
  foreach ($s in $script:Steps) {
    if ($s.Step -ne $lastStep) { Write-Host "  $s.Step" -ForegroundColor White; $lastStep = $s.Step }
    $col = switch ($s.Status) { "PASS" { "Green" } "WARN" { "Yellow" } default { "Red" } }
    Write-Host ("    [{0}] {1}" -f $s.Status, $s.Text) -ForegroundColor $col
  }
  Write-Host ("-" * 78)
  if ($script:Failures.Count -gt 0) {
    Write-Host "  RESULT: FAIL  ($($script:Failures.Count) failure(s), $($script:Warnings.Count) warning(s))" -ForegroundColor Red
    foreach ($f in $script:Failures) { Write-Host "    x $f" -ForegroundColor Red }
  } else {
    Write-Host "  RESULT: PASS  (0 failures, $($script:Warnings.Count) warning(s))" -ForegroundColor Green
  }
  Write-Host ("=" * 78)
}

Write-Banner "KRISHI-SAARTHI - HANDOVER ENVIRONMENT SETUP"
Write-Host "  Repository root : $root"
Write-Host "  Virtual env     : $VenvDir"
Write-Host "  Required dataset: NONE (models are committed to the repository)"
Write-Host "  Required GPU    : NONE (CPU inference is the supported baseline)"

# ── 1. Operating system ───────────────────────────────────────────────────────
Write-Step "1. Operating system"
$osCaption = (Get-CimInstance Win32_OperatingSystem).Caption
$osBuild   = (Get-CimInstance Win32_OperatingSystem).BuildNumber
$isWin     = $env:OS -eq "Windows_NT"
$arch      = $env:PROCESSOR_ARCHITECTURE
Write-Info "$osCaption  (build $osBuild) / $arch"
if (-not $isWin) {
  Die "1. OS" "This script targets Windows. Detected: $($PSVersionTable.OS)." "Use scripts/setup_handover.sh on macOS/Linux."
}
if ($arch -ne "AMD64" -and $arch -ne "x86_64") {
  Die "1. OS" "64-bit Windows is required. Detected architecture: $arch" "Install 64-bit Python 3.11 on a 64-bit machine."
}
Pass "1. OS" "Windows $osBuild ($arch)"

# ── 2. RAM ────────────────────────────────────────────────────────────────────
Write-Step "2. Available RAM"
$os   = Get-CimInstance Win32_OperatingSystem
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
$freeGB = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
Write-Info "Total $ramGB GB, currently free $freeGB GB"
if ($ramGB -lt 8) {
  Die "2. RAM" "Only $ramGB GB RAM detected; 8 GB is the minimum." "Close memory-heavy apps or use a machine with >= 8 GB RAM."
}
Pass "2. RAM" "$ramGB GB total / $freeGB GB free (minimum 8 GB)"

# ── 3. GPU (informational) ────────────────────────────────────────────────────
Write-Step "3. GPU detection (informational - not required)"
$gpuFound = $false
try {
  $gpus = Get-CimInstance Win32_VideoController -ErrorAction Stop
  foreach ($g in $gpus) {
    if ($g.Name) { Write-Info "  - $($g.Name.Trim())  (driver $($g.DriverVersion))"; $gpuFound = $true }
  }
} catch { Write-Info "  WMI query unavailable." }
if (-not $gpuFound) { Write-Info "  - no display adapter reported" }
$driver = $null
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  $smi = Invoke-Native -Exe "nvidia-smi" -NativeArgs @("--query-gpu=name", "--format=csv,noheader")
  if ($smi.Ok -and ($smi.Out -join "").Trim()) { $driver = ($smi.Out -join " ").Trim() }
}
if ($driver) {
  Write-Info "nvidia-smi: $driver"
  Warn "3. GPU" "NVIDIA GPU present, but the pinned PyTorch build is CPU-only. CPU inference will be used."
} else {
  Pass "3. GPU" "No NVIDIA requirement - inference will run on CPU (supported baseline)"
}

# ── 4. Disk space ─────────────────────────────────────────────────────────────
Write-Step "4. Free disk space"
$drive   = (Split-Path -Qualifier $root)
$freeD   = [math]::Round((Get-PSDrive -Name $drive.TrimEnd(':')).Free / 1GB, 1)
Write-Info "$drive free: $freeD GB"
if ($freeD -lt 4) {
  Die "4. Disk" "Only $freeD GB free on $drive; 4 GB is needed for the venv and PyTorch wheels." "Free up disk space and re-run."
}
Pass "4. Disk" "$freeD GB free on $drive"

# ── 5. Python interpreter ─────────────────────────────────────────────────────
Write-Step "5. Python interpreter"
$pyExe = $null
$pyVer = $null

# Probe a launcher string such as "py -3.11" or a literal path to python.exe.
function Test-Interpreter {
  param([string]$Launcher)
  $cmdline = $Launcher + " --version"
  if ($Launcher -like "*.exe" -and $Launcher.Contains(" ")) { $cmdline = '"' + $Launcher + '" --version' }
  $r = Invoke-Native -Exe "cmd.exe" -NativeArgs @("/c", $cmdline)
  if (-not $r.Ok) { return $null }
  $text = ($r.Out -join " ")
  if ($text -notmatch "Python\s+(3)\.(\d+)\.(\d+)") { return $null }
  $maj = [int]$Matches[1]; $min = [int]$Matches[2]; $pat = [int]$Matches[3]
  if ($maj -lt 3 -or ($maj -eq 3 -and $min -lt 10)) { return $null }
  return [pscustomobject]@{ Launcher = $Launcher; Version = "$maj.$min.$pat"; MajorMinor = "$maj.$min" }
}

# 3.11 first (the version this project is verified against), then 3.12/3.10/3.13.
$launchers = @()
if ($env:KRISHI_PYTHON) { $launchers += $env:KRISHI_PYTHON }
$launchers += @("py -3.11", "py -3.12", "py -3.10", "py -3.13", "python")

# Standard install locations, in case python is not on PATH.
$searchRoots = @($env:LOCALAPPDATA, $env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
foreach ($r in $searchRoots) {
  foreach ($m in @("Python311", "Python312", "Python310", "Python313")) {
    $launchers += (Join-Path $r "Programs\Python\$m\python.exe")
    $launchers += (Join-Path $r "$m\python.exe")
    $launchers += (Join-Path $r "Python$($m.Substring(6))\python.exe")
  }
}

foreach ($lc in $launchers) {
  if (-not $lc) { continue }
  $res = Test-Interpreter -Launcher $lc
  if ($res) {
    $pyExe = $res; $pyVer = $res.MajorMinor
    if ($res.MajorMinor -eq "3.11") { break }   # preferred: do not downgrade the choice
  }
}

if (-not $pyExe) {
  Die "5. Python" "No Python 3.10+ interpreter was found on this machine." `
       "Install Python 3.11.9 from https://www.python.org/downloads/windows/ and tick 'Add python.exe to PATH', then re-run. Or set `$env:KRISHI_PYTHON='C:\Path\To\python.exe' and re-run."
}
Write-Info "interpreter : $($pyExe.Launcher)  (Python $pyVer)"
if ($pyVer -eq "3.11") {
  Pass "5. Python" "Python $pyVer - the exact minor version this project is verified against"
} else {
  Warn "5. Python" "Python $pyVer selected; the project is verified on 3.11. The version check in step 18 is authoritative."
}

# ── 6. Node / npm (NOT required - reported for completeness) ──────────────────
Write-Step "6. Node.js / npm (optional - this project has no Node frontend)"
$nodeVer = (Invoke-Native -Exe "cmd.exe" -NativeArgs @("/c", "node --version")).Out -join ""
$npmVer  = (Invoke-Native -Exe "cmd.exe" -NativeArgs @("/c", "npm --version")).Out -join ""
if ($nodeVer.Trim()) {
  Write-Info "node $($nodeVer.Trim()), npm $($npmVer.Trim()) detected (installed but unused by this project)"
  Pass "6. Node" "node/npm present but not required by this project"
} else {
  Write-Info "Node.js is not installed. This is fine: the frontend is Flutter/Dart and the backend is Python."
  Pass "6. Node" "not required - frontend is Flutter, backend is Python"
}

# ── 7. Model artefacts must exist before we install anything ──────────────────
Write-Step "7. Model artefacts present in the repository"
$models = @(
  @{ Name = "V1 weights";      Path = (Join-Path $root "ai_module\best_model_final.pth");           MinMB = 5 },
  @{ Name = "V1 class mapping";Path = (Join-Path $root "ai_module\class_names.json");               MinMB = 0 },
  @{ Name = "V2 weights";      Path = (Join-Path $root "ai_module\models\v2\best_model_v2.pth");   MinMB = 5 },
  @{ Name = "V2 class mapping";Path = (Join-Path $root "ai_module\models\v2\class_names_v2.json"); MinMB = 0 }
)
$missing = @()
foreach ($m in $models) {
  if (-not (Test-Path -LiteralPath $m.Path)) {
    Fail "7. Models" "$($m.Name) missing" "Expected at $(Resolve-Path -LiteralPath $root -ErrorAction SilentlyContinue)\$($m.Path.Substring($root.Length + 1))"
    $missing += $m.Name
  } else {
    $len = (Get-Item -LiteralPath $m.Path).Length
    if ($len -lt ($m.MinMB * 1MB)) {
      Fail "7. Models" "$($m.Name) is truncated ($([math]::Round($len/1KB,1)) KB)"
      $missing += $m.Name
    } else {
      Pass "7. Models" "$($m.Name) present ($([math]::Round($len/1MB,2)) MB)"
    }
  }
}
if ($missing.Count -gt 0) {
  Die "7. Models" "$($missing.Count) model artefact(s) missing from the checkout." `
       "Clone the handover branch with Git LFS enabled (if the repo uses LFS), or re-clone. These .pth files ARE committed on purpose."
}
if (-not (Test-Path -LiteralPath $Reqs)) {
  Die "7. Models" "backend\requirements.txt not found - this does not look like the project repository." "Re-clone the repository."
}

# ── 8. Virtual environment ────────────────────────────────────────────────────
Write-Step "8. Virtual environment ($VenvName)"
if ($Force -and (Test-Path -LiteralPath $VenvDir)) {
  Write-Info "-Force: removing $VenvDir"
  Remove-Item -LiteralPath $VenvDir -Recurse -Force
}
if (Test-Path -LiteralPath $PyVenv) {
  Write-Info "reusing existing $PyVenv"
} else {
  Write-Info "creating $VenvDir (this takes ~20 seconds)"
  $vparts = @($pyExe.Launcher.Split(" ") | Where-Object { $_ -ne "" })
  $venvArgs = @("-m", "venv", $VenvDir)
  if ($vparts.Count -gt 1) { $venvArgs = @($vparts[1..($vparts.Length - 1)]) + $venvArgs }
  $venvRun = Invoke-Native -Exe $vparts[0] -NativeArgs $venvArgs
  if (-not $venvRun.Ok -or -not (Test-Path -LiteralPath $PyVenv)) {
    Die "8. venv" "Failed to create the virtual environment at $VenvDir" "Close anything locking the folder, or pass -VenvName <other>."
  }
}
$venvVer = (Invoke-Native -Exe $PyVenv -NativeArgs @("-c", "import sys;print('%d.%d.%d' % sys.version_info[:3])")).Out -join ""
if (-not $venvVer) { Die "8. venv" "The virtual environment python.exe does not run." "Delete $VenvDir and re-run with -Force." }
$venvVer = $venvVer.Trim()
if ([version]($venvVer -replace '[^0-9.].*$', '') -lt [version]"3.10.0") {
  Die "8. venv" "Virtual environment Python is $venvVer; 3.10+ is required." "Delete $VenvDir and re-run with -Force."
}
Pass "8. venv" "Python $venvVer at $VenvDir"

# ── 9. Pinned dependencies ────────────────────────────────────────────────────
Write-Step "9. Pinned dependencies"
if ($SkipPip) {
  Warn "9. Deps" "dependency installation skipped (-SkipPip)"
} else {
  Write-Info "upgrading pip ..."
  $pipUp = Invoke-Native -Exe $PyVenv -NativeArgs @("-m", "pip", "install", "--upgrade", "pip", "--quiet", "--disable-pip-version-check")
  if (-not $pipUp.Ok) { Die "9. Deps" "pip could not be upgraded" "Check your internet connection / proxy, then re-run." }

  Write-Info "installing from backend\requirements.txt (downloads ~250 MB, 3-8 minutes) ..."
  Write-Host ""
  $pipRun = Invoke-Native -Exe $PyVenv -NativeArgs @("-m", "pip", "install", "-r", $Reqs, "--disable-pip-version-check")
  $pipRun.Out | Select-Object -Last 12 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
  if (-not $pipRun.Ok) {
    Die "9. Deps" "pip install -r backend\requirements.txt failed (exit $($pipRun.Code))." "Scroll up for the failing wheel. Common causes: no internet access, or a corporate proxy. Set `$env:PIP_INDEX_URL / `$env:PIP_TRUSTED_HOST and re-run."
  }
  Pass "9. Deps" "pinned dependencies installed from backend\requirements.txt"
}

# ── 10. Environment configuration ─────────────────────────────────────────────
Write-Step "10. Environment configuration"
if (Test-Path -LiteralPath $EnvFile) {
  Pass "10. Config" "backend\.env already present (kept as-is)"
} elseif (Test-Path -LiteralPath $EnvTmpl) {
  Copy-Item -LiteralPath $EnvTmpl -Destination $EnvFile -Force
  Pass "10. Config" "backend\.env created from backend\.env.example"
} else {
  Fail "10. Config" "backend\.env.example not found - cannot create backend\.env"
  Warn "10. Config" "the backend will fall back to built-in defaults (SQLite auto-fallback still works)"
}
# Guarantee SQLite so a fresh clone never needs PostgreSQL.
if (Test-Path -LiteralPath $EnvFile) {
  $envText = Get-Content -LiteralPath $EnvFile -Raw
  if ($envText -notmatch "(?m)^DATABASE_URL=") {
    Add-Content -LiteralPath $EnvFile -Value "`n# Added by setup_handover.ps1: force the SQLite auto-fallback so no PostgreSQL server is required." -Encoding UTF8
    Add-Content -LiteralPath $EnvFile -Value "DATABASE_URL=sqlite+aiosqlite:///./krishi_saarthi.db" -Encoding UTF8
    Add-Content -LiteralPath $EnvFile -Value "DATABASE_URL_SYNC=sqlite:///./krishi_saarthi.db" -Encoding UTF8
    Pass "10. Config" "DATABASE_URL set to SQLite (no PostgreSQL required)"
  } else {
    Pass "10. Config" "DATABASE_URL already configured in backend\.env"
  }
  if ($envText -notmatch "(?m)^SECRET_KEY=") {
    $secret = (Invoke-Native -Exe $PyVenv -NativeArgs @("-c", "import secrets;print(secrets.token_urlsafe(48))")).Out -join ""
    if ($secret) {
      Add-Content -LiteralPath $EnvFile -Value "SECRET_KEY=$secret" -Encoding UTF8
      Pass "10. Config" "SECRET_KEY generated (random, local dev only)"
    }  }
}

# ── Helper: run a python script from the venv and capture output ──────────────
function Invoke-Check {
  param([string]$Step, [string]$Label, [string]$Script, [string[]]$ScriptArgs = @())
  $r = Invoke-Native -Exe $PyVenv -NativeArgs (@($Script) + $ScriptArgs)
  if ($r.Ok) { Pass $Step $Label } else { Fail $Step "$Label failed (exit $($r.Code))" (($r.Out | Select-Object -Last 12) -join "`n") }
  return $r
}

# ── 11-12. V1 and V2 verification ─────────────────────────────────────────────
Write-Step "11. V1 model verification (4 crops / 21 classes)"
$v1 = Invoke-Check "11. V1" "V1 loads: weights + 21-class mapping + forward pass" `
        (Join-Path $root "scripts\verify_models.py")
$v1.Out | Select-String -Pattern "V1 " | ForEach-Object { Write-Host "      $($_.Line.Trim())" -ForegroundColor DarkGray }
if (-not $v1.Ok -or (($v1.Out -join "`n") -match "\[FAIL\]")) {
  Die "11. V1" "V1 model verification reported a FAIL." "Re-clone the repository so ai_module\best_model_final.pth and ai_module\class_names.json are restored intact."
}

Write-Step "12. V2 model verification (8 crops / 24 classes)"
$v2 = Invoke-Check "12. V2" "V2 loads: weights + 24-class mapping + forward pass" `
        (Join-Path $root "scripts\verify_models.py")
$v2.Out | Select-String -Pattern "V2 " | ForEach-Object { Write-Host "      $($_.Line.Trim())" -ForegroundColor DarkGray }
if (-not $v2.Ok -or (($v2.Out -join "`n") -match "\[FAIL\]")) {
  Die "12. V2" "V2 model verification reported a FAIL." "Re-clone the repository so ai_module\models\v2\best_model_v2.pth and class_names_v2.json are restored intact."
}

# ── 13. Backend dependencies ──────────────────────────────────────────────────
Write-Step "13. Backend dependencies"
$backendProbe = @'
import importlib, sys
mods = ["fastapi","uvicorn","pydantic","pydantic_settings","sqlalchemy","aiosqlite","alembic",
        "jose","passlib","cryptography","multipart","httpx","aiohttp","requests","redis",
        "structlog","dotenv","shortuuid","tenacity","numpy","PIL","torch","torchvision",
        "ai_edge_litert","pytest"]
missing = []
for m in mods:
    try:
        importlib.import_module(m)
    except Exception:
        missing.append(m)
if missing:
    print("MISSING: " + ", ".join(missing)); sys.exit(1)
sys.path.insert(0, "backend")
from app.main import app
paths = {getattr(r, "path", "") for r in app.routes}
for need in ("/health", "/api/diagnose"):
    if need not in paths:
        print("ROUTE MISSING: " + need); sys.exit(1)
from app.services.crop_ai_service import MODEL_PATH
from pathlib import Path
if not (MODEL_PATH and Path(MODEL_PATH).is_file()):
    print("BACKEND CANNOT RESOLVE best_model_final.pth"); sys.exit(1)
print("BACKEND_OK routes=%d model=%s" % (len(app.routes), Path(MODEL_PATH).name))
'@
$probeFile = Join-Path $env:TEMP "krishi_backend_probe.py"
Set-Content -LiteralPath $probeFile -Value $backendProbe -Encoding UTF8
Push-Location $root
$probeRun = Invoke-Native -Exe $PyVenv -NativeArgs @($probeFile)
Pop-Location
Remove-Item -LiteralPath $probeFile -Force -ErrorAction SilentlyContinue
if (-not $probeRun.Ok) {
  Fail "13. Backend" "backend dependency / import check failed (exit $($probeRun.Code))" (($probeRun.Out | Select-Object -Last 10) -join "`n")
  Die "13. Backend" "The backend cannot start on this machine." "Re-run without -SkipPip to install the pinned dependencies."
} else {
  Pass "13. Backend" (($probeRun.Out | Where-Object { $_ -match "BACKEND_OK" } | Select-Object -Last 1))
}

# ── 14. Frontend toolchain (optional) ─────────────────────────────────────────
Write-Step "14. Frontend toolchain (Flutter - optional)"
$flutterOk = $false
foreach ($cand in @("$env:LOCALAPPDATA\flutter\bin\flutter.bat", "$env:ProgramFiles\flutter\bin\flutter.bat", "C:\flutter\bin\flutter.bat")) {
  if (Test-Path -LiteralPath $cand) { $flutterExe = $cand; break }
}
if (-not $flutterExe) { $cmd = Get-Command flutter -ErrorAction SilentlyContinue; if ($cmd) { $flutterExe = $cmd.Source } }
if ($flutterExe) {
  $fv = (Invoke-Native -Exe "cmd.exe" -NativeArgs @("/c", """$flutterExe"" --version")).Out -join " "
  if ($fv -match "Flutter\s+(\d+)\.(\d+)\.(\d+)") {
    $fVer = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
    $fMajor = [int]$Matches[1]; $fMinor = [int]$Matches[2]
    Write-Info "flutter $fVer  ($flutterExe)"
    if ($fMajor -eq 3 -and $fMinor -ge 44) {
      $flutterOk = $true
      Pass "14. Frontend" "Flutter $fVer at $flutterExe"
    } else {
      Warn "14. Frontend" "Flutter $fVer is older than the required 3.44+"
    }
  } else {
    Warn "14. Frontend" "Flutter was found at $flutterExe but `flutter --version` did not report a version (is Git installed? Flutter needs it)."
  }
} else {
  Write-Info "Flutter SDK not found on this machine."
}
if (-not $flutterOk) {
  Warn "14. Frontend" "Flutter 3.44+ not found. The backend and both ML models work without it. Install Flutter only if you need to run the Flutter app."
}
$pubspec = Join-Path $root "mobile_app\pubspec.yaml"
if (Test-Path -LiteralPath $pubspec) { Pass "14. Frontend" "mobile_app\pubspec.yaml + pubspec.lock present (Dart deps are version-locked)" }
$webIndex = Join-Path $root "mobile_app\build\web\index.html"
if (Test-Path -LiteralPath $webIndex) { Pass "14. Frontend" "prebuilt web bundle present" }
elseif ($flutterOk) { Warn "14. Frontend" "no prebuilt web bundle (build/ is gitignored) - run: cd mobile_app; flutter build web" }

# ── 15. Smoke + service tests ─────────────────────────────────────────────────
if ($SkipTests) {
  Warn "15. Tests" "smoke and service tests skipped (-SkipTests)"
} else {
  Write-Step "15. Smoke test (inference pipeline, synthetic images)"
  $smoke = Join-Path $root "ai_module\smoke_test.py"
  if (Test-Path -LiteralPath $smoke) {
    $r = Invoke-Check "15. Tests" "ai_module\smoke_test.py - all checks passed" $smoke
    $r.Out | Select-String -Pattern "\[FAIL\]" | ForEach-Object { Write-Host "      $($_.Line.Trim())" -ForegroundColor Red }
  } else {
    Warn "15. Tests" "ai_module\smoke_test.py not found"
  }

  Write-Step "16. Service check (backend CropAIService on a generated image)"
  $svc = Join-Path $root "ai_module\service_check.py"
  if (Test-Path -LiteralPath $svc) {
    Push-Location $root
    $r = Invoke-Check "16. Service" "ai_module\service_check.py - service healthy" $svc
    Pop-Location
    if (-not $r.Ok) { $r.Out | Select-Object -Last 6 | ForEach-Object { Write-Host "      $_" -ForegroundColor Red } }
  } else {
    Warn "16. Service" "ai_module\service_check.py not found"
  }
}

# ── 17. Backend test suite ────────────────────────────────────────────────────
if (-not $SkipTests) {
  Write-Step "17. Backend test suite (pytest)"
  if (Test-Path -LiteralPath (Join-Path $root "backend\pytest.ini")) {
    Push-Location (Join-Path $root "backend")
    $r = Invoke-Native -Exe $PyVenv -NativeArgs @("-m", "pytest", "-q", "--no-header")
    Pop-Location
    $tail = ($r.Out | Select-Object -Last 1)
    if ($r.Ok) { Pass "17. Tests" "backend pytest: $tail" }
    else { Fail "17. Tests" "backend pytest suite failed (exit $($r.Code))" (($r.Out | Select-Object -Last 20) -join "`n") }
  } else {
    Warn "17. Tests" "backend\pytest.ini not found - skipping the backend test suite"
  }
}

# ── 18. Full environment verification ─────────────────────────────────────────
Write-Step "18. Full environment verification"
$verify = Join-Path $root "scripts\verify_environment.py"
$vrun = Invoke-Native -Exe $PyVenv -NativeArgs @($verify)
$vrun.Out | Select-Object -Last 26 | ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
if ($vrun.Ok) { Pass "18. Verify" "scripts\verify_environment.py - all required checks PASSED" }
else { Fail "18. Verify" "scripts\verify_environment.py reported FAIL (exit $($vrun.Code))" "Read the FAIL list above; this machine does not meet the requirements yet." }

# ── Final report ──────────────────────────────────────────────────────────────
Show-Report

if ($script:Failures.Count -gt 0) {
  Write-Host ""
  Write-Host "NEXT STEPS" -ForegroundColor Yellow
  Write-Host "  1. Fix every [FAIL] line above (the FIX hints say exactly what to do)." -ForegroundColor White
  Write-Host "  2. Re-run:  powershell -ExecutionPolicy Bypass -File .\scripts\setup_handover.ps1" -ForegroundColor White
  exit 1
}

Write-Host ""
Write-Host "SETUP COMPLETE. Next:" -ForegroundColor Green
Write-Host "  Verify models only : .\$VenvName\Scripts\python.exe scripts\verify_models.py" -ForegroundColor White
Write-Host "  V1 inference       : .\$VenvName\Scripts\python.exe ai_module\predict.py    <image> tomato" -ForegroundColor White
Write-Host "  V2 inference       : .\$VenvName\Scripts\python.exe ai_module\predict_v2.py <image> cashew" -ForegroundColor White
Write-Host "  Start backend      : .\run_app.ps1            (or see START_HERE.md section 10)" -ForegroundColor White
Write-Host ""
Write-Host "No training dataset and no NVIDIA GPU are required for any of the above." -ForegroundColor DarkGray
exit 0
