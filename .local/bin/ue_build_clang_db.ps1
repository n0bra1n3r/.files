#!/usr/bin/env powershell

Write-Host "Unreal Engine Clang Database Generator" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Find .uproject file in current directory
$uprojectFiles = Get-ChildItem -Filter "*.uproject" -File
if ($uprojectFiles.Count -eq 0) {
    Write-Host "ERROR: No .uproject file found in the current directory." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$uprojectFile = $uprojectFiles[0]
$uprojectPath = $uprojectFile.FullName
$uprojectName = $uprojectFile.BaseName
$projectDir = $uprojectFile.DirectoryName

Write-Host "UPROJECT_PATH: $uprojectPath"
Write-Host "UPROJECT_NAME: $uprojectName"

# Extract EngineAssociation from .uproject file
$engineVersion = ""
$uprojectContent = Get-Content $uprojectFile.Name -Raw
if ($uprojectContent -match '"EngineAssociation"\s*:\s*"([^"]*)"') {
    $engineVersion = $matches[1]
}

$ueDir = ""
if ([string]::IsNullOrEmpty($engineVersion)) {
    Write-Host "WARNING: Could not detect engine version from .uproject file" -ForegroundColor Yellow
    $ueDir = Read-Host "Enter Unreal Engine installation path"
    $ueDir = $ueDir.Trim('"')
} else {
    Write-Host "ENGINE_VERSION: $engineVersion"
    
    # Try to find engine path in registry
    try {
        $registryPath = "HKCU:\Software\Epic Games\Unreal Engine\Builds"
        $registryValue = Get-ItemProperty -Path $registryPath -Name $engineVersion -ErrorAction SilentlyContinue
        if ($registryValue) {
            $ueDir = $registryValue.$engineVersion
        }
    } catch {
        # Registry lookup failed, continue without error
    }
    
    if ([string]::IsNullOrEmpty($ueDir)) {
        Write-Host "Could not find engine path in registry for version $engineVersion" -ForegroundColor Yellow
        $ueDir = Read-Host "Enter Unreal Engine installation path"
        $ueDir = $ueDir.Trim('"')
    }
}

Write-Host "UE_DIR: $ueDir"

# Verify the path exists
$buildBatPath = Join-Path $ueDir "Engine\Build\BatchFiles\Build.bat"
if (-not (Test-Path $buildBatPath)) {
    Write-Host "ERROR: Build.bat not found at: $buildBatPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Execute the build command
Write-Host "Generating Clang database..."
$buildArgs = @(
    "-mode=GenerateClangDatabase",
    "-project", "`"$uprojectPath`"",
    "-game",
    "-engine",
    "$($uprojectName)Editor",
    "Win64",
    "Development"
)

& $buildBatPath @buildArgs

# Move compile_commands.json from UE folder to project folder
$ueCompileCommands = Join-Path $ueDir "compile_commands.json"
$projectCompileCommands = Join-Path $projectDir "compile_commands.json"

if (Test-Path $ueCompileCommands) {
    Move-Item $ueCompileCommands $projectCompileCommands -Force
    Write-Host "Moved compile_commands.json to project directory."
} else {
    Write-Host "WARNING: compile_commands.json not found at: $ueCompileCommands" -ForegroundColor Yellow
}
