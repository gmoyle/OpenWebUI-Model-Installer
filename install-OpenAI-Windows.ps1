# OpenWebUI AI Model Installer for Windows
# Enhanced version with OpenAI models and Arena mode support

param(
    [switch]$SkipChecks = $false
)

# Configuration
$DEFAULT_OPENWEBUI_DATA = "$env:USERPROFILE\openwebui-data"
$DEFAULT_OLLAMA_DATA = "$env:USERPROFILE\ollama-data"

# Helper Functions
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-Docker {
    Write-Host "Checking Docker..." -ForegroundColor Yellow
    
    if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker is not installed." -ForegroundColor Red
        Write-Host "Installing Docker Desktop using Chocolatey..." -ForegroundColor Yellow
        
        # Install Chocolatey if not present
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        }
        
        # Install Docker Desktop
        choco install docker-desktop -y
        Write-Host "⚠️  Please restart this script after Docker Desktop installation completes." -ForegroundColor Yellow
        exit 1
    }
    
    # Test if Docker is running
    try {
        docker info | Out-Null
        Write-Host "✅ Docker is running." -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Docker is not running." -ForegroundColor Red
        Write-Host "Please start Docker Desktop and rerun the script." -ForegroundColor Yellow
        exit 1
    }
}

function Test-SystemRequirements {
    Write-Host "Checking system requirements..." -ForegroundColor Yellow
    
    # Check available RAM
    $totalRAM = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
    Write-Host "💻 Available RAM: ${totalRAM}GB" -ForegroundColor Cyan
    
    # Check available disk space
    $disk = Get-CimInstance Win32_LogicalDisk | Where-Object { $_.DeviceID -eq $env:SystemDrive }
    $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB)
    Write-Host "💾 Available disk space: ${freeSpaceGB}GB" -ForegroundColor Cyan
    
    if ($freeSpaceGB -lt 50) {
        Write-Host "⚠️  Warning: You have less than 50GB of available disk space." -ForegroundColor Yellow
        Write-Host "   The model download may require significant storage." -ForegroundColor Yellow
        $continue = Read-Host "Do you want to continue? (y/N)"
        if ($continue -notmatch '^[Yy]$') {
            Write-Host "Installation cancelled." -ForegroundColor Red
            exit 1
        }
    }
    
    return $totalRAM
}

function Test-ExistingInstallation {
    $ollamaRunning = $false
    $openwebuiRunning = $false
    
    # Check if containers exist and are running
    try {
        $ollamaContainer = docker ps -q -f name=ollama 2>$null
        if ($ollamaContainer) {
            $ollamaRunning = $true
        }
    } catch {}
    
    try {
        $openwebuiContainer = docker ps -q -f name=openwebui 2>$null
        $openwebuiContainer2 = docker ps -q -f name=open-webui 2>$null
        if ($openwebuiContainer -or $openwebuiContainer2) {
            $openwebuiRunning = $true
        }
    } catch {}
    
    return ($ollamaRunning -and $openwebuiRunning)
}

function Show-ExistingModels {
    Write-Host "📚 Currently installed models:" -ForegroundColor Cyan
    try {
        $models = docker exec ollama ollama list 2>$null
        if ($models) {
            $models | Select-Object -Skip 1 | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object {
                Write-Host $_ -ForegroundColor White
            }
        } else {
            Write-Host "   No models installed yet." -ForegroundColor Gray
        }
    } catch {
        Write-Host "   Unable to retrieve model list." -ForegroundColor Gray
    }
    Write-Host ""
}

function Get-DataPaths {
    Write-Host "Enter path for OpenWebUI data [$DEFAULT_OPENWEBUI_DATA]: " -NoNewline
    $openwebuiPath = Read-Host
    if ([string]::IsNullOrWhiteSpace($openwebuiPath)) {
        $openwebuiPath = $DEFAULT_OPENWEBUI_DATA
    }
    
    Write-Host "Enter path for Ollama data [$DEFAULT_OLLAMA_DATA]: " -NoNewline
    $ollamaPath = Read-Host
    if ([string]::IsNullOrWhiteSpace($ollamaPath)) {
        $ollamaPath = $DEFAULT_OLLAMA_DATA
    }
    
    # Expand environment variables
    $openwebuiPath = [Environment]::ExpandEnvironmentVariables($openwebuiPath)
    $ollamaPath = [Environment]::ExpandEnvironmentVariables($ollamaPath)
    
    return @{
        OpenWebUI = $openwebuiPath
        Ollama = $ollamaPath
    }
}

# Main Script
Write-Host "🚀 AI Model Installer for Windows" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""

# Check if running as administrator
if (!(Test-Administrator)) {
    Write-Host "⚠️  This script requires administrator privileges." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    exit 1
}

$totalRAM = Test-SystemRequirements
Test-Docker

# Check if installation already exists
$existingInstall = Test-ExistingInstallation

