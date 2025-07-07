# Define the updated install-maven.ps1 script content
param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$Base = Join-Path $HomeDir ".wsdk"
$ToolDir = Join-Path $Base "tools\\maven\\versions\\$Version"
$CurrentDir = Join-Path $Base "current"
$SymlinkPath = Join-Path $CurrentDir "maven"

# Create the version directory if it doesn't exist
if (-Not (Test-Path $ToolDir)) {
    New-Item -ItemType Directory -Force -Path $ToolDir | Out-Null
    Write-Host "Created directory: $ToolDir"
} else {
    Write-Host "Directory already exists: $ToolDir"
}

# Remove existing symlink if it exists
if (Test-Path $SymlinkPath) {
    Remove-Item $SymlinkPath
}


# Create directory junction
cmd /c mklink /J "$SymlinkPath" "$ToolDir"
Write-Host "Maven version $Version installed and linked successfully."

# Set environment variables
$env:MAVEN_HOME = $SymlinkPath
$env:M2_HOME = Join-Path $SymlinkPath "bin"

[Environment]::SetEnvironmentVariable("MAVEN_HOME", $env:MAVEN_HOME, "User")
[Environment]::SetEnvironmentVariable("M2_HOME", $env:M2_HOME, "User")


# Add M2_HOME to PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$env:M2_HOME*") {
    $newPath = "$userPath;$env:M2_HOME"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    $env:Path = $newPath
    Write-Host "M2_HOME added to PATH."
} else {
    Write-Host "M2_HOME already in PATH."
}

# Reload environment variables in current session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "Environment variables set:"
Write-Host "MAVEN_HOME = $env:MAVEN_HOME"
Write-Host "M2_HOME = $env:M2_HOME"


