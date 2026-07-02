# AI Pet Health Assistant -- Run Everything
$ErrorActionPreference = "Continue"
$ROOT = "D:\jabiru Labs Tasks\Pet"

Write-Host "=== AI Pet Health Assistant ===" -ForegroundColor Cyan

# Step 1: Start AI Service (port 8000)
Write-Host "[1/4] Starting AI Service (port 8000)..." -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8000/" -UseBasicParsing -TimeoutSec 2
    Write-Host "  OK - AI Service already running" -ForegroundColor Green
} catch {
    $log = "$env:TEMP\ai-service.log"
    $p = Start-Process -FilePath "python" -ArgumentList "-m uvicorn app.main:app --host 0.0.0.0 --port 8000 --log-level info" `
        -WorkingDirectory "$ROOT\pet-ai-service" -WindowStyle Hidden -PassThru -RedirectStandardOutput $log
    Start-Sleep -Seconds 4
    Write-Host "  OK - AI Service started (PID: $($p.Id))" -ForegroundColor Green
}

# Step 2: Start Backend API (port 8001)
Write-Host "[2/4] Starting Backend API (port 8001)..." -ForegroundColor Yellow
try {
    $r = Invoke-WebRequest -Uri "http://127.0.0.1:8001/" -UseBasicParsing -TimeoutSec 2
    Write-Host "  OK - Backend already running" -ForegroundColor Green
} catch {
    $log = "$env:TEMP\backend.log"
    $p = Start-Process -FilePath "python" -ArgumentList "-m uvicorn app.main:app --host 0.0.0.0 --port 8001 --log-level info" `
        -WorkingDirectory "$ROOT\pet-backend-fastapi" -WindowStyle Hidden -PassThru -RedirectStandardOutput $log
    Start-Sleep -Seconds 4
    Write-Host "  OK - Backend started (PID: $($p.Id))" -ForegroundColor Green
}

# Step 3: Smoke Tests
Write-Host "[3/4] Running API smoke tests..." -ForegroundColor Yellow
python "$ROOT\smoke_test.py"

# Step 4: Launch Flutter App
Write-Host "[4/4] Flutter App - cd pet-app && flutter run -d chrome" -ForegroundColor Yellow

Write-Host "`nDone. Services:" -ForegroundColor Cyan
Write-Host "  AI Service:   http://localhost:8000"
Write-Host "  Backend API:  http://localhost:8001"
Write-Host "  API Docs:     http://localhost:8001/docs"