if ($existingInstall) {
    Write-Host "✅ Found existing OpenWebUI + Ollama installation!" -ForegroundColor Green
    Write-Host "   OpenWebUI: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "   Ollama API: http://localhost:11434" -ForegroundColor Cyan
    Write-Host ""
    Show-ExistingModels
    Write-Host "What would you like to do?"
    Write-Host "1) Install additional models"
    Write-Host "2) Fresh install (remove existing setup)"
    Write-Host "3) Exit"
    Write-Host ""
    $actionChoice = Read-Host "Your choice [1-3]"
    Write-Host ""
    
    switch ($actionChoice) {
        "1" {
            $existingInstallFlag = $true
        }
        "2" {
            Write-Host "Removing existing containers..." -ForegroundColor Yellow
            docker stop ollama openwebui open-webui 2>$null | Out-Null
            docker rm ollama openwebui open-webui 2>$null | Out-Null
            Write-Host "Existing setup removed. Starting fresh installation..." -ForegroundColor Green
            $existingInstallFlag = $false
        }
        "3" {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Host "Invalid choice. Exiting." -ForegroundColor Red
            exit 1
        }
    }
} else {
    $existingInstallFlag = $false
}

Write-Host "Select a model to install:" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 OpenAI Models (Advanced):" -ForegroundColor Magenta
Write-Host "1) gpt-oss:20b   - 🔥 Advanced reasoning | 20B  | ~16GB+ VRAM/RAM"
Write-Host "2) gpt-oss:120b  - 🔥 Most advanced     | 120B | ~60GB+ VRAM/RAM"
Write-Host ""
Write-Host "⚡ Premium Models (Fast & Capable):" -ForegroundColor Yellow
Write-Host "3) mistral       - ⚡⚡⚡ Fast          | 7B   | ~8GB RAM"
Write-Host "4) llama3.2      - ⚡⚡ Latest Meta     | 3B   | ~4GB RAM"
Write-Host "5) qwen2.5:3b    - ⚡⚡ Great reasoning | 3B   | ~4GB RAM"
Write-Host ""
Write-Host "🏃 Lightweight Models (Very Fast):" -ForegroundColor Green
Write-Host "6) phi3          - ⚡⚡⚡⚡ Very Fast      | 3.8B | ~4GB RAM"
Write-Host "7) gemma2:2b     - ⚡⚡⚡⚡ Ultra Fast    | 2B   | ~3GB RAM"
Write-Host ""
Write-Host "🛠️  Specialized Models:" -ForegroundColor Blue
Write-Host "8) codellama     - 💻 Code-focused     | 13B  | ~12GB+ RAM"
Write-Host "9) Install multiple models (Arena mode setup)" -ForegroundColor Cyan
Write-Host ""
$modelChoice = Read-Host "Your choice [1-9]"

switch ($modelChoice) {
    "1" {
        $models = @("gpt-oss:20b")
        $ramRequirements = @("16GB+ VRAM/RAM")
        $modelTypes = @("openai")
    }
    "2" {
        $models = @("gpt-oss:120b")
        $ramRequirements = @("60GB+ VRAM/RAM")
        $modelTypes = @("openai")
    }
    "3" {
        $models = @("mistral")
        $ramRequirements = @("8GB RAM")
        $modelTypes = @("ollama")
    }
    "4" {
        $models = @("llama3.2")
        $ramRequirements = @("4GB RAM")
        $modelTypes = @("ollama")
    }
    "5" {
        $models = @("qwen2.5:3b")
        $ramRequirements = @("4GB RAM")
        $modelTypes = @("ollama")
    }
    "6" {
        $models = @("phi3")
        $ramRequirements = @("4GB RAM")
        $modelTypes = @("ollama")
    }
    "7" {
        $models = @("gemma2:2b")
        $ramRequirements = @("3GB RAM")
        $modelTypes = @("ollama")
    }
    "8" {
        $models = @("codellama")
        $ramRequirements = @("12GB+ RAM")
        $modelTypes = @("ollama")
    }
    "9" {
        if ($totalRAM -ge 16) {
            $models = @("phi3", "gemma2:2b", "llama3.2", "qwen2.5:3b", "mistral")
            $ramRequirements = @("4GB", "3GB", "4GB", "4GB", "8GB")
            $modelTypes = @("ollama", "ollama", "ollama", "ollama", "ollama")
            Write-Host "🏟️  Installing Arena setup (5 models for comparison)" -ForegroundColor Cyan
        } elseif ($totalRAM -ge 12) {
            $models = @("phi3", "gemma2:2b", "llama3.2", "qwen2.5:3b")
            $ramRequirements = @("4GB", "3GB", "4GB", "4GB")
            $modelTypes = @("ollama", "ollama", "ollama", "ollama")
            Write-Host "🏟️  Installing Arena setup (4 models - optimized for your RAM)" -ForegroundColor Cyan
        } else {
            $models = @("phi3", "gemma2:2b", "llama3.2")
            $ramRequirements = @("4GB", "3GB", "4GB")
            $modelTypes = @("ollama", "ollama", "ollama")
            Write-Host "🏟️  Installing Arena setup (3 lightweight models for your system)" -ForegroundColor Cyan
        }
    }
    default {
        Write-Host "Invalid choice. Exiting." -ForegroundColor Red
        exit 1
    }
}

