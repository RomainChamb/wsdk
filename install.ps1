#Define path

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$WsdkDir = Join-Path $HomeDir ".wsdk"
$CurrentDir = Join-Path $WsdkDir "current"
$BinDir = Join-Path $CurrentDir "bin"
$ScriptUrl = "https://raw.githubusercontent.com/RomainChamb/wsdk/main/wsdk.ps1"
$ScriptPath = Join-Path $WsdkDir "wsdk.ps1"

#Create required directories
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

#Download wsdk.ps1
Invoke-WebRequest -Uri $ScriptUrl -OutFile $ScriptPath

#Set system environment varaibles
[Environment]::SetEnvironmentVariable("M2_HOME", $CurrentDir, "User")
[Environment]::SetEnvironmentVariable("M2", $BinDir, "User")

#Add .wsdk to system PATH if not already present
$envPath = [Environment]::GetEnvironmentVariable("Path", "User")
if($envPath -notLike "*$WsdkDir*") {
    $newPath = "$envPath;$WsdkDir"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

# Reload environment variables in current session
$env:M2_HOME = $CurrentDir
$env:M2 = $BinDir
$env:Path = [Environment]::GetEnvironmentVariable("Path", "User")

Write-Host "wsdk installed successfully in $WsdkDir"
Write-Host "M2_HOME set to $env:M2_HOME"
Write-Host "M2 set to $env:M2"
Write-Host "wsdk.ps1 is now available in your PATH"
Write-Host "You can now run wsdk from this terminal. Restart other terminals to apply changes globally."

