@echo off
REM Ardour Windows Build - Launcher Script
REM This batch file launches the build process in MSYS2 MinGW64 shell

setlocal EnableDelayedExpansion

REM Configuration
set "MSYS2_PATH=C:\msys64"
set "SCRIPT_DIR=%~dp0"

REM Parse arguments
set "BUILD_ARGS="
set "SETUP_ONLY=0"

:parse_args
if "%~1"=="" goto :check_msys2
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="--setup" (
    set "SETUP_ONLY=1"
    shift
    goto :parse_args
)
set "BUILD_ARGS=%BUILD_ARGS% %~1"
shift
goto :parse_args

:show_help
echo Ardour Windows Build - Launcher Script
echo.
echo Usage: %~nx0 [options]
echo.
echo Options:
echo   -h, --help      Show this help message
echo   --setup         Run MSYS2 setup only (install/update)
echo   --clean         Clean build
echo   --debug         Build debug configuration
echo   --release       Build release configuration (default)
echo   --skip-deps     Skip dependency installation
echo   --skip-package  Skip packaging step
echo   --build-only    Only rebuild (skip deps, configure, package)
echo.
echo This script will:
echo   1. Check for MSYS2 installation
echo   2. Launch the build in MinGW64 environment
echo.
echo If MSYS2 is not installed, run:
echo   powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-msys2.ps1"
echo.
goto :eof

:check_msys2
REM Check if MSYS2 is installed
if not exist "%MSYS2_PATH%\msys2_shell.cmd" (
    echo [ERROR] MSYS2 not found at %MSYS2_PATH%
    echo.
    echo Please install MSYS2 first:
    echo   Option 1: Run the PowerShell setup script:
    echo     powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-msys2.ps1"
    echo.
    echo   Option 2: Download and install manually from:
    echo     https://www.msys2.org/
    echo.
    pause
    exit /b 1
)

echo [OK] MSYS2 found at %MSYS2_PATH%

REM Handle setup-only mode
if "%SETUP_ONLY%"=="1" (
    echo.
    echo Running MSYS2 setup...
    powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-msys2.ps1"
    goto :eof
)

REM Convert Windows path to MSYS2 path
set "MSYS_SCRIPT_DIR=%SCRIPT_DIR:\=/%"
set "MSYS_SCRIPT_DIR=%MSYS_SCRIPT_DIR:C:=/c%"
set "MSYS_SCRIPT_DIR=%MSYS_SCRIPT_DIR:D:=/d%"
set "MSYS_SCRIPT_DIR=%MSYS_SCRIPT_DIR:E:=/e%"

REM Remove trailing slash if present
if "%MSYS_SCRIPT_DIR:~-1%"=="/" set "MSYS_SCRIPT_DIR=%MSYS_SCRIPT_DIR:~0,-1%"

echo.
echo ========================================
echo   Ardour Windows Build
echo ========================================
echo.
echo Script directory: %SCRIPT_DIR%
echo MSYS2 path: %MSYS_SCRIPT_DIR%
echo Build arguments: %BUILD_ARGS%
echo.

REM Launch MSYS2 MinGW64 shell with build script
echo Launching build in MinGW64 environment...
echo.

"%MSYS2_PATH%\msys2_shell.cmd" -mingw64 -defterm -no-start -here -c "cd '%MSYS_SCRIPT_DIR%' && bash build-all.sh %BUILD_ARGS%"

if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Build failed with error code %ERRORLEVEL%
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo [OK] Build completed successfully!
echo.
echo Output can be found in: %SCRIPT_DIR%..\Export
echo.
pause
