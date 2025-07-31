$scriptPath = $MyInvocation.MyCommand.Path
$ScheduledTaskName = "OpenWebUIResumeInstall"

function Prompt-Reboot {
    param(
        [string]$Message = "Rebooting is required. Reboot now? [Y]es/[N]o:"
    )
    do {
        $rebootChoice = Read-Host $Message
    } while ($rebootChoice -notin @("y", "Y", "n", "N"))
    return $rebootChoice -in @("y", "Y")
}

function Ensure-Elevation {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "This script needs to run as Administrator. Relaunching with elevated privileges..."
        Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$scriptPath`"" -Verb RunAs
        exit
    }
}

Ensure-Elevation

if ($env:RESUME_AFTER_REBOOT -eq "WSL") {
    Write-Host "Resuming after WSL install reboot..."
    $env:RESUME_AFTER_REBOOT = ""
    [Environment]::SetEnvironmentVariable("RESUME_AFTER_REBOOT", $null, [System.EnvironmentVariableTarget]::User)
    try {
        Register-ScheduledTask -TaskName $ScheduledTaskName -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`"") -Trigger (New-ScheduledTaskTrigger -AtLogOn) -RunLevel Highest -Force
    } catch {
        Write-Warning "Failed to register resume scheduled task. $_"
    }
}

if ($env:RESUME_AFTER_REBOOT -eq "Docker") {
    Write-Host "Resuming after Docker install reboot..."
    $env:RESUME_AFTER_REBOOT = ""
    [Environment]::SetEnvironmentVariable("RESUME_AFTER_REBOOT", $null, [System.EnvironmentVariableTarget]::User)
}

function Test-WSLInstalled {
    return (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -eq "Enabled"
}

function Test-DockerInstalled {
    return Get-Command docker -ErrorAction SilentlyContinue
}

if (-not (Test-WSLInstalled)) {
    Write-Host "WSL is not installed. Installing..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    $env:RESUME_AFTER_REBOOT = "WSL"
    [Environment]::SetEnvironmentVariable("RESUME_AFTER_REBOOT", "WSL", [System.EnvironmentVariableTarget]::User)
    if (Prompt-Reboot "Rebooting is required to complete WSL installation. Reboot now? [Y]es/[N]o:") {
        Restart-Computer
        exit
    } else {
        Write-Host "Please reboot manually and re-run the script to continue."
        exit
    }
}

if (-not (Test-DockerInstalled)) {
    Write-Warning "Docker is not installed. Please install Docker Desktop for Windows."
    $downloadChoice = Read-Host "Do you want to download and install Docker Desktop now? [Y]es/[N]o:"
    if ($downloadChoice -in @("y", "Y")) {
        $dockerInstallerPath = "$env:TEMP\DockerDesktopInstaller.exe"
        $dockerUrl = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
        Write-Host "Downloading Docker Desktop installer..."
        Invoke-WebRequest -Uri $dockerUrl -OutFile $dockerInstallerPath -UseBasicParsing
        Write-Host "Running Docker Desktop installer..."
        Start-Process -FilePath $dockerInstallerPath -Wait
        $env:RESUME_AFTER_REBOOT = "Docker"
        [Environment]::SetEnvironmentVariable("RESUME_AFTER_REBOOT", "Docker", [System.EnvironmentVariableTarget]::User)
        if (Prompt-Reboot "Rebooting is required to complete Docker installation. Reboot now? [Y]es/[N]o:") {
            Restart-Computer
            exit
        } else {
            Write-Host "Please reboot manually and re-run the script to continue."
            exit
        }
    } else {
        Write-Host "Docker installation skipped. Exiting."
        exit
    }
}

Write-Host "All dependencies are installed. Proceeding with the rest of the installation..."

# --- Cleanup resume scheduled task ---
try {
    if (Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue) {
        Write-Host "`nCleaning up scheduled task '$ScheduledTaskName'..."
        Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$false
        Write-Host "Scheduled task '$ScheduledTaskName' removed."
    }
} catch {
    Write-Warning "Failed to remove scheduled task '$ScheduledTaskName'. You may need to remove it manually."
}

# --- Memory-based model recommendation ---
function Get-InstalledMemoryGB {
    try {
        # Get the total physical memory (RAM) from the system
        $totalMemoryBytes = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory
        $totalMemoryGB = [math]::Round($totalMemoryBytes / 1GB, 2)
        
        Write-Host "Detected system memory: $totalMemoryGB GB"
        return $totalMemoryGB
    }
    catch {
        Write-Host "Error while checking system memory: $_"
        return 0
    }
}

function Recommend-Models {
    $memoryGB = Get-InstalledMemoryGB
    if ($memoryGB -eq 0) {
        Write-Warning "Unable to determine system memory. Exiting script."
        exit 1
    }

    Write-Host "`nDetected memory: $memoryGB GB"

    $models = @(
        @{ Name = "phi3:3.8b"; RAM = 4; Speed = 1 },
        @{ Name = "gemma:2b"; RAM = 6; Speed = 2 },
        @{ Name = "llama3:8b"; RAM = 8; Speed = 3 },
        @{ Name = "mistral:7b"; RAM = 10; Speed = 4 },
        @{ Name = "llama3:8b-instruct"; RAM = 11; Speed = 5 },
        @{ Name = "gemma:7b"; RAM = 12; Speed = 6 },
        @{ Name = "llama2:13b"; RAM = 14; Speed = 7 },
        @{ Name = "mistral:7b-instruct"; RAM = 15; Speed = 8 }
    )

    $recommended = $models |
        Where-Object { $_.RAM -le $memoryGB } |
        Sort-Object Speed |
        Select-Object -First 5

    if ($recommended.Count -eq 0) {
        Write-Warning "No models found that fit in available memory."
    } else {
        Write-Host "`nTop 5 compatible models based on available RAM:"
        $recommended | ForEach-Object {
            Write-Host " - $($_.Name) (Requires $_.RAM GB RAM)"
        }

        # Optional: prompt to auto-pull one
        $selected = Read-Host "`nEnter a model to pull now (or press Enter to skip)"
        if ($selected) { ollama pull $selected }
    }
}

Recommend-Models
