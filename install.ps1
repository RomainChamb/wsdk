param(
    [string]$Tag = "latest"
)

# Define paths
$HomeDir = [Environment]::GetFolderPath("UserProfile")
$WsdkDir = Join-Path $HomeDir ".wsdk"
$CurrentDir = Join-Path $WsdkDir "current"

# Determine tag URL
if ($Tag -eq "latest") {
    $apiUrl = "https://api.github.com/repos/RomainChamb/wsdk/releases/latest"
    $Tag = (Invoke-RestMethod -Uri $apiUrl).tag_name
}

$ZipUrl = "https://github.com/RomainChamb/wsdk/archive/refs/tags/$Tag.zip"
$TempZip = Join-Path $env:TEMP "wsdk-$Tag.zip"

# Create required directories
New-Item -ItemType Directory -Force -Path $WsdkDir | Out-Null
New-Item -ItemType Directory -Force -Path $CurrentDir | Out-Null

# Download the tagged version of the repo
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

# Extract the zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($TempZip, $env:TEMP)

# Copy contents to .wsdk directory
$extractedFolder = Join-Path $env:TEMP "wsdk-$($Tag.TrimStart('v'))"
Copy-Item -Path (Join-Path $extractedFolder "*") -Destination $WsdkDir -Recurse -Force

# Clean up
Remove-Item $TempZip -Force
Remove-Item $extractedFolder -Recurse -Force

# Add .wsdk to system PATH if not already present
$envPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($envPath -notlike "*$WsdkDir*") {
    $newPath = "$envPath;$WsdkDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

# Reload environment variables in current session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User")

# Create VERSiON.txt file
$VersionFile = Join-Path $WsdkDir "VERSION.txt"
Set-Content -Path $VersionFile -Value $Tag


Write-Host "wsdk version $Tag installed successfully in $WsdkDir"
Write-Host "You can now run wsdk from this terminal. Restart other terminals to apply changes globally."
