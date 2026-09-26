# Krishi-Saarthi - one-command launcher for Windows PowerShell
#
#   .\run_app.ps1            -> start backend + open the Flutter app in Chrome
#   .\run_app.ps1 -Backend   -> start only the backend
#   .\run_app.ps1 -Web       -> start only the Flutter web app
#
# NOTE: This needs a PowerShell window you keep open. Press Ctrl+C in that
# window to stop. Two services cannot survive being started from a script that
# exits, so run this in its own terminal.

param(
  [switch]$Backend,
  [switch]$Web
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$venv = Join-Path $root ".venv311"
$py = Join-Path $venv "Scripts\python.exe"
$reqs = Join-Path $root "backend\requirements.txt"

# ── Auto-setup ───────────────────────────────────────────────────────────────
# If the virtual environment is missing, build it and install dependencies.
# This is what makes "just make it work" a single command on a fresh clone.
if (-not (Test-Path $py)) {
  Write-Host "[setup] no virtual environment found - creating .venv311 ..." -ForegroundColor Cyan
  Write-Host "[setup] this runs once and takes a few minutes" -ForegroundColor DarkGray

  $base = $null
  foreach ($cand in @("py -3.11", "py -3.12", "py -3.10", "python")) {
    try {
      & ([scriptblock]::Create($cand + " --version")) *> $null
      if ($LASTEXITCODE -eq 0) { $base = $cand; break }
    } catch { }
  }
  if (-not $base) {
    Write-Host "[setup] FAILED - no Python 3.10+ found. Install Python from python.org and retry." -ForegroundColor Red
    exit 1
  }

  & ([scriptblock]::Create($base + " -m venv $venv"))
  if (-not (Test-Path $py)) {
    Write-Host "[setup] FAILED to create the virtual environment." -ForegroundColor Red
    exit 1
  }

  Write-Host "[setup] installing backend dependencies ..." -ForegroundColor Cyan
  & $py -m pip install --upgrade pip --quiet
  & $py -m pip install -r $reqs
  if ($LASTEXITCODE -ne 0) {
    Write-Host "[setup] FAILED to install dependencies. Scroll up for the error." -ForegroundColor Red
    exit 1
  }

  # Make sure the database exists and is seeded with the disease data.
  Write-Host "[setup] preparing the database ..." -ForegroundColor Cyan
  Push-Location $root
  & $py backend\scripts\init_db.py
  Pop-Location

  Write-Host "[setup] done." -ForegroundColor Green
}

# If no switch was given, run both.
if (-not $Backend -and -not $Web) { $Backend = $true; $Web = $true }

function Test-Port($port) {
  try {
    $c = New-Object Net.Sockets.TcpClient
    $c.Connect("127.0.0.1", $port)
    $c.Close()
    return $true
  } catch { return $false }
}

# ── Backend ────────────────────────────────────────────────────────────────
if ($Backend) {
  if (Test-Port 8000) {
    Write-Host "[backend] already running on http://127.0.0.1:8000" -ForegroundColor DarkGray
  } else {
    Write-Host "[backend] starting on http://127.0.0.1:8000 ..." -ForegroundColor Cyan
    Start-Process -FilePath $py `
      -ArgumentList "-m","uvicorn","app.main:app","--host","127.0.0.1","--port","8000" `
      -WorkingDirectory (Join-Path $root "backend") `
      -WindowStyle Hidden
    Start-Sleep -Seconds 8
    if (Test-Port 8000) {
      Write-Host "[backend] up. API docs: http://127.0.0.1:8000/docs" -ForegroundColor Green
    } else {
      Write-Host "[backend] FAILED to start - check that .venv311 exists" -ForegroundColor Red
    }
  }
}

# ── Flutter app ────────────────────────────────────────────────────────────
if ($Web) {
  $webDir = Join-Path $root "mobile_app\build\web"
  $index  = Join-Path $webDir "index.html"

  if (-not (Test-Path $index)) {
    Write-Host "[web] no build found, building now (takes ~1 min)..." -ForegroundColor Cyan
    Push-Location (Join-Path $root "mobile_app")
    try {
      flutter build web --release
    } catch {
      Write-Host "[web] build failed - run 'flutter build web' in mobile_app to see why" -ForegroundColor Red
    }
    Pop-Location
  }

  if (Test-Port 8080) {
    Write-Host "[web] already running on http://127.0.0.1:8080" -ForegroundColor DarkGray
  } else {
    Write-Host "[web] starting on http://127.0.0.1:8080 ..." -ForegroundColor Cyan
    Start-Process -FilePath $py `
      -ArgumentList "-m","http.server","8080","--bind","127.0.0.1" `
      -WorkingDirectory $webDir `
      -WindowStyle Hidden
    Start-Sleep -Seconds 4
  }

  if (Test-Port 8080) {
    Write-Host "[web] up at http://127.0.0.1:8080" -ForegroundColor Green
    Start-Process "http://127.0.0.1:8080/"
    Write-Host "[web] opening in your browser..." -ForegroundColor Green
  } else {
    Write-Host "[web] FAILED to start" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "Backend : http://127.0.0.1:8000/docs" -ForegroundColor Yellow
Write-Host "App     : http://127.0.0.1:8080"     -ForegroundColor Yellow
Write-Host ""
Write-Host "Both are running in the background. To stop them:" -ForegroundColor DarkGray
Write-Host "  Get-NetTCPConnection -LocalPort 8000,8080 -State Listen |" -ForegroundColor DarkGray
Write-Host "    ForEach-Object { Stop-Process -Id `$_.OwningProcess -Force }" -ForegroundColor DarkGray
