$TestCommands = @(
'Get-AzContext'
'New-AzUserAssignedIdentity'
)

foreach ($command in $TestCommands)
{
    # Sets up command testing as Az modules seem to be inconsitently installed
    if (-not (Get-Command $command))
    {
        Write-Host  "${command} doesn't exist, it requires to be installed for this script to continue, try - Install-Module -Name Az.Accounts -AllowClobber or pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery or something similar.  - Exit Code - AZ_CMDS_NOT_INSTALLED"  -ForegroundColor Black -BackgroundColor Yellow ; exit 1
    }
    else
    {
        Write-Host "${command} is installed! Continuing" -ForegroundColor Black -BackgroundColor Green
    }
}

