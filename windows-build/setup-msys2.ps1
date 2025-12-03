# Ardour Windows Build - MSYS2 Setup Script
# This script downloads and installs MSYS2, then configures it for building Ardour

param(
    [switch]$SkipDownload,
    [switch]$SkipUpdate,
    [string]$InstallPath = "C:\msys64"
)

$ErrorActionPreference = "Stop"

# MSYS2 installer configuration
$MSYS2_VERSION = "20241116"
$MSYS2_INSTALLER = "msys2-x86_64-$MSYS2_VERSION.exe"
$MSYS2_URL = "https://github.com/msys2/msys2-installer/releases/download/$MSYS2_VERSION/$MSYS2_INSTALLER"

function Write-Status {
    param([string]$Message)
    Write-Host "[SETUP] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if MSYS2 is already installed
function Test-MSYS2Installed {
    return (Test-Path "$InstallPath\msys2_shell.cmd")
}

# Download MSYS2 installer
function Get-MSYS2Installer {
    $tempPath = Join-Path $env:TEMP $MSYS2_INSTALLER

    if (Test-Path $tempPath) {
        Write-Status "MSYS2 installer already downloaded"
        return $tempPath
    }

    Write-Status "Downloading MSYS2 installer from $MSYS2_URL..."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($MSYS2_URL, $tempPath)
        Write-Success "Downloaded MSYS2 installer"
        return $tempPath
    }
    catch {
        Write-Error "Failed to download MSYS2: $_"
        exit 1
    }
}

# Install MSYS2
function Install-MSYS2 {
    param([string]$InstallerPath)

    Write-Status "Installing MSYS2 to $InstallPath..."

    # Run installer silently
    $args = @(
        "install",
        "--root", $InstallPath,
        "--confirm-command"
    )

    Start-Process -FilePath $InstallerPath -ArgumentList $args -Wait -NoNewWindow

    if (Test-MSYS2Installed) {
        Write-Success "MSYS2 installed successfully"
    }
    else {
        Write-Error "MSYS2 installation failed"
        exit 1
    }
}

# Run a command in MSYS2
function Invoke-MSYS2Command {
    param(
        [string]$Command,
        [string]$Shell = "msys2"
    )

    $shellCmd = "$InstallPath\msys2_shell.cmd"

    switch ($Shell) {
        "mingw64" { $shellArg = "-mingw64" }
        "mingw32" { $shellArg = "-mingw32" }
        "ucrt64"  { $shellArg = "-ucrt64" }
        default   { $shellArg = "-msys2" }
    }

    $args = @($shellArg, "-defterm", "-no-start", "-here", "-c", "`"$Command`"")

    Write-Status "Running: $Command"
    $process = Start-Process -FilePath $shellCmd -ArgumentList $args -Wait -NoNewWindow -PassThru

    return $process.ExitCode
}

# Update MSYS2 packages
function Update-MSYS2 {
    Write-Status "Updating MSYS2 packages..."

    # First update - may require shell restart
    Invoke-MSYS2Command "pacman -Syu --noconfirm" | Out-Null

    # Second update to complete
    Invoke-MSYS2Command "pacman -Su --noconfirm" | Out-Null

    Write-Success "MSYS2 packages updated"
}

# Main execution
Write-Host ""
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "  Ardour Windows Build - MSYS2 Setup  " -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host ""

# Check for existing installation
if (Test-MSYS2Installed) {
    Write-Status "MSYS2 is already installed at $InstallPath"

    if (-not $SkipUpdate) {
        Update-MSYS2
    }
}
else {
    Write-Status "MSYS2 not found, starting installation..."

    if (-not $SkipDownload) {
        $installer = Get-MSYS2Installer
        Install-MSYS2 -InstallerPath $installer
    }
    else {
        Write-Error "MSYS2 not installed and -SkipDownload specified"
        exit 1
    }

    if (-not $SkipUpdate) {
        # Initial update after fresh install
        Write-Status "Running initial package update..."
        Update-MSYS2
    }
}

# Now install dependencies using the bash script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDepsScript = Join-Path $scriptDir "install-deps.sh"

if (Test-Path $installDepsScript) {
    Write-Status "Installing build dependencies..."

    # Convert Windows path to MSYS2 path
    $msysScriptDir = $scriptDir -replace "\\", "/" -replace "^([A-Za-z]):", '/$1'

    $exitCode = Invoke-MSYS2Command "cd '$msysScriptDir' && bash install-deps.sh" "mingw64"

    if ($exitCode -eq 0) {
        Write-Success "Dependencies installed successfully"
    }
    else {
        Write-Error "Failed to install dependencies (exit code: $exitCode)"
        exit 1
    }
}
else {
    Write-Warning "install-deps.sh not found, skipping dependency installation"
}

Write-Host ""
Write-Success "MSYS2 setup complete!"
Write-Host ""
Write-Host "To build Ardour, run:" -ForegroundColor White
Write-Host "  .\build.bat" -ForegroundColor Yellow
Write-Host ""
Write-Host "Or manually from MSYS2 MinGW64 shell:" -ForegroundColor White
Write-Host "  cd /c/dev/myardour/windows-build" -ForegroundColor Yellow
Write-Host "  ./build-all.sh" -ForegroundColor Yellow
Write-Host ""
