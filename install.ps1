# Define paths
$HomeDir = [Environment]::GetFolderPath("UserProfile")
$WsdkDir = Join-Path $HomeDir ".wsdk"
$CurrentDir = Join-Path $WsdkDir "current"
$ZipUrl = "https://github.com/RomainChamb/wsdk/archive/refs/heads/main.zip"
$TempZip = Join-Path $env:TEMP "wsdk-main.zip"
$ExtractPath = Join-Path $env:TEMP "wsdk-main"

# Create required directories
New-Item -ItemType Directory -Force -Path $WsdkDir | Out-Null
New-Item -ItemType Directory -Force -Path $CurrentDir | Out-Null

# Download the latest version of the repo as a zip
Invoke-WebRequest -Uri $ZipUrl -OutFile $TempZip

# Extract the zip
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($TempZip, $env:TEMP)

# Copy contents to .wsdk directory
Copy-Item -Path (Join-Path $ExtractPath "*") -Destination $WsdkDir -Recurse -Force

# Clean up
Remove-Item $TempZip -Force
Remove-Item $ExtractPath -Recurse -Force

# Add .wsdk to system PATH if not already present
$envPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($envPath -notlike "*$WsdkDir*") {
    $newPath = "$envPath;$WsdkDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

# Reload environment variables in current session
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "wsdk installed successfully in $WsdkDir"
Write-Host "You can now run wsdk from this terminal. Restart other terminals to apply changes globally."
