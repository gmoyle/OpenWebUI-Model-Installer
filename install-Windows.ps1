# install-Windows.ps1

# Check for Docker and its status
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed. Please install Docker Desktop for Windows."
    exit 1
}

# Check if Docker is running
try {
    $dockerInfo = docker info
} catch {
    Write-Error "Docker is not running. Please start Docker Desktop for Windows."
    exit 1
}

# Define variables
$INSTALL_DIR = Get-Location
$DATA_DIR = "$env:USERPROFILE\openwebui-ollama-data"
$MODEL = "phi3"  # Default model
$DOCKER_COMPOSE_YML = "$INSTALL_DIR\docker-compose.yml"

# Prompt for model selection
Write-Host "Select a model by number (1-4):"
Write-Host "1) phi3        - ⚡⚡⚡⚡ Very Fast | 3.8B | ~4GB RAM"
Write-Host "2) mistral     - ⚡⚡ Moderate    | 7B   | ~8GB RAM"
Write-Host "3) llama3      - ⚡  Slower      | 8B   | ~8GB+ RAM"
Write-Host "4) codellama   - 🐌 Slowest     | 13B  | ~12GB+ RAM"
$ModelChoice = Read-Host "Your choice [1-4]"

switch ($ModelChoice) {
    1 { $MODEL = "phi3" }
    2 { $MODEL = "mistral" }
    3 { $MODEL = "llama3" }
    4 { $MODEL = "codellama" }
    default { Write-Host "Invalid choice, defaulting to phi3."; $MODEL = "phi3" }
}

Write-Host "You selected: $MODEL"

# Prompt for custom data directories
$OPENWEBUI_DATA_PATH = Read-Host "Enter path for OpenWebUI data [$env:USERPROFILE\openwebui-data]"
if (-not $OPENWEBUI_DATA_PATH) { $OPENWEBUI_DATA_PATH = "$env:USERPROFILE\openwebui-data" }

$OLLAMA_DATA_PATH = Read-Host "Enter path for Ollama data [$env:USERPROFILE\ollama-data]"
if (-not $OLLAMA_DATA_PATH) { $OLLAMA_DATA_PATH = "$env:USERPROFILE\ollama-data" }

# Create necessary directories if they do not exist
Write-Host "Creating data directories..."
if (-not (Test-Path $OPENWEBUI_DATA_PATH)) { New-Item -ItemType Directory -Force -Path $OPENWEBUI_DATA_PATH }
if (-not (Test-Path $OLLAMA_DATA_PATH)) { New-Item -ItemType Directory -Force -Path $OLLAMA_DATA_PATH }

# Pull Docker images
Write-Host "Pulling Docker images..."
docker pull ollama/ollama
docker pull ghcr.io/open-webui/open-webui:main

# Start Ollama container
Write-Host "Starting Ollama container..."
docker run -d --name ollama --restart unless-stopped -v "${OLLAMA_DATA_PATH}:/root/.ollama" -p 11434:11434 --network bridge ollama/ollama

# Skip waiting for Ollama in CI environment, proceed directly to pulling the model and starting OpenWebUI

# Pull the selected model
Write-Host "Pulling model: $MODEL ..."
ollama pull $MODEL

# Start Open WebUI container
Write-Host "Starting Open WebUI container..."
docker run -d --name openwebui --restart unless-stopped -v "${OPENWEBUI_DATA_PATH}:/app/backend/data" -e "OLLAMA_API_BASE_URL=http://localhost:11434" -p 3000:3000 --network bridge ghcr.io/open-webui/open-webui:main

Write-Host "✅ Setup complete!"
Write-Host "Visit OpenWebUI at: http://localhost:3000"
