# install-Windows.ps1

# Function to check if a command exists
function Command-Exists {
    param([string]$command)
    return (Get-Command $command -ErrorAction SilentlyContinue) -ne $null
}

# Ensure Docker is installed and running
Write-Host "`n🔍 Checking Docker installation..."
if (!(Command-Exists "docker")) {
    Write-Error "❌ Docker is not installed. Please install Docker Desktop for Windows and try again."
    exit 1
}

try {
    docker info | Out-Null
} catch {
    Write-Error "❌ Docker is installed but not running. Please start Docker Desktop and try again."
    exit 1
}

# Model options
$models = @{
    "1" = @{ name = "phi3";      desc = "⚡⚡⚡⚡ Very Fast | 3.8B | ~4GB RAM" }
    "2" = @{ name = "mistral";   desc = "⚡⚡ Moderate    | 7B   | ~8GB RAM" }
    "3" = @{ name = "llama3";    desc = "⚡  Slower      | 8B   | ~8GB+ RAM" }
    "4" = @{ name = "codellama"; desc = "🐌 Slowest     | 13B  | ~12GB+ RAM" }
}

Write-Host "`n🤖 Available Ollama models to auto-pull:`n"
foreach ($key in $models.Keys) {
    $model = $models[$key]
    Write-Host "$key) $($model.name) - $($model.desc)"
}

$modelChoice = Read-Host "`nSelect a model by number (default: 1)"
if (-not $modelChoice -or -not $models.ContainsKey($modelChoice)) {
    Write-Host "⚠️ No valid choice entered, defaulting to model 1 (phi3)."
    $modelChoice = "1"
}
$selectedModel = $models[$modelChoice].name

# Pull model from Ollama
Write-Host "`n📦 Pulling model '$selectedModel' from Ollama..."
docker pull "ollama/$selectedModel" || Write-Host "⚠️ Model will be pulled on first use if not found."

# Clean up any old containers
Write-Host "`n🧹 Stopping and removing any existing containers named 'ollama' or 'open-webui'..."
docker rm -f ollama open-webui 2>$null

# Run Ollama
Write-Host "`n🚀 Starting Ollama container..."
docker run -d --name ollama -p 11434:11434 --restart unless-stopped ollama/ollama

# Wait a moment for it to be ready
Start-Sleep -Seconds 5

# Run Open WebUI
Write-Host "`n🌐 Starting Open WebUI container (http://localhost:3000)..."
docker run -d --name open-webui --network=host --restart unless-stopped -e OLLAMA_BASE_URL=http://localhost:11434 ghcr.io/open-webui/open-webui:main

# Optional: auto-pull selected model in Ollama container
Write-Host "`n📥 Sending model pull command to Ollama backend..."
Invoke-WebRequest -Uri "http://localhost:11434/api/pull" -Method POST -Body (@{ name = "$selectedModel" } | ConvertTo-Json) -ContentType "application/json" | Out-Null

Write-Host "`n✅ Setup complete! Access Open WebUI at: http://localhost:3000"
Write-Host "You can also use Ollama locally at: http://localhost:11434"
