$scriptPath = $MyInvocation.MyCommand.Path

function Prompt-Remove {
    param(
        [string]$Message = "Would you like to remove this component? [Y]es/[N]o:"
    )
    do {
        $removeChoice = Read-Host $Message
    } while ($removeChoice -notin @("y", "Y", "n", "N"))
    return $removeChoice -in @("y", "Y")
}

function Ensure-Elevation {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script needs to run as Administrator. Relaunching with elevated privileges..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

Ensure-Elevation

Write-Host "Starting uninstallation process..."

# --- Uninstall WSL ---
if (Test-WSLInstalled) {
    if (Prompt-Remove "WSL is installed. Would you like to uninstall WSL and remove all Linux distributions? [Y]es/[N]o:") {
        Write-Host "Uninstalling WSL..."
        dism.exe /online /disable-feature /featurename:Microsoft-Windows-Subsystem-Linux /norestart
        Write-Host "WSL uninstalled."
    }
} else {
    Write-Host "WSL is not installed."
}

# --- Uninstall Docker ---
if (Test-DockerInstalled) {
    if (Prompt-Remove "Docker is installed. Would you like to uninstall Docker Desktop? [Y]es/[N]o:") {
        Write-Host "Uninstalling Docker..."
        Stop-Service -Name com.docker.service
        Start-Process -FilePath "C:\Program Files\Docker\Docker\Docker Desktop Installer.exe" -ArgumentList "uninstall" -Wait
        Write-Host "Docker uninstalled."
    }
} else {
    Write-Host "Docker is not installed."
}

# --- Remove Scheduled Task ---
try {
    if (Get-ScheduledTask -TaskName "OpenWebUIResumeInstall" -ErrorAction SilentlyContinue) {
        if (Prompt-Remove "Scheduled task 'OpenWebUIResumeInstall' exists. Would you like to remove it? [Y]es/[N]o:") {
            Unregister-ScheduledTask -TaskName "OpenWebUIResumeInstall" -Confirm:$false
            Write-Host "Scheduled task 'OpenWebUIResumeInstall' removed."
        }
    }
} catch {
    Write-Warning "Failed to remove scheduled task 'OpenWebUIResumeInstall'. You may need to remove it manually."
}

# --- Clean Up Docker Containers ---
if (Test-DockerInstalled) {
    if (Prompt-Remove "Would you like to remove all Docker containers? [Y]es/[N]o:") {
        Write-Host "Removing all Docker containers..."
        docker container prune -f
        Write-Host "Docker containers removed."
    }
}

# --- Remove OpenWebUI Data ---
$openWebUIDir = "$env:USERPROFILE\openwebui-ollama-data"
if (Test-Path $openWebUIDir) {
    if (Prompt-Remove "Would you like to remove OpenWebUI data stored at '$openWebUIDir'? [Y]es/[N]o:") {
        Remove-Item -Recurse -Force $openWebUIDir
        Write-Host "OpenWebUI data removed."
    }
}

# --- Remove Ollama Data ---
$ollamaDir = "$env:USERPROFILE\ollama-data"
if (Test-Path $ollamaDir) {
    if (Prompt-Remove "Would you like to remove Ollama data stored at '$ollamaDir'? [Y]es/[N]o:") {
        Remove-Item -Recurse -Force $ollamaDir
        Write-Host "Ollama data removed."
    }
}

# --- Clean Up Docker Images ---
if (Test-DockerInstalled) {
    if (Prompt-Remove "Would you like to remove all Docker images? [Y]es/[N]o:") {
        Write-Host "Removing all Docker images..."
        docker image prune -a -f
        Write-Host "Docker images removed."
    }
}

Write-Host "Uninstallation process completed."
