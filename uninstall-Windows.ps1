# PowerShell Uninstaller for Open WebUI + Ollama

# Function to check if Docker is installed
function Check-Docker {
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker is not installed."
        exit
    }
}

# Function to check if Docker is running
function Check-Docker-Running {
    try {
        docker info | Out-Null
    } catch {
        Write-Host "❌ Docker is not running. Please start Docker Desktop."
        exit
    }
}

# Check Docker installation
Check-Docker

# Ensure Docker is running
Check-Docker-Running

$INSTALL_DIR = Get-Location
$DATA_DIR = "$env:USERPROFILE\openwebui-ollama-data"
$VOLUME_NAME = "ollama_data"

# Confirm before uninstalling
$confirmation = Read-Host "⚠️ This will remove containers, volumes, and local data. Are you sure? [y/N]"
if ($confirmation -notmatch "^[Yy]$") {
    Write-Host "❌ Uninstall canceled."
    exit
}

# Stop and remove containers
Write-Host "🛑 Stopping and removing containers..."
docker stop openwebui ollama
docker rm openwebui ollama

# Remove images
Write-Host "🧼 Removing Docker images..."
docker rmi ollama/ollama ghcr.io/open-webui/open-webui:main

# Remove volumes
Write-Host "🧼 Removing Docker volumes..."
docker volume rm $VOLUME_NAME

# Remove data directory
if (Test-Path $DATA_DIR) {
    Write-Host "🗑️ Removing data directory: $DATA_DIR"
    Remove-Item -Recurse -Force $DATA_DIR
} else {
    Write-Host "ℹ️ No data directory found at $DATA_DIR"
}

Write-Host "✅ Uninstallation complete."