# Show selection summary
if ($models.Count -eq 1) {
    Write-Host "You selected: $($models[0]) ($($ramRequirements[0]))" -ForegroundColor Green
} else {
    Write-Host "You selected $($models.Count) models for Arena mode:" -ForegroundColor Green
    for ($i = 0; $i -lt $models.Count; $i++) {
        Write-Host "  - $($models[$i]) ($($ramRequirements[$i]))" -ForegroundColor White
    }
}
Write-Host ""

# Set up containers only if not existing installation
if (!$existingInstallFlag) {
    $paths = Get-DataPaths
    
    Write-Host ""
    Write-Host "Creating data directories..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $paths.OpenWebUI -Force | Out-Null
    New-Item -ItemType Directory -Path $paths.Ollama -Force | Out-Null
    
    Write-Host ""
    Write-Host "Pulling Docker images..." -ForegroundColor Yellow
    docker pull ollama/ollama
    docker pull ghcr.io/open-webui/open-webui:main
    
    Write-Host ""
    Write-Host "Starting Ollama container..." -ForegroundColor Yellow
    docker run -d `
        --name ollama `
        --restart unless-stopped `
        -v "$($paths.Ollama):/root/.ollama" `
        -p 11434:11434 `
        ollama/ollama
    
    # Wait for Ollama to be ready
    Write-Host "Waiting for Ollama to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host ""
    Write-Host "Starting Open WebUI container..." -ForegroundColor Yellow
    docker run -d `
        --name openwebui `
        --restart unless-stopped `
        -v "$($paths.OpenWebUI):/app/backend/data" `
        -e "OLLAMA_BASE_URL=http://host.docker.internal:11434" `
        -p 3000:8080 `
        ghcr.io/open-webui/open-webui:main
    
    Write-Host "Waiting for OpenWebUI to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}

# Install models
Write-Host ""
Write-Host "Installing selected models..." -ForegroundColor Yellow
$successfulModels = @()
$failedModels = @()

for ($i = 0; $i -lt $models.Count; $i++) {
    $model = $models[$i]
    $modelType = $modelTypes[$i]
    
    Write-Host ""
    if ($modelType -eq "openai") {
        Write-Host "Installing OpenAI model: $model" -ForegroundColor Magenta
    } else {
        Write-Host "Installing model: $model" -ForegroundColor Cyan
    }
    
    try {
        docker exec ollama ollama pull $model
        Write-Host "✅ Model '$model' installed successfully." -ForegroundColor Green
        $successfulModels += $model
    } catch {
        Write-Host "❌ Failed to install model '$model'." -ForegroundColor Red
        $failedModels += $model
    }
}

Write-Host ""
Write-Host "🎉 Installation Summary" -ForegroundColor Green
Write-Host "======================="
Write-Host ""

if ($successfulModels.Count -gt 0) {
    Write-Host "✅ Successfully installed models:" -ForegroundColor Green
    foreach ($model in $successfulModels) {
        Write-Host "   - $model" -ForegroundColor White
    }
}

if ($failedModels.Count -gt 0) {
    Write-Host ""
    Write-Host "❌ Failed to install models:" -ForegroundColor Red
    foreach ($model in $failedModels) {
        Write-Host "   - $model" -ForegroundColor White
    }
    Write-Host "   Please check your internet connection and disk space." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ OpenWebUI: http://localhost:3000" -ForegroundColor Green
Write-Host "✅ Ollama API: http://localhost:11434" -ForegroundColor Green
Write-Host ""

if ($successfulModels.Count -gt 1) {
    Write-Host "🏟️  Arena Mode Ready! You can now compare multiple models side-by-side." -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host "1. Open your web browser and go to http://localhost:3000"
Write-Host "2. Create an account or sign in"
if ($successfulModels.Count -gt 1) {
    Write-Host "3. Try Arena mode to compare your models!"
} else {
    Write-Host "3. Start chatting with your model!"
}
Write-Host ""
Write-Host "💡 Tip: The first response may take a moment as models load into memory." -ForegroundColor Yellow
Write-Host ""
Write-Host "🛠️  To stop the services:" -ForegroundColor Blue
Write-Host "   docker stop ollama open-webui"
Write-Host ""
Write-Host "🔄 To restart the services:" -ForegroundColor Blue
Write-Host "   docker start ollama open-webui"
Write-Host ""
Write-Host "🔄 To run this script again to add more models:" -ForegroundColor Blue
Write-Host "   Invoke-Expression (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/gmoyle/OpenWebUI-Model-Installer/main/install-OpenAI-Windows.ps1' -UseBasicParsing).Content"
