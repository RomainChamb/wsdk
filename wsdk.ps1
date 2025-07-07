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
    Write-Host " wsdk help                    # Show this help message"

}

function Switch-Version {
    param(
        [string]$Tool,
        [string]$Version
    )

    $ToolBase = Join-Path $Base "tools\$Tool"
    $VersionDir = Join-Path $ToolBase "versions"
    $TargetPath = Join-Path $VersionDir "$Tool-$VersionDir"
    $ToolSymlinkPath = Join-Path $CurrentDir $Tool

    if(-Not (Test-Path $TargetPath)) {
        Write-Error "$Tool version $Version not found at $TargetPath"
        return
    }

    if(Test-Path $ToolSymlinkPath) {
        Remove-Item $ToolSymlinkPath
    }

    New-Item -ItemType SymbolicLink -Path $ToolSymlinkPath -Target $TargetPath
    Write-Host "Switched $Tool to version $Version"
}

function Update-Wsdk {
    $RepoZipUrl = "https://github.com/RomainChamb/wsdk/archive/refs/heads/main.zip"
    $TempZip = Join-Path $env:TEMP "wsdk_update.zip"
    $ExtractPath = Join-Path $env:TEMP "wsdk_update"

    try {
        Write-Host "Downloading latest wsdk repository..."
        Invoke-WebRequest -Uri $RepoZipUrl -OutFile $TempZip

        if (Test-Path $ExtractPath) {
            Remove-Item -Recurse -Force $ExtractPath
        }

        Expand-Archive -Path $TempZip -DestinationPath $ExtractPath

        $ExtractedRoot = Join-Path $ExtractPath "wsdk-main"

        Write-Host "Replacing local .wsdk contents..."
        Copy-Item -Path (Join-Path $ExtractedRoot "*") -Destination $Base -Recurse -Force

        Write-Host "Update complete."
    } catch {
        Write-Error "Update failed: $_"
    } finally {
        if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
        if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
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
            Get-ChildItem -Directory $VersionDir | ForEach-Object
            {
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
    "update" {
        Update-Wsdk
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
