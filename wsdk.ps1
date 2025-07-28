param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string]$Tool,
    [string]$Version
)

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$Base = Join-Path $HomeDir ".wsdk"
$CurrentDir = Join-Path $Base "current"

function Show-Help {
    Write-Host "Usage:"
    Write-Host " wsdk list <tool>             # List available versions for a tool (e.g, maven, java, node)"
    Write-Host " wsdk use <tool> <version>    # Switch to a specific version of a tool"
    Write-Host " wsdk update                  # Update the entire wsdk from github"
    Write-Host " version                      # Show the currently installed wsdk version"
    Write-Host " wsdk help                    # Show this help message"

}

function Switch-Version {
    param(
        [string]$Tool,
        [string]$Version
    )

    $ToolBase = Join-Path $Base "tools\$Tool"
    $VersionDir = Join-Path $ToolBase "versions"
    $TargetPath = Join-Path $VersionDir $Version
    $ToolSymlinkPath = Join-Path $CurrentDir $Tool

    if(-Not (Test-Path $TargetPath)) {
        Write-Error "$Tool version $Version not found at $TargetPath"
        return
    }

    if(Test-Path $ToolSymlinkPath) {
        Remove-Item $ToolSymlinkPath -Recurse -Force
    }

    cmd /c mklink /J "$ToolSymlinkPath" "$TargetPath"
    Write-Host "Switched $Tool to version $Version"
}


function Update-Wsdk {
    param(
        [string]$Tag = "latest"
    )

    $Base = Join-Path ([Environment]::GetFolderPath("UserProfile")) ".wsdk"
    $TempZip = Join-Path $env:TEMP "wsdk_update.zip"
    $ExtractPath = Join-Path $env:TEMP "wsdk_update"

    try {
        if ($Tag -eq "latest") {
            $apiUrl = "https://api.github.com/repos/RomainChamb/wsdk/releases/latest"
            $Tag = (Invoke-RestMethod -Uri $apiUrl).tag_name
        }

        $RepoZipUrl = "https://github.com/RomainChamb/wsdk/archive/refs/tags/$Tag.zip"
        Write-Host "Downloading wsdk version $Tag..."
        Invoke-WebRequest -Uri $RepoZipUrl -OutFile $TempZip

        if (Test-Path $ExtractPath) {
            Remove-Item -Recurse -Force $ExtractPath
        }

        Expand-Archive -Path $TempZip -DestinationPath $ExtractPath

        $ExtractedRoot = Join-Path $ExtractPath "wsdk-$($Tag.TrimStart('v'))"

        Write-Host "Replacing local .wsdk contents..."
        Copy-Item -Path (Join-Path $ExtractedRoot "*") -Destination $Base -Recurse -Force

        # Update VERSION.txt file
        $VersionFile = Join-Path $Base "VERSION.txt"
        Set-Content -Path $VersionFile -Value $Tag

        Write-Host "Update to version $Tag complete."
    } catch {
        Write-Error "Update failed: $_"
    } finally {
        if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
        if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
    }
}

function Version {
    $VersionFile = Join-Path $Base "VERSION.txt"
    if (Test-Path $VersionFile) {
        $installedVersion = Get-Content $VersionFile
        Write-Host "wsdk version: $installedVersion"
    } else {
        Write-Host "wsdk version information not found."
    }
}

switch ($Command.ToLower()) {
    "list" {
        if(-not $Tool) {
            Write-Error "Please specify a tool. Example: wsdk list maven"
        } else {
            $ToolBase = Join-Path $Base "tools\$Tool"
            $VersionDir = Join-Path $ToolBase "versions"
            $ToolSymlinkPath = Join-Path $CurrentDir $Tool

            if(-Not (Test-Path $VersionDir)) {
                Write-Host "No versions found for $Tool"
                return
            }
            Get-ChildItem -Directory $VersionDir | ForEach-Object {
                $isCurrent = (Test-Path $ToolSymlinkPath) -and ((Get-Item $ToolSymlinkPath).Target -eq $_.FullName)
                Write-Host "$($_.Name) $(if ($isCurrent) { '(current)' })"
            }
        }
    }
    "use" {
        if(-not $Tool -or -not $Version) {
            Write-Error "Please specify a tool and version. Example: wsdk use maven 3.9.5"
        } else {
            Switch-Version -Tool $Tool -Version $Version
        }
    }
    "install" {
        if (-not $Tool -or -not $Version) {
            Write-Error "Please specify a tool and version. Example: wsdk install maven 3.9.5"
        } else {
            $InstallScript = Join-Path $Base "install-tools\\install-$Tool.ps1"
            if (Test-Path $InstallScript) {
                & $InstallScript -Version $Version
            } else {
                Write-Error "Installer for '$Tool' not found at $InstallScript"
            }
        }
    }
    "update" {
        Update-Wsdk
    }
    "version" {
        Version
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
