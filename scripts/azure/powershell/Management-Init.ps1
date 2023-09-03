#!/usr/bin/env pwsh

    [Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidUsingInvokeExpression","")]
    [CmdletBinding()]
    [OutputType([System.Object[]])]
param(

    [switch]$Help
)

Write-Host "This script is intended to be ran in a PowerShell environment to setup your pre-requisite items in a fresh tenant, to setup management resources for terraform. You will need Owner in Tenant Root Group (or similar), Global Adminstrator in Microsoft Entra for ID, Key Vault Administrator to manage Key Vault and Storage Blob Data Owner for Storage account management.  This is just an example to get going, please review any code before you run it!" -ForegroundColor Black -BackgroundColor Yellow; Start-Sleep -Seconds 3

Set-StrictMode -Version Latest

########### Edit the below variables to use script ############

$SubscriptionId = "sub-ldo-uks-prd-mgmt-01"
$ShorthandName = "ldo"
$ShorthandLocation = "uks"
$ShorthandEnv = "prd"

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

$ResourceGroupName = "rg-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgmt"
$KeyvaultName = "kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgmt-01"
$ServicePrincipalName = "svp-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgmt-01"
$ManagedIdentityName = "id-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgmt-01"
$PublicSshKeyName = "ssh-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-pub-mgmt"
$PrivateSshKeyName = "Ssh${titleConvertedShorthandName}${titleConvertedShorthandLocation}${titleConvertedShorthandEnv}Key"
$StorageAccountName = "sa${lowerConvertedShorthandName}${lowerConvertedShorthandLocation}${lowerConvertedShorthandEnv}mgmt01"
$BlobContainerName = "blob${lowerConvertedShorthandName}${lowerConvertedShorthandLocation}${lowerConvertedShorthandEnv}mgmt01"

$TestCommands = @(
'Get-AzContext',
'Set-AzContext',
'New-AzResourceGroup',
'New-AzKeyVault',
'Get-AzKeyvault',
'Set-AzKeyVaultAccessPolicy',
'Set-AzKeyVaultSecret',
'Get-AzADUser',
'Get-AzADServicePrincipal',
'New-AzADServicePrincipal',
'Get-AzUserAssignedIdentity',
'New-AzSshKey',
'New-AzStorageAccount',
'New-AzStorageContainer'
)

foreach ($command in $TestCommands)
{
    # Sets up command testing as Az modules seem to be inconsitently installed
    if (-not (Get-Command $command))
    {
        Write-Host "${command} doesn't exist, it requires to be installed for this script to continue, try - Install-Module -Name Az.Accounts -AllowClobber or pwsh -Command Install-Module -Name Az -Force -AllowClobber -Scope AllUsers -Repository PSGallery or something similar.  - Exit Code - AZ_CMDS_NOT_INSTALLED" -ForegroundColor Black -BackgroundColor Yellow; exit 1
    }
}

# Ensure you're logged in
$LoggedIn = Get-AzContext
if ($null -eq $LoggedIn) {
    Write-Host "You need to login to Azure to run this script" -ForegroundColor Black -BackgroundColor Red
    exit 1
} else {
    Write-Host "Already logged in, continuing..." -ForegroundColor Black -BackgroundColor Green

    # Get current user's Object ID from the context
    $currentUserObjectId = $(Get-AzADUser).Id

    # Fetch RBAC assignments for the current user in the current subscription
    $roleAssignments = Get-AzRoleAssignment -ObjectId $currentUserObjectId

    # List of roles to check for
    $requiredRoles = @("Owner", "Key Vault Administrator", "Storage Blob Data Owner")

    # Check if the user has the required roles
    $missingRoles = @($requiredRoles | Where-Object { $_ -notin $roleAssignments.RoleDefinitionName })

    # Display or throw error for missing roles
    if ($missingRoles.Count -gt 0) {
        $errorMessage = "The user lacks the following roles in the current subscription: $($missingRoles -join ', ')"
        Write-Error $errorMessage
    } else {
        Write-Host "The user has all required AzureRm RBAC roles in the current subscription to run this script." -ForegroundColor Green
    }
}


if (-not ($ShorthandName.Length -le 5 -and $ShorthandName.Length -ge 1))
{
    Write-Host "You can't have a shorthand greater than 5, edit the variables and retry" -ForegroundColor Black -BackgroundColor Red; exit 1
}
else
{
    Write-Host "${lowerConvertedShorthandName} shorthand name is less than 5 and greater than 1, thus is permissible, continuing" -ForegroundColor Black -BackgroundColor Green
}

# Set subscription
Set-AzContext -Subscription $SubscriptionId

$SubId = $(Get-AzContext | Select-Object -ExpandProperty Subscription)
$spokeSubId = ConvertTo-SecureString "$SubId" -AsPlainText -Force

$signedInUserUpn = $(Get-AzADUser -SignedIn | Select-Object -ExpandProperty Id)

# Create Resource Group
$spokeMgmtRgName = $(New-AzResourceGroup `
     -Name $ResourceGroupName `
     -Location $LonghandLocation -Force | Select-Object -ExpandProperty ResourceGroupName)

Write-Host "Resource Group created!" -ForegroundColor Black -BackgroundColor Green

# Create Keyvault
$KeyvaultExists = $(Get-AzKeyVault -VaultName $KeyvaultName)

if ($null -eq $KeyvaultExists)
{
    Write-Host "Keyvault doesn't exist, creating it" -ForegroundColor Black -BackgroundColor Yellow

    New-AzKeyVault `
     -Name $KeyvaultName `
     -ResourceGroupName $spokeMgmtRgName `
     -Location $LonghandLocation `
     -EnableRbacAuthorization
}
elseif ($null -ne $KeyvaultExists)
{
    Write-Host "Keyvault already exists, fetching info" -ForegroundColor Black -BackgroundColor Yellow
}

$KvOutput = $(Get-AzKeyVault -VaultName $KeyvaultName)

$spokeKvId = $($KvOutput | Select-Object -ExpandProperty ResourceId)
$spokeKvName = ConvertTo-SecureString "$KeyvaultName" -AsPlainText -Force

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeKvname" `
   -SecretValue $spokeKvName

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSubId" `
   -SecretValue $spokeSubId

Write-Host "Keyvault Setup Complete" -ForegroundColor Black -BackgroundColor Green

Write-Host "Creating new service principal now, be advised, this script will generate a new client secret if the service principal exists, you have 5 seconds to cancel the script now." -ForegroundColor Black -BackgroundColor Yellow; Start-Sleep -Seconds 5

$SubId = $(Get-AzSubscription -SubscriptionName $SubscriptionId | Select-Object -ExpandProperty SubscriptionId)

$AzSvpExistsOutput = $(Get-AzADServicePrincipal `
     -DisplayName $ServicePrincipalName)


if ($null -eq $AzSvpExistsOutput)
{
    Write-Host "Service Principal does not yet exist, creating now" -ForegroundColor Black -BackgroundColor Yellow;

    $AzSvpExistsOutput = $null
    $AzSvpExistsOutput = $(New-AzADServicePrincipal `
       -DisplayName $ServicePrincipalName)

    $spokeSvpClientId = $null
    $spokeSvpId = $null
    $spokeTenantId = $null

    $SvpClientId = $null
    $SvpId = $null
    $SvpTenantId = $null

    $SvpClientId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppId
    $SvpClientSecret = $AzSvpExistsOutput | Select-Object -ExpandProperty PasswordCredentials | Select-Object -First 1 | Select-Object -ExpandProperty SecretText
    $SvpId = $AzSvpExistsOutput | Select-Object -ExpandProperty Id
    $SvpTenantId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppOwnerOrganizationId

    $spokeSvpClientId = ConvertTo-SecureString "$SvpClientId" -AsPlainText -Force
    $spokeSvpClientSecret = ConvertTo-SecureString "$SvpClientSecret" -AsPlainText -Force
    $spokeSvpId = ConvertTo-SecureString "$SvpId" -AsPlainText -Force
    $spokeTenantId = ConvertTo-SecureString "$SvpTenantId" -AsPlainText -Force

    Write-Host "New Service Principal Created!" -ForegroundColor Black -BackgroundColor Green
}
elseif ($null -ne $AzSvpExistsOutput)
{
    # Set conditional output so variables are the same between both conditions
    $AzSvpExistsOutput = $null
    $AzSvpExistsOutput = $(Get-AzADServicePrincipal -DisplayName $ServicePrincipalName)

    Write-Host "Service Principal exists, fetching output and generating new secret" -ForegroundColor Black -BackgroundColor Green; `

  $spokeSvpClientId = $null
    $spokeSvpId = $null
    $spokeTenantId = $null

    $SvpClientId = $null
    $SvpId = $null
    $SvpTenantId = $null

    $SvpClientId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppId
    $SvpClientSecret = $AzSvpExistsOutput | New-AzADSpCredential | Select-Object -ExpandProperty SecretText
    $SvpId = $AzSvpExistsOutput | Select-Object -ExpandProperty Id
    $SvpTenantId = $AzSvpExistsOutput | Select-Object -ExpandProperty AppOwnerOrganizationId

    $spokeSvpClientId = ConvertTo-SecureString "$SvpClientId" -AsPlainText -Force
    $spokeSvpClientSecret = ConvertTo-SecureString "$SvpClientSecret" -AsPlainText -Force
    $spokeSvpId = ConvertTo-SecureString "$SvpId" -AsPlainText -Force
    $spokeTenantId = ConvertTo-SecureString "$SvpTenantId" -AsPlainText -Force

    Write-Host "Existing Service Principal updated!" -ForegroundColor Black -BackgroundColor Green
}

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSvpClientId" `
   -SecretValue $spokeSvpClientId

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSvpObjectId" `
   -SecretValue $spokeSvpId

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSvpClientSecret" `
   -SecretValue $spokeSvpClientSecret

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeTenantId" `
   -SecretValue $spokeTenantId

$SvpRoleAssignmentExists = $(Get-AzRoleAssignment -Scope "/subscriptions/${SubId}" | Where-Object { $_.RoleDefinitionName -eq 'Owner' } | Select-Object -Property DisplayName | Where-Object { $_.DisplayName -eq $ServicePrincipalName })

if ($null -ne $SvpRoleAssignmentExists)
{
    Write-Host "Service Principal Owner Role exists, skipping" -ForegroundColor Black -BackgroundColor Yellow

}
elseif ($null -eq $SvpRoleAssignmentExists)
{
    $requiredRoles = @("Owner", "Key Vault Administrator", "Storage Blob Data Owner")

    foreach ($role in $requiredRoles) {
        Write-Host "Svp $role Role does not exist, creating now" -ForegroundColor Black -BackgroundColor Yellow

        New-AzRoleAssignment `
         -ApplicationId $SvpClientId `
         -RoleDefinitionName $role `
         -Scope "/subscriptions/$SubId"
    }

    Write-Host "Owner Role Assigned to Svp" -ForegroundColor Black -BackgroundColor Green
}

if (-not (Get-AzUserAssignedIdentity -ResourceGroup $ResourceGroupName -Name $ManagedIdentityName -ErrorAction SilentlyContinue))
{
    Write-Host "Managed Identity does not exist, creating it" -ForegroundColor Black -BackgroundColor Yellow
    $AzManagedIdOutput = $null
    $AzManagedIdOutput = $(New-AzUserAssignedIdentity `
       -ResourceGroupName $ResourceGroupName `
       -Location $LonghandLocation `
       -Name $ManagedIdentityName)

    Write-Host "Managed Identity Created, Sleeping 30s while we await API catching up" -ForegroundColor Black -BackgroundColor Yellow; Start-Sleep -Seconds 30

    $spokeManagedIdentityId = $null
    $spokeManagedIdentityClientId = $null
    $spokeManagedIdentityPrincipalId = $null

    $SpokeMiId = $($AzManagedIdOutput | Select-Object -ExpandProperty Id)
    $SpokeMiClientId = $(Get-AzUserAssignedIdentity -ResourceGroup $ResourceGroupName -Name $ManagedIdentityName | Select-Object -ExpandProperty ClientId)
    $spokeManagedIdentityPrincipalId = $($AzManagedIdOutput | Select-Object -ExpandProperty PrincipalId)

}
else
{
    Write-Host "Managed Identity already exists, Exporting values" -ForegroundColor Black -BackgroundColor Yellow
    $AzManagedIdOutput = $null
    $AzManagedIdOutput = $(Get-AzUserAssignedIdentity `
       -ResourceGroup $ResourceGroupName `
       -Name $ManagedIdentityName)

    $spokeManagedIdentityId = $null
    $spokeManagedIdentityClientId = $null
    $spokeManagedIdentityPrincipalId = $null

    $SpokeMiId = $($AzManagedIdOutput | Select-Object -ExpandProperty Id)
    $SpokeMiClientId = $(Get-AzUserAssignedIdentity -ResourceGroup $ResourceGroupName -Name $ManagedIdentityName | Select-Object -ExpandProperty ClientId)
    $spokeManagedIdentityPrincipalId = $($AzManagedIdOutput | Select-Object -ExpandProperty PrincipalId)

}

$spokeManagedIdentityClientId = ConvertTo-SecureString "$SpokeMiClientId" -AsPlainText -Force

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeManagedIdentityClientId" `
   -SecretValue $spokeManagedIdentityClientId

Write-Host "Managed Identity Created! and given rights to keyvault and subscription!" -ForegroundColor Black -BackgroundColor Green

$MiRoleAssignmentExists = $(Get-AzRoleAssignment -Scope "/subscriptions/$SubId" | Where-Object { $_.RoleDefinitionName  -eq 'Owner' } | Select-Object -Property DisplayName | Where-Object { $_.DisplayName -eq $ManagedIdentityName})


if ($null -ne $MiRoleAssignmentExists)
{
    Write-Host "Managed Identity Owner Role exists already, skipping" -ForegroundColor Black -BackgroundColor Yellow

}
elseif ($null -eq $MiRoleAssignmentExists)
{
    $requiredRoles = @("Owner", "Key Vault Administrator", "Storage Blob Data Owner")

    foreach ($role in $requiredRoles) {
        Write-Host "Managed Identity $role Role does not exist, creating now" -ForegroundColor Black -BackgroundColor Yellow

        New-AzRoleAssignment `
     -ApplicationId $SpokeMiClientId `
     -RoleDefinitionName $role `
     -Scope "/subscriptions/$SubId"
    }

    Write-Host "Managed Identity Role Assignment Done!" -ForegroundColor Black -BackgroundColor Green
}

$PasswordGenerator = $(-join (((48..57) + (65..90) + (97..122)) * 80 | Get-Random -Count 25 | ForEach-Object { [char]$_ }))
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

# Creates storage account and blob container for terraform
# Ensure you are authenticated with Azure AD using Connect-AzAccount or equivalent before running this script.
if (-not (Get-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue)) {
    Write-Host "Storage account doesn't exist, creating it" -ForegroundColor Black -BackgroundColor Yellow
    $StorageAccountOutput = $null

    $StorageAccountOutput = New-AzStorageAccount `
       -ResourceGroupName $ResourceGroupName `
       -AccountName $StorageAccountName `
       -Location $LonghandLocation `
       -AllowSharedKeyAccess $false `
       -AllowBlobPublicAccess $false `
       -AllowCrossTenantReplication $false `
       -SkuName "Standard_LRS" `
       -AccessTier "Hot"

    # Get a storage context using Azure AD authentication
    $context = New-AzStorageContext -StorageAccountName $StorageAccountName -UseConnectedAccount

    if (-not (Get-AzStorageContainer -Name $BlobContainerName -Context $context -ErrorAction SilentlyContinue)) {
        Write-Host "Storage Container doesn't exist" -ForegroundColor Black -BackgroundColor Yellow
        $BlobContainerOutput = $null
        $BlobContainerOutput = New-AzStorageContainer -Name $BlobContainerName -Permission "off" -Context $context
    }
    else {
        Write-Host "Storage Container Created!" -ForegroundColor Black -BackgroundColor Green
        $BlobContainerOutput = $null
        $BlobContainerOutput = Get-AzStorageContainer -Name $BlobContainerName -Context $context
    }

    Write-Host "New Storage Account and Blob Created" -ForegroundColor Black -BackgroundColor Green
}
else {
    Write-Host "Storage account already exists. Skipping creation." -ForegroundColor Black -BackgroundColor Green
}


$SaRgName = $($StorageAccountOutput | Select-Object -ExpandProperty ResourceGroupName)
$StorageKey1 = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName | Select-Object -ExpandProperty Value | Select-Object -First 1)
$StorageKey2 = $(Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -AccountName $StorageAccountName | Select-Object -ExpandProperty Value | Select-Object -Last 1)

$spokeSaId = $($StorageAccountOutput | Select-Object -ExpandProperty Id)
$spokeSaRgName = ConvertTo-SecureString "$SaRgName" -AsPlainText -Force
$spokeSaName = ConvertTo-SecureString "$StorageAccountName" -AsPlainText -Force
$spokeSaPrimaryKey = ConvertTo-SecureString "$StorageKey1" -AsPlainText -Force
$spokeSaSecondarykey = ConvertTo-SecureString "$StorageKey2" -AsPlainText -Force

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSaRgName" `
   -SecretValue $spokeSaRgName

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSaName" `
   -SecretValue $spokeSaName

$KeyExpiryDate = (Get-Date).AddMonths(3).ToUniversalTime()
Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSaPrimaryKey" `
   -SecretValue $spokeSaPrimaryKey `
   -Expires $KeyExpiryDate

Set-AzKeyVaultSecret `
   -VaultName $KeyvaultName `
   -Name "SpokeSaSecondaryKey" `
   -SecretValue $spokeSaSecondarykey

Write-Host "Various Keyvault secrets have been set!" -ForegroundColor Black -BackgroundColor Green
