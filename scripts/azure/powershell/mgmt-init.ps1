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

$ResourceGroupName = "rg-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt"
$KeyvaultName = "kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01"
$ServicePrincipalName = "svp-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01"
$ManagedIdentityName = "id-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01"
$PublicSshKeyName = "ssh-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-pub-mgt"
$PrivateSshKeyName = "Ssh${titleConvertedShorthandName}${titleConvertedShorthandLocation}${titleConvertedShorthandEnv}Key"

Write-Host "This script is intended to be ran in the Cloud Shell in Azure to setup your pre-requisite items in a fresh tenant, to setup management resources for terraform.  This is just an example!" -ForegroundColor Black -BackgroundColor Yellow ; Start-Sleep -Seconds 3
Write-Host "Please be aware, if you are running this script to update an existing service principal, it will give it a new secret, DO not run this script if you do not want this" -ForegroundColor Black -BackgroundColor DarkYellow

$LoggedIn = Get-AzContext
if ($null -eq $LoggedIn )
{
    Write-Host "You need to login to Azure to run this script" -ForegroundColor Black -BackgroundColor Red ; exit 1
}
elseif ($null -ne $LoggedIn)
{
    Write-Host "Already logged in, continuing..." -ForegroundColor Black -BackgroundColor Green

}

# Set subscription
Set-AzContext -Subscription $SubscriptionId

$spokeSubid=$(Get-AzContext | Select-Object -ExpandProperty Subscription)
$signedInUserUpn = $(Get-AzADUser -SignedIn | Select-Object -ExpandProperty Id)

# Create Resource Group
$spokeMgmtRgName=$(New-AzResourceGroup `
-Name $ResourceGroupName `
-Location $LonghandLocation -Force | Select-Object -ExpandProperty ResourceGroupName)

Write-Host "Resource Group created!" -ForegroundColor Black -BackgroundColor Green

# Create Keyvault

New-AzKeyVault `
-Name $KeyvaultName `
-ResourceGroupName $spokeMgmtRgName `
-Location $LonghandLocation  -ErrorAction SilentlyContinue

$KvOutput=$(Get-AzKeyvault `
-VaultName $KeyvaultName `
-ResourceGroupName $spokeMgmtRgName `
-SubscriptionId $spokeSubid)

$spokeKvId=$($KvOutput | Select-Object -ExpandProperty ResourceId)

Write-Host "Keyvault Created!" -ForegroundColor Black -BackgroundColor Green

Write-Host "Creating new service principal now, be advised, this script will generate a new client secret if the service principal exists, you have 5 seconds to cancel the script now." -ForegroundColor Black -BackgroundColor Yellow ; Start-Sleep -Seconds 5

$AzSvpExistsOutput = $(Get-AzADServicePrincipal `
-DisplayName $ServicePrincipalName)


if ($null -eq $AzSvpExistsOutput )
{
    Write-Host "Service Principal does not yet exist, creating now" -ForegroundColor Black -BackgroundColor Yellow ;

    $AzSvpExistsOutput = $null
    $AzSvpExistsOutput=$(New-AzADServicePrincipal `
    -DisplayName $ServicePrincipalName)

    $spokeSvpClientId = $null
    $spokeSvpClientSecret = $null
    $spokeSvpId = $null
    $spokeTenantId = $null

    $spokeSvpClientId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppId
    $spokeSvpClientSecret = $AzSvpExistsOutput | Select-Object -ExpandProperty PasswordCredentials | Select-Object -ExpandProperty SecretText
    $spokeSvpId = $AzSvpExistsOutput | Select-Object -ExpandProperty Id
    $spokeTenantId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppOwnerOrganizationId

    Write-Host "New Service Principal Created!" -ForegroundColor Black -BackgroundColor Green
    }
