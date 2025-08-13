@echo off
setlocal enabledelayedexpansion

echo Unreal Engine Development Project Builder
echo =====================================
echo.

REM Find .uproject file in current directory
set UPROJECT_PATH=
set UPROJECT_NAME=
for %%f in (*.uproject) do (
    set UPROJECT_PATH=%%~ff
    set UPROJECT_NAME=%%~nf
    set PROJECT_DIR=%%~dpf
    set UPROJECT_FILE=%%f
    goto :found_project
)

echo ERROR: No .uproject file found in the current directory.
pause
exit /b 1

:found_project
echo UPROJECT_PATH: !UPROJECT_PATH!
echo UPROJECT_NAME: !UPROJECT_NAME!

REM Extract EngineAssociation from .uproject file
set ENGINE_VERSION=
for /f "tokens=2 delims=:" %%a in ('findstr "EngineAssociation" "!UPROJECT_FILE!"') do (
    set ENGINE_VERSION=%%a
    REM Remove quotes, spaces, and comma
    set ENGINE_VERSION=!ENGINE_VERSION:"=!
    set ENGINE_VERSION=!ENGINE_VERSION: =!
    set ENGINE_VERSION=!ENGINE_VERSION:,=!
)

set UE_DIR=
if "!ENGINE_VERSION!"=="" (
    echo WARNING: Could not detect engine version from .uproject file
    set /p UE_DIR="Enter Unreal Engine installation path: "
    set UE_DIR=!UE_DIR:"=!
) else (
    echo ENGINE_VERSION: !ENGINE_VERSION!
    
    REM Try to find engine path in registry
    for /f "skip=2 tokens=3*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Epic Games\Unreal Engine\Builds" /v "!ENGINE_VERSION!" 2^>nul') do (
        set UE_DIR=%%a %%b
        REM Remove trailing spaces
        for /l %%i in (1,1,100) do if "!UE_DIR:~-1!"==" " set UE_DIR=!UE_DIR:~0,-1!
    )
    
    if "!UE_DIR!"=="" (
        echo Could not find engine path in registry for version !ENGINE_VERSION!
        set /p UE_DIR="Enter Unreal Engine installation path: "
        set UE_DIR=!UE_DIR:"=!
    )
)

REM Echo UE_DIR outside of the if block to verify it's set correctly
echo UE_DIR: !UE_DIR!

REM Verify the path exists
if not exist "!UE_DIR!\Engine\Build\BatchFiles\Build.bat" (
    echo ERROR: Build.bat not found at: !UE_DIR!\Engine\Build\BatchFiles\Build.bat
    pause
    exit /b 1
)

echo.

REM Execute the build command
echo Building project...
call "!UE_DIR!\Engine\Build\BatchFiles\Build.bat" "!UPROJECT_PATH!" -game -engine !UPROJECT_NAME!Editor Win64 Development

