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

# Function to check if Ollama container is running
function Wait-For-Container {
    param([string]$containerName, [int]$timeoutSec = 30)

    $endTime = (Get-Date).AddSeconds($timeoutSec)
    while ((Get-Date) -lt $endTime) {
        $status = docker inspect -f '{{.State.Status}}' $containerName
        if ($status -eq "running") {
            Write-Host "✅ $containerName is running."
            return $true
        }
        Write-Host "⏳ Waiting for $containerName to start..."
        Start-Sleep -Seconds 5
    }

    Write-Error "❌ $containerName did not start within $timeoutSec seconds."
    return $false
}

# Start the Ollama container
Write-Host "`n🚀 Starting Ollama container..."
docker run -d --name ollama -p 11434:11434 --restart unless-stopped ollama/ollama

# Wait for Ollama container to be fully running
if (-not (Wait-For-Container -containerName "ollama" -timeoutSec 60)) {
    Write-Error "❌ Ollama container failed to start in time."
    exit 1
}

# Now send the request to pull the model
Write-Host "`n📥 Sending model pull command to Ollama backend..."
Invoke-WebRequest -Uri "http://localhost:11434/api/pull" -Method POST -Body (@{ name = "$selectedModel" } | ConvertTo-Json) -ContentType "application/json" | Out-Null
Write-Host "✅ Model pull request sent successfully."

# Clean up any old containers
Write-Host "`n🧹 Stopping and removing any existing containers named 'ollama' or 'open-webui'..."
docker rm -f ollama open-webui

Write-Host "`n🎉 Installation complete! The OpenWebUI and Ollama containers should now be running."
