param(
    [Parameter(Mandatory = $true)]
    [string]$Command,
    [string]$Argument
)

$HomeDir = [Environment]::GetFolderPath("UserProfile")
$MavenBase = Join-Path $HomeDir ".wsdk"
$SymlinkPath = Join-Path $MavenBase "current"

function Shwo-Help {
    Write-Host "Usage:"
    Write-Host " wsdk list             # List available Maven versions"
    Write-Host " wsdk use <version>    # Switch to a specific Maven version"
    Write-Host " wsdk help             # Show this help message
}

function Switch-MavenVersion {
    param(
        [string]$Version
    )

    $TargetPath = Join-Path $MavenBase "apache-maven-$Version"

    if(-Not (Test-Path $TargetPath)) {
        Write-Error "Maven version $Version not found ad $TargetPath"
        return
    }

    if(Test-Path $SymlinkPath) {
        Remove-Item $SymlinkPath
    }

    New-Item -ItemType SymbolicLink -Path $SymlinkPath -Target $TargetPath
    Write-Host "Switched Maven to version $Version"
}

switch ($Command.ToLower()) {
    "list" {
        Get-ChildItem -Directory $MavenBase | Where-Object { $_.Name -like "apache-maven-*" } | ForEach-Object
        {
            $isCurrent = (Test-Path $SymlinkPath) -and ((Get-Item $SymlinkPath).Target -eq $_.FullName)
            Write-Host "$($_.Name) $(if ($isCurrent) { '(current)' })"
        }
    }
    "use" {
        if(-not $Argument) {
            Write-Error "Please specify a Maven version. Example: wsdk use 3.9.5"
        } else {
            Switch-MavenVersion -Version $Argument
        }
    }
    "help" {
        Write-Host "Usage:"
        Write-Host "wsdk list # List available Maven versions"
        Write-Host "wsdk use <version> # Switch to a specific Maven version"
    }
    default {
        Write-Host "❓ Unknown command: $Command"
        Write-Host "Usage:"
        Write-Host "wsdk list # List available Maven versions"
        Write-Host "wsdk use <version> # Switch to a specific Maven version"

    }
}
