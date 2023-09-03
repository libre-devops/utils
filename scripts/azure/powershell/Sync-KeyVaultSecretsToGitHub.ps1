#!/usr/bin/env pwsh

    [Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidUsingInvokeExpression","")]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
param(

    [switch]$Help
)

Set-StrictMode -Version Latest

########### Edit the below variables to use script ############

$SubscriptionId = "sub-ldo-uks-prd-mgmt-01"
$ShorthandName = "ldo"
$ShorthandLocation = "uks"
$ShorthandEnv = "prd"
$GithubOrgName = "libre-devops"


########## Do not edit anything below unless you know what you are doing ############

if ($ShorthandLocation = "uks")
{
    $LonghandLocation = "uksouth"
}
elseif ($ShorthandLocation = "ukw")
{
    $LonghandLocation = "ukwest"
}
elseif ($ShorthandLocation = "euw")
{
    $LonghandLocation = "westeurope"
}
elseif ($ShorthandLocation = "eun")
{
    $LonghandLocation = "northeurope"
}
elseif ($ShorthandLocation = "use")
{
    $LonghandLocation = "eastus"
}
elseif ($ShorthandLocation = "use2")
{
    $LonghandLocation = "eastus2"
}


$lowerConvertedShorthandName = $ShorthandName.ToLower()
$lowerConvertedShorthandEnv = $ShorthandEnv.ToLower()
$lowerConvertedShorthandLocation = $ShorthandLocation.ToLower()

$upperConvertedShorthandName = $ShorthandName.ToUpper()
$upperConvertedShorthandEnv = $ShorthandEnv.ToUpper()
$upperConvertedShorthandLocation = $ShorthandLocation.ToUpper()

$TextInfo = (Get-Culture).TextInfo
$titleConvertedShorthandName = $TextInfo.ToTitleCase($ShorthandName)
$titleConvertedShorthandEnv = $TextInfo.ToTitleCase($ShorthandEnv)
$titleConvertedShorthandLocation = $TextInfo.ToTitleCase($ShorthandLocation)

$KeyvaultName = "kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgmt-01"

# Check if Azure CLI is installed
if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
    Write-Error "Azure CLI (az) is not installed or not in the PATH. Please install it and retry."
    exit
}

# Check if GitHub CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in the PATH. Please install it and retry."
    exit
}

# Checks for logged in data, if the API responds with Null, you aren't logged in
$LoggedIn = Get-AzContext
if ($null -eq $LoggedIn)
{
  Write-Host "You need to login to Azure to run this script" -ForegroundColor Black -BackgroundColor Red; exit 1
}
elseif ($null -ne $LoggedIn)
{
  Write-Host "Already logged in, continuing..." -ForegroundColor Black -BackgroundColor Green
}

# Set subscription
Set-AzContext -Subscription $SubscriptionId

# Retrieve all secrets from the Key Vault
$secrets = Get-AzKeyVaultSecret -VaultName $keyVaultName

foreach ($secret in $secrets) {
    $secretName = $secret.Name
    # Retrieve the secret's value as a SecureString
    $secretSecureValue = (Get-AzKeyVaultSecret -VaultName $KeyvaultName -Name $secretName).SecretValue

    # Convert the SecureString to plain text
    $secretValue = [System.Net.NetworkCredential]::new("", $secretSecureValue).Password

    # Add/Update the secret to GitHub organization
    # Note: This will prompt for confirmation unless `--confirm` is added to the command
    Write-Output $secretValue | gh secret set $secretName --org=$GithubOrgName --visibility=all
}

Write-Output "All secrets transferred to GitHub organization."
