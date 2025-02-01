function Compare-Version
{
    param (
        [string]$Version1,
        [string]$Version2
    )

    $Version1 = $Version1.TrimStart('v')
    $Version2 = $Version2.TrimStart('v')

    $v1 = [Version]$Version1
    $v2 = [Version]$Version2

    return [int]($v1.CompareTo($v2))
}

function Invoke-AsAdmin
{
    param (
        [string]$ScriptName
    )

    $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath $ScriptName

    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
}

$targetVersion = "1.9.25200"
$currentVersion = winget --version

if (Compare-Version $currentVersion $targetVersion -lt 0)
{
    Write-Host "Upgrading winget to the latest version..."
    winget install -e --accept-source-agreements --accept-package-agreements Microsoft.AppInstaller
}

# Install JetBrains Nerd Font
Invoke-AsAdmin "Install-JetBrainsMonoNerdFont.ps1"
