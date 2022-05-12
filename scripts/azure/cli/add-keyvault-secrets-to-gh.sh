#!/usr/bin/env bash

set -xe

SUBSCRIPTION_ID="libredevops-devtest-sub"
SHORTHAND_NAME="ldo"
SHORTHAND_ENV="dev"
SHORTHAND_LOCATION="euw"
GITHUB_ORG="libre-devops"
GITHUB_REPO="azure-terraform-gh-action"

print_success() {
    lightcyan='\033[1;36m'
    nocolor='\033[0m'
    echo -e "${lightcyan}$1${nocolor}"
}

print_error() {
    lightred='\033[1;31m'
    nocolor='\033[0m'
    echo -e "${lightred}$1${nocolor}"
}

print_alert() {
    yellow='\033[1;33m'
    nocolor='\033[0m'
    echo -e "${yellow}$1${nocolor}"
}

title_case_convert() {
    sed 's/.*/\L&/; s/[a-z]*/\u&/g' <<<"$1"
}

upper_case_convert() {
    sed -e 's/\(.*\)/\U\1/' <<< "$1"
}

lower_case_convert() {
    sed -e 's/\(.*\)/\L\1/' <<< "$1"
}

lowerConvertedShorthandName="$(lower_case_convert $SHORTHAND_NAME)"
lowerConvertedShorthandEnv="$(lower_case_convert $SHORTHAND_ENV)"
lowerConvertedShorthandLocation="$(lower_case_convert $SHORTHAND_LOCATION)"

titleConvertedShorthandName="$(title_case_convert $SHORTHAND_NAME)"
titleConvertedShorthandEnv="$(title_case_convert $SHORTHAND_ENV)"
titleConvertedShorthandLocation="$(title_case_convert $SHORTHAND_LOCATION)"

RESOURCE_GROUP_NAME="rg-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt"
KEYVAULT_NAME="kv-${lowerConvertedShorthandName}-${lowerConvertedShorthandLocation}-${lowerConvertedShorthandEnv}-mgt-01"

export DEBIAN_FRONTEND=noninteractive

    #Checks if Azure-CLI is installed
if [[ ! $(command -v az) ]] ;

then
    print_error "You must install Azure CLI to use this script" && exit 1

else
    print_success "Azure-CLI is installed!, continuing" && sleep 2s

fi

if [[ ! $(command -v gh) ]] ;

then
    print_error "You must install GitHub CLI to use this script"  && exit 1

else
    print_success "GitHub CLI is installed!, continuing" && sleep 2s

fi

az account set --subscription "${SUBSCRIPTION_ID}" && \

spokeSubId=$(az account show --query id -o tsv)

spokeMgmtRgName=$(az group show \
        --resource-group "${RESOURCE_GROUP_NAME}" \
    --subscription ${SUBSCRIPTION_ID} --query "name" -o tsv)

spokeKvName=$(az keyvault show \
        --name "${KEYVAULT_NAME}" \
        --resource-group "${spokeMgmtRgName}" \
        --subscription "${SUBSCRIPTION_ID}" \
    --query "name" -o tsv)

spokeKvId=$(az keyvault show \
        --name "${KEYVAULT_NAME}" \
        --resource-group "${spokeMgmtRgName}" \
        --subscription "${SUBSCRIPTION_ID}" \
    --query "id" -o tsv)

LocalAdminSecret=$(az keyvault secret show \
--name "Local${titleConvertedShorthandName}Admin${titleConvertedShorthandEnv}Pwd" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeManagedIdentityClientId=$(az keyvault secret show \
--name "SpokeManagedIdentityClientId" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSaBlobContainerName=$(az keyvault secret show \
--name "SpokeSaBlobContainerName" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSaName=$(az keyvault secret show \
--name "SpokeSaName" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSaPrimaryKey=$(az keyvault secret show \
--name "SpokeSaPrimaryKey" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSaRgName=$(az keyvault secret show \
--name "SpokeSaRgName" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSaSecondaryKey=$(az keyvault secret show \
--name "SpokeSaSecondaryKey" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSubId=$(az keyvault secret show \
--name "SpokeSubId" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSvpClientId=$(az keyvault secret show \
--name "SpokeSvpClientId" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSvpClientSecret=$(az keyvault secret show \
--name "SpokeSvpClientSecret" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeSvpObjectId=$(az keyvault secret show \
--name "SpokeSvpObjectId" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokeTenantId=$(az keyvault secret show \
--name "SpokeTenantId" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SpokePulumiPassphrase=$(az keyvault secret show \
--name "SpokePulumiPassphrase" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

SshKey=$(az keyvault secret show \
--name "Ssh${titleConvertedShorthandName}${titleConvertedShorthandLocation}${titleConvertedShorthandEnv}Key" \
--vault-name "${spokeKvName}" \
--query "value" -o tsv)

print_alert "All secrets have been retrived successfully"

gh secret set LocalAdminSecret --body "${LocalAdminSecret}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeManagedIdentityClientId --body "${SpokeManagedIdentityClientId}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSaBlobContainerName --body "${SpokeSaBlobContainerName}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSaName --body "${SpokeSaName}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSaPrimaryKey --body "${SpokeSaPrimaryKey}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSaRgName --body "${SpokeSaRgName}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSaSecondaryKey --body "${SpokeSaSecondaryKey}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSubId --body "${SpokeSubId}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSvpClientId --body "${SpokeSvpClientId}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSvpClientSecret --body "${SpokeSvpClientSecret}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokePulumiPassphrase --body "${SpokePulumiPassphrase}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeSvpObjectId --body "${SpokeSvpObjectId}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SpokeTenantId --body "${SpokeTenantId}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}
gh secret set SshKey --body "${SshKey}" --org ${GITHUB_ORG} --repos ${GITHUB_REPO}

