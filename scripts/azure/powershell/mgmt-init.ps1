[Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidUsingInvokeExpression", "")]
[CmdletBinding()]
[OutputType([System.Object[]])]
param(

    [Switch] $Help
)

Set-StrictMode -Version Latest

$SubscriptionId = "libredevops-sub"
$ShorthandName  = "exm"
$ShorthandEnv   = "poc"
$ShorthandLocation = "uks"

if ($ShorthandLocation = "uks")
{
    $LonghandLocation = "uksouth"
}
elseif ($ShorthandLocation = "euw")
{
    $LonghandLocation = "westeurope"
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

Write-Host "This script is intended to be ran in the Cloud Shell in Azure to setup your pre-requisite items in a fresh tenant" -ForegroundColor Black -BackgroundColor Yellow ; Start-Sleep -Seconds 3

# Set subscription
Set-AzContext -Subscription $SubscriptionId

$spokeSubid=$(Get-AzContext | Select-Object -ExpandProperty Subscription)

# Create Resource Group
$spokeMgmtRgName=$(New-AzResourceGroup `
-Name "rg-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt" `
-Location $LonghandLocation -Force | Select-Object -ExpandProperty ResourceGroupName)

# Create Keyvault

New-AzKeyVault `
-Name "kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01" `
-ResourceGroupName $spokeMgmtRgName `
-Location $LonghandLocation  -ErrorAction SilentlyContinue

$KvOutput=$(Get-AzKeyvault `
-VaultName "kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01" `
-ResourceGroupName $spokeMgmtRgName `
-SubscriptionId $spokeSubid)

$spokeKvId=$($KvOutput | Select-Object -ExpandProperty ResourceId)
$spokeKvName=$($KvOutput | Select-Object -ExpandProperty VaultName)