elseif ($null -ne $AzSvpExistsOutput)
{
    # Set conditional output so variables are the same between both conditions
    $AzSvpExistsOutput = $null
    $AzSvpExistsOutput=$(Get-AzADServicePrincipal -DisplayName $ServicePrincipalName)

    $spokeSvpClientSecret=$(Get-AzADServicePrincipal -DisplayName $ServicePrincipalName | New-AzADSpCredential | Select-Object -ExpandProperty SecretText)
    Write-Host "Service Principal exists, fetching output and generating new secret" -ForegroundColor Black -BackgroundColor Green ; `

    $spokeSvpClientId = $null
    $spokeSvpClientSecret = $null
    $spokeSvpId = $null
    $spokeTenantId = $null

    $spokeSvpClientId = $AzSvpExistsOutput | Select-Object -ExpandProperty appId
    $spokeSvpClientSecret = New-AzADSpCredential -ServicePrincipalName ${spokeSvpclientId} | Select-Object -ExpandProperty SecretText
    $spokeSvpId = $AzSvpExistsOutput | Select-Object -ExpandProperty id
    $spokeTenantId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppOwnerOrganizationId

    Write-Host "Existing Service Principal updated!" -ForegroundColor Black -BackgroundColor Green
}
if (-not (Get-Command New-AzUserAssignedIdentity))
{
   Write-Host  "New-AzUserAssignedIdentity doesn't exist, please install it to have this script run correct via pwsh -Command Set-PSRepository -Name PSGallery -InstallationPolicy Trusted  ; pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery ;  Install-Module -Name Az.ManagedServiceIdentity -AllowClobber as admin"  -ForegroundColor Black -BackgroundColor Red ; exit 1
}

if (-not (Get-AzUserAssignedIdentity -ResourceGroup $ResourceGroupName -Name $ManagedIdentityName))
{
    Write-Host "Managed Identity does not exist, creating it" -ForegroundColor Black -BackgroundColor Yellow
    $AzManagedIdOutput = $null
    $AzManagedIdOutput=$(New-AzUserAssignedIdentity `
    -ResourceGroupName $ResourceGroupName `
    -Name $ManagedIdentityName)

    $spokeManagedIdentityId = $null
    $spokeManagedIdentityClientId = $null
    $spokeManagedIdentityPrincipalId = $null

    $spokeManagedIdentityId=$($AzManagedIdOutput | Select-Object -ExpandProperty Id)
    $spokeManagedIdentityClientId=$($AzManagedIdOutput | Select-Object -ExpandProperty ClientId)
    $spokeManagedIdentityPrincipalId=$($AzManagedIdOutput | Select-Object -ExpandProperty PrincipalId)

    Set-AzKeyVaultAccessPolicy `
    -VaultName $KeyvaultName `
    -ResourceGroupName $ResourceGroupName `
    -ServicePrincipalName $spokeManagedIdentityClientId `
    -PermissionsToSecrets get,list,set,recover,backup,restore `
    -PermissionsToCertificates get,list,update,create,import,delete,recover,backup,restore `
    -PermissionsToKeys get,list,update,create,import,delete,recover,backup,restore,decrypt,encrypt,verify,sign
}
else
{
    Write-Host "Managed Identity already exists, Exporting values" -ForegroundColor Black -BackgroundColor Yellow
    $AzManagedIdOutput = $null
    $AzManagedIdOutput=$(Get-AzUserAssignedIdentity `
    -ResourceGroup $ResourceGroupName `
    -Name $ManagedIdentityName)

    $spokeManagedIdentityId = $null
    $spokeManagedIdentityClientId = $null
    $spokeManagedIdentityPrincipalId = $null

    $spokeManagedIdentityId=$($AzManagedIdOutput | Select-Object -ExpandProperty Id)
    $spokeManagedIdentityClientId=$($AzManagedIdOutput | Select-Object -ExpandProperty ClientId)
    $spokeManagedIdentityPrincipalId=$($AzManagedIdOutput | Select-Object -ExpandProperty PrincipalId)

    Set-AzKeyVaultAccessPolicy `
    -VaultName $KeyvaultName `
    -ResourceGroupName $ResourceGroupName `
    -ServicePrincipalName $spokeManagedIdentityClientId `
    -PermissionsToSecrets get,list,set,recover,backup,restore `
    -PermissionsToCertificates get,list,update,create,import,delete,recover,backup,restore `
    -PermissionsToKeys get,list,update,create,import,delete,recover,backup,restore,decrypt,encrypt,verify,sign
}


Write-Host "Managed Identity Created! and given rights to keyvault and subscription!" -ForegroundColor Black -BackgroundColor Green

$PasswordGenerator=$(-join (((48..57)+(65..90)+(97..122)) * 80 | Get-Random -Count 25 | ForEach-Object{[char]$_}))
$spokeAdminSecret = ConvertTo-SecureString "$PasswordGenerator" -AsPlainText -Force

Set-AzKeyVaultSecret `
-VaultName $KeyvaultName `
-Name "Local${titleConvertedShorthandName}Admin${titleConvertedShorthandEnv}Pwd" `
-SecretValue $spokeAdminSecret

Write-Host "Admin Secret made in keyvault" -ForegroundColor Black -BackgroundColor Green

if (Get-Command ssh-keygen -ErrorAction SilentlyContinue)
{
    Write-Host "ssh-keygen exists! Attempting to generate SSH key now" -ForegroundColor Black -BackgroundColor Green

    #Gets current time tag in fractions of seconds to ensure running the same script twice is unlikely to exit with residue fodler

    ssh-keygen -b 4096 -t rsa -f "${lowerConvertedShorthandName}-${lowerConvertedShorthandEnv}-ssh-azureid_rsa.key" -q -N '""'

    $PublicKey = Get-Content "${lowerConvertedShorthandName}-${lowerConvertedShorthandEnv}-ssh-azureid_rsa.key.pub" -Raw
    $RawPrivateKey = Get-Content "${lowerConvertedShorthandName}-${lowerConvertedShorthandEnv}-ssh-azureid_rsa.key" -Raw
    $PrivateKey = ConvertTo-SecureString -String $RawPrivateKey -AsPlainText -Force

    New-AzSshKey `
    -ResourceGroupName $ResourceGroupName `
    -Name $PublicSshKeyName `
    -PublicKey $PublicKey

    Set-AzKeyVaultSecret `
    -VaultName $KeyvaultName `
    -Name $PrivateSshKeyName `
    -SecretValue $PrivateKey

    Remove-Item -Force "${lowerConvertedShorthandName}-${lowerConvertedShorthandEnv}-ssh-azureid_rsa.key.pub"
    Remove-Item -Force "${lowerConvertedShorthandName}-${lowerConvertedShorthandEnv}-ssh-azureid_rsa.key"
}
else
{
    Write-Host "SSH Keygen does not exist, skipping SSH key generation" -ForegroundColor Black -BackgroundColor Yellow
}