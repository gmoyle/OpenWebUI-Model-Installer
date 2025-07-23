# Ensure Docker and WSL2 installation

$ErrorActionPreference = "Stop"

# Function to check if a command exists
function Command-Exists {
    param([string]$cmd)
    return (Get-Command $cmd -ErrorAction SilentlyContinue) -ne $null
}

# Function to prompt the user for elevated permissions
function Require-Administrator {
    if (-not [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) {
        Write-Host "This script requires administrator privileges. Please run PowerShell as Administrator."
        Exit
    }
}

# Prompt for elevated permissions
Require-Administrator

# Check if Docker is installed
if (-not (Command-Exists "docker")) {
    Write-Host "Docker is not installed. Installing Docker Desktop..."
    # Check if Chocolatey is installed
    if (-not (Command-Exists "choco")) {
        Write-Host "Chocolatey is not installed. Installing Chocolatey first."
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    }
    # Install Docker using Chocolatey
    choco install docker-desktop -y
    Write-Host "Docker Desktop has been installed. Please restart your system to complete the installation."
    Exit
}

# Check if Docker is running
if (-not (docker info)) {
    Write-Host "Docker is not running. Please start Docker Desktop."
    Exit
}

# Check for WSL2 installation
function Check-WSL2 {
    $wslVersion = (wsl --list --verbose) -match "WSL 2" 
    if (-not $wslVersion) {
        Write-Host "WSL2 is not installed. Installing WSL2..."
        wsl --install
        Write-Host "WSL2 installation complete. Please restart your system."
        Exit
    }
}

Check-WSL2

# Check if Docker is using WSL2 as the backend
function Check-Docker-WSL2-Backend {
    $dockerVersion = docker info | Select-String "OSType"
    if ($dockerVersion -notmatch "linux") {
        Write-Host "Docker is not using WSL2 as the backend. Please configure Docker Desktop to use WSL2."
        Write-Host "To do this, open Docker Desktop settings, go to 'General' and select 'Use the WSL 2 based engine'."
        Write-Host "You may also need to enable the 'Use the Windows Subsystem for Linux' feature in Docker settings."
        Exit
    }
}

Check-Docker-WSL2-Backend

# Check Hyper-V and Virtualization
function Check-HyperV {
    $hyperV = dism /online /get-feature /featurename:Microsoft-Hyper-V-All | findstr /C:"Enabled"
    if (-not $hyperV) {
        Write-Host "Hyper-V is not enabled. Enabling Hyper-V..."
        dism /online /enable-feature /all /featurename:Microsoft-Hyper-V-All
        Write-Host "Hyper-V has been enabled. Please restart your system to complete the setup."
        Exit
    }
}

Check-HyperV

# Check virtualization status
function Check-Virtualization {
    $isVirtualizationEnabled = (Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty VirtualizationFirmwareEnabled)
    if (-not $isVirtualizationEnabled) {
        Write-Host "Virtualization is not enabled in BIOS. Please reboot your system and enable virtualization in the BIOS settings."
        Exit
    }
}

Check-Virtualization

# Check disk space
function Check-DiskSpace {
    $diskSpace = (Get-PSDrive -Name C).Used / 1GB
    if ($diskSpace -gt 70) {
        Write-Host "Warning: Disk space is below 30GB. It is recommended to have at least 30GB of free disk space for Docker containers."
        Write-Host "Please free up space if necessary."
    }
}

Check-DiskSpace

# Check if File Sharing for Docker is set up
function Check-FileSharing {
    Write-Host "Checking if file sharing for Docker is properly configured..."

    # Check for shared drive configuration in Docker Desktop
    $sharedFolderConfig = docker info | Select-String "Docker Root Dir"
    if (-not $sharedFolderConfig) {
        Write-Host "Docker file sharing is not properly configured. Please open Docker Desktop and configure file sharing for your drives."
        Write-Host "You can configure shared drives by going to Docker Desktop settings -> Shared Drives."
        Exit
    }
}

Check-FileSharing

# Start Docker containers
Write-Host "Starting Docker containers for OpenWebUI and Ollama..."

# Create necessary Docker volumes and directories
$openwebuiDataDir = "$env:USERPROFILE\openwebui-data"
$ollamaDataDir = "$env:USERPROFILE\ollama-data"

# Create directories if they don't exist
if (-not (Test-Path $openwebuiDataDir)) {
    Write-Host "Creating OpenWebUI data directory..."
    New-Item -Path $openwebuiDataDir -ItemType Directory
}

if (-not (Test-Path $ollamaDataDir)) {
    Write-Host "Creating Ollama data directory..."
    New-Item -Path $ollamaDataDir -ItemType Directory
}

# Starting containers using Docker commands
docker run -d --name openwebui -v $openwebuiDataDir:/data open-webui:latest
docker run -d --name ollama -v $ollamaDataDir:/data ollama:latest

Write-Host "OpenWebUI and Ollama containers have been started."

# End of Script
Write-Host "Installation complete. You can now access OpenWebUI and Ollama."
