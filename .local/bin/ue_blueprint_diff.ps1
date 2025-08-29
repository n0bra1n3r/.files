#!/usr/bin/env powershell

param(
    [Parameter(Mandatory=$true, HelpMessage="First file reference in git cat-file format (e.g., feature/branch:Content/Blueprints/MyBlueprint.uasset)")]
    [string]$FileRefA,

    [Parameter(Mandatory=$false, HelpMessage="Second file reference in git cat-file format (e.g., master:Content/Blueprints/MyBlueprint.uasset)")]
    [string]$FileRefB
)

# Function to parse tree-ish:file-path format
function Parse-FileReference($fileRef) {
    if ($fileRef -notmatch '^([^:]+):(.+)$') {
        Write-Host "ERROR: Invalid reference '$fileRef'" -ForegroundColor Red
        Write-Host "Usage examples:" -ForegroundColor Yellow
        Write-Host "  .\script.ps1 'feature/branch:Content/Blueprints/MyBlueprint.uasset' 'main:Content/Blueprints/MyBlueprint.uasset'"
        Write-Host "  .\script.ps1 'HEAD~1:Content/Maps/Level1.umap' 'HEAD:Content/Maps/Level1.umap'"
        Write-Host "  .\script.ps1 'v1.0:Content/Characters/Player.uasset' 'develop:Content/Characters/Player.uasset'"
        Write-Host "  .\script.ps1 'quickfix:Content/Characters/Enemy.uasset'"
        exit 1
    }
    return @{
        TreeIsh = $matches[1]
        FilePath = $matches[2]
    }
}

$refA = Parse-FileReference $FileRefA

if ([string]::IsNullOrWhiteSpace($FileRefB)) {
    $FileRefB = "HEAD:$($refA.FilePath)"
}

$refB = Parse-FileReference $FileRefB

# Use current directory as project root
$projectRoot = Get-Location

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

# Construct path to UnrealEditor.exe
$ueEditorPath = Join-Path $ueDir "Engine\Binaries\Win64\UnrealEditor.exe"
if (!(Test-Path $ueEditorPath)) {
    Write-Host "ERROR: UnrealEditor.exe not found at: $ueEditorPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Create unique temp directories in system temp
$tempSessionId = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
$tempDir = Join-Path $env:TEMP "UE5Diff_$tempSessionId"
$tempDirA = "$tempDir\RefA"
$tempDirB = "$tempDir\RefB"

# Function to extract file from git using cat-file with LFS support
function Extract-FileFromGit($treeIsh, $filePath, $outputPath) {
    Write-Host "`nExtracting $treeIsh`:$filePath..."

    # Create output directory if it doesn't exist
    $outputDir = Split-Path $outputPath -Parent
    if (!(Test-Path $outputDir)) {
        New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
    }

    # Construct the git reference - properly escape special characters
    $gitRef = "${treeIsh}:${filePath}"

    try {
        # Use Start-Process with proper argument escaping for safety
        $errorLogPath = "$env:TEMP\git_error_$tempSessionId.log"

        $processArgs = @{
            FilePath = "git"
            ArgumentList = @(
                "-C", $projectRoot.Path,
                "cat-file", "--filters",
                $gitRef
            )
            NoNewWindow = $true
            Wait = $true
            PassThru = $true
            RedirectStandardOutput = $outputPath
            RedirectStandardError = $errorLogPath
        }

        $process = Start-Process @processArgs

        if ($process.ExitCode -eq 0 -and (Test-Path $outputPath) -and (Get-Item $outputPath).Length -gt 0) {
            $size = (Get-Item $outputPath).Length
            Write-Host "Successfully extracted to: $outputPath ($size bytes)"
            # Clean up error log if successful
            Remove-Item $errorLogPath -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            $errorContent = ""
            if (Test-Path $errorLogPath) {
                $errorContent = Get-Content $errorLogPath -Raw
                Remove-Item $errorLogPath -Force -ErrorAction SilentlyContinue
            }
            Write-Error "Failed to extract file $gitRef. Exit code: $($process.ExitCode). Error: $errorContent"
            return $false
        }
    }
    catch {
        Write-Error "Exception while extracting file $gitRef`: $_"
        return $false
    }
}

# Create temp directories
New-Item -ItemType Directory -Force -Path $tempDirA | Out-Null
New-Item -ItemType Directory -Force -Path $tempDirB | Out-Null

# Extract filename for temp file naming
$fileNameA = Split-Path $refA.FilePath -Leaf
$fileNameB = Split-Path $refB.FilePath -Leaf

# Extract files from both git references
$fileA = "$tempDirA\$fileNameA"
$fileB = "$tempDirB\$fileNameB"

$extractA = Extract-FileFromGit $refA.TreeIsh $refA.FilePath $fileA
$extractB = Extract-FileFromGit $refB.TreeIsh $refB.FilePath $fileB

if (!$extractA -or !$extractB) {
    Write-Error "Failed to extract one or both files. Aborting."

    # Cleanup temp files
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    exit 1
}

Write-Host "`nLaunching diff tool..."
Write-Host "File A: $fileA"
Write-Host "File B: $fileB"

# Launch Unreal Editor with Diff Tool
Start-Process $ueEditorPath -ArgumentList "`"$uprojectPath`"", "-diff", "`"$fileA`"", "`"$fileB`""
