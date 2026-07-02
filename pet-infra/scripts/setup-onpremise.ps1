# AI Pet Health Assistant — On-Premise Setup Script
# Run as Administrator on your on-premise Ubuntu/Debian server

Write-Host "=== AI Pet Health Assistant — On-Premise Setup ===" -ForegroundColor Cyan

# 1. System Updates
Write-Host "[1/6] Updating system packages..." -ForegroundColor Yellow
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
Write-Host "[2/6] Installing Docker..." -ForegroundColor Yellow
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $env:USER
}

# 3. Install Docker Compose
Write-Host "[3/6] Installing Docker Compose..." -ForegroundColor Yellow
if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
}

# 4. Pull Qwen models via Ollama
Write-Host "[4/6] Pulling Qwen models (this may take a while)..." -ForegroundColor Yellow
sudo docker run -d --name ollama-pull --rm \
    -v ollama_models:/root/.ollama \
    ollama/ollama:latest \
    sh -c "ollama pull qwen2.5:7b-q4_K_M && ollama pull qwen2.5:1.5b-q4_K_M && ollama pull bge-m3:latest"

# 5. Copy configuration
Write-Host "[5/6] Setting up configuration..." -ForegroundColor Yellow
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "  -> Edit .env with your actual API keys!" -ForegroundColor Red
}

# 6. Start services
Write-Host "[6/6] Starting services..." -ForegroundColor Yellow
sudo docker-compose -f docker/docker-compose.yml up -d

Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host "AI Service: http://localhost:8000"
Write-Host "Grafana:    http://localhost:3000 (admin/admin)"
Write-Host "Prometheus: http://localhost:9090"
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Edit .env with your Longcat API key (already included)"
Write-Host "  2. Verify models: curl http://localhost:8000/health"
Write-Host "  3. Test symptom analysis:"
Write-Host "     curl -X POST http://localhost:8000/v1/symptoms/analyze \"
Write-Host "       -H 'X-API-Key: dev-internal-key' \"
Write-Host "       -H 'Content-Type: application/json' \"
Write-Host "       -d '{\"text\":\"My dog has a mild cough\",\"pet_species\":\"dog\",\"pet_age\":3}'"
