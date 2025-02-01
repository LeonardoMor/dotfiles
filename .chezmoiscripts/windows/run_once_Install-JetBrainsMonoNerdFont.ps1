$FontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip"
$TempFolder = [System.IO.Path]::GetTempPath()
$FontZip = Join-Path -Path $TempFolder -ChildPath "JetBrainsMono.zip"
$ExtractFolder = Join-Path -Path $TempFolder -ChildPath "JetBrainsMonoFont"
$FontsFolder = "$env:SystemRoot\Fonts"
$RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

function Show-Help
{
    Write-Output @"
Install-JetBrainsMonoNerdFont.ps1 - Install the JetBrains Mono Nerd Font on Windows.

Usage:
    Run this script to download, extract, and install the JetBrains Mono Nerd Font.

Options:
    -h  Display this help message and exit.

This script will:
    1. Download the JetBrains Mono Nerd Font ZIP file.
    2. Extract the font files to a temporary directory.
    3. Install the font files to the Windows Fonts folder.
    4. Register the fonts in the Windows registry.
    5. Clean up temporary files.

Make sure to run the script with administrator privileges.
"@
    exit
}

if ($args -contains "-h")
{
    Show-Help
}

function Test-FontInstalled
{
    param (
        [string]$FontName
    )

    try
    {
        $InstalledFonts = Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
        return $InstalledFonts.PSObject.Properties.Name -contains "$FontName (TrueType)"
    } catch
    {
        return $false
    }
}

function Restart-AsAdmin
{
    param (
        [string]$ScriptPath
    )

    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`"" -Verb RunAs
}

# Check if running as administrator
function Test-IsAdmin
{
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

$FontToCheck = "JetBrainsMonoNerdFontMono-Regular"

if (Test-FontInstalled -FontName $FontToCheck)
{
    Write-Output "JetBrains Mono Nerd Font is already installed. Exiting."
    exit
}

# If not installed and not running as admin, restart with elevation
if (-not (Test-IsAdmin))
{
    Write-Output "This script requires administrator privileges to install fonts. Requesting elevation..."
    Restart-AsAdmin -ScriptPath $MyInvocation.MyCommand.Path
    exit
}

# Step 1: Download the font ZIP file
Write-Output "Downloading JetBrains Mono Nerd Font..."
Invoke-WebRequest -Uri $FontUrl -OutFile $FontZip -UseBasicParsing
Write-Output "Font ZIP downloaded to: $FontZip"

# Step 2: Extract the ZIP file
Write-Output "Extracting font files..."
Expand-Archive -Path $FontZip -DestinationPath $ExtractFolder -Force
Write-Output "Fonts extracted to: $ExtractFolder"

# Step 3: Install fonts
Write-Output "Installing fonts..."
$FontFiles = Get-ChildItem -Path $ExtractFolder -Recurse -Include "*.ttf", "*.otf"

foreach ($FontFile in $FontFiles)
{
    # Copy font to the Fonts folder
    Write-Output "Installing font: $($FontFile.Name)"
    Copy-Item -Path $FontFile.FullName -Destination $FontsFolder -Force

    # Register the font in the registry
    $FontName = $FontFile.Name
    $FontRegistryValue = "$($FontFile.BaseName) (TrueType)"
    Set-ItemProperty -Path $RegistryPath -Name $FontRegistryValue -Value $FontName
}

Write-Output "Fonts installed successfully."

# Step 4: Clean up
Write-Output "Cleaning up temporary files..."
Remove-Item -Path $FontZip -Force
Remove-Item -Path $ExtractFolder -Recurse -Force
Write-Output "Temporary files removed."

Write-Output "JetBrains Mono Nerd Font installation complete!"
