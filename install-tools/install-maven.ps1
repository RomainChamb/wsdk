# Define the updated install-maven.ps1 script content
param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

function download_maven_from_central_repository {
    param(
        [string]$Version,
        [string]$ToolDir,
        [string]$ExtractDir
    )

    # Extract maven major version
    $majorVersion = $Version.Split('.')[0]

    # Construct base URL
    $baseUrl = "https://archive.apache.org/dist/maven/maven-$majorVersion/$Version/binaries"
    $fileName = "apache-maven-$Version-bin.zip"
    $downloadUrl = "$baseUrl/$fileName"

    # Create the version directory if it doesn't exist
    if (-Not (Test-Path $ExtractDir)) {
        New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null
        Write-Host "Created directory: $ExtractDir"
    } else {
        Write-Host "Directory already exists: $ExtractDir"
    }

    # Download the file
    $zipPath = Join-Path -Path $ExtractDir -ChildPath $fileName
    Write-Host "Downloading $downloadUrl..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath

    # Temporary extraction folder
    $tempExtractDir = Join-Path -Path $ExtractDir -ChildPath "temp_extract_$Version"
    if (Test-Path $tempExtractDir) {
        Remove-Item $tempExtractDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $tempExtractDir | Out-Null

    # Extract the archive
    Write-Host "Extracting to $ExtractDir..."
    Expand-Archive -Path $zipPath -DestinationPath $tempExtractDir -Force

    # Find the extracted apache-maven-* folder
    $extractedRoot = Get-ChildItem -Path $tempExtractDir | Where-Object { $_.PSIsContainer } | Select-Object -First 1

    if ($extractedRoot) {
        if (-Not (Test-Path $ToolDir)) {
            New-Item -ItemType Directory -Force -Path $ToolDir | Out-Null
            Write-Host "Created directory: $ToolDir"
        }

        Get-ChildItem -Path $extractedRoot.FullName | ForEach-Object {
            Move-Item -Path $_.FullName -Destination $ToolDir -Force
        }
    } else {
        Write-Host "Error: Could not find extracted Maven folder."
    }

    # Cleanup
    Remove-Item $zipPath -Force
    Remove-Item $tempExtractDir -Recurse -Force

    Write-Host "Maven $Version has been downloaded and extracted to '$ToolDir'"
}

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$Base = Join-Path $HomeDir ".wsdk"
$ExtractDir = Join-Path $Base "tools\\maven\\versions"
$ToolDir = Join-Path $Base "tools\\maven\\versions\\$Version"
$CurrentDir = Join-Path $Base "current"
$SymlinkPath = Join-Path $CurrentDir "maven"

download_maven_from_central_repository -Version $Version -ToolDir $ToolDir -ExtractDir $ExtractDir

# Remove existing symlink if it exists
if (Test-Path $SymlinkPath) {
    Remove-Item $SymlinkPath -Recurse -Force
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


