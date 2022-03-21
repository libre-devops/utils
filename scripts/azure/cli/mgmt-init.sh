#!/usr/bin/env bash

SUBSCRIPTION_ID="ExampleSubIDorName"
SHORTHAND_NAME="exm"
SHORTHAND_ENV="prd"
SHORTHAND_LOCATION="euw"
LONGHAND_LOCATION="westeurope"

set -xeuo pipefail

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

clean_on_exit() {
    rm -rf "spoke_svp.json"
    az logout
    cat /dev/null > ~/.bash_history && history -c
}

#Without this, you have a chicken and an egg scenario, you need a storage account for terraform, you need an ARM template for ARM, or you can create in portal and terraform import, I prefer just using Azure-CLI and "one and done" it
print_alert "This script is intended to be ran in the Cloud Shell in Azure to setup your pre-requisite items in a fresh tenant" && sleep 3s && \

az account set --subscription "${SUBSCRIPTION_ID}" && \

    #Create Management Resource group and export its values
if

signedInUserUpn=$(az ad signed-in-user show \
--query "userPrincipalName" -o tsv)

az group create \
    --name "rg-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-mgt" \
    --location "${LONGHAND_LOCATION}" \
    --subscription ${SUBSCRIPTION_ID} && \

    spokeMgmtRgName=$(az group show \
        --resource-group "rg-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-mgt" \
    --subscription ${SUBSCRIPTION_ID} --query "name" -o tsv)

then
    print_success "Management resource group made for spoke" && sleep 2s
else
    print_error "Something went wrong making the management resource group inside spoke" && clean_on_exit && exit 1
fi

#Create management keyvault, add rules to it and export values for later use
if

az keyvault create \
    --name "kv-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-mgt-01" \
    --resource-group "${spokeMgmtRgName}" \
    --location "${LONGHAND_LOCATION}" \
    --subscription "${SUBSCRIPTION_ID}"

spokeKvName=$(az keyvault show \
        --name "kv-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-mgt-01" \
        --resource-group "${spokeMgmtRgName}" \
        --subscription "${SUBSCRIPTION_ID}" \
    --query "name" -o tsv)

spokeKvId=$(az keyvault show \
        --name "kv-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-mgt-01" \
        --resource-group "${spokeMgmtRgName}" \
        --subscription "${SUBSCRIPTION_ID}" \
    --query "id" -o tsv)

then
    print_success "Management keyvault made for spoke" && sleep 2s
else
    print_error "Something went wrong making the management keyvault." && clean_on_exit && exit 1
fi

#Create Keyvault secret for Local Admin in the Keyvault
if

spokeAdminSecret=$(openssl rand -base64 21) && \

    az keyvault secret set \
    --vault-name "${spokeKvName}" \
    --name "Local${SHORTHAND_NAME}Admin${SHORTHAND_ENV}-pwd" \
    --value "${spokeAdminSecret}"

then
    print_success "Keyvault secret has been made for the Local Admin User" && sleep 2s
else
    print_error "Something has went wrong with creating the keyvault secret, check the logs." && clean_on_exit && exit 1

fi

#Create SSH Key for Linux boxes
if

mkdir -p "/tmp/${SHORTHAND_NAME}-${SHORTHAND_ENV}-ssh"
ssh-keygen -b 4096 -t rsa -f "/tmp/${SHORTHAND_NAME}-${SHORTHAND_ENV}-ssh/azureid_rsa.key" -q -N '' && \

    az sshkey create \
    --location "${LONGHAND_LOCATION}" \
    --public-key "@/tmp/${SHORTHAND_NAME}-${SHORTHAND_ENV}-ssh/azureid_rsa.key.pub" \
    --resource-group "${spokeMgmtRgName}" \
    --name "ssh-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-pub-mgt" && \

    az keyvault secret set \
    --vault-name "${spokeKvName}" \
    --name "ssh-${SHORTHAND_NAME}-${SHORTHAND_LOCATION}-${SHORTHAND_ENV}-key-mgt"  \
    --file "/tmp/${SHORTHAND_NAME}-${SHORTHAND_ENV}-ssh/azureid_rsa.key" && \

    rm -rf /tmp/${SHORTHAND_NAME}-${SHORTHAND_ENV}-ssh && echo "Keys created"

then
    print_success "SSH keys have been generated and stored appropriately" && sleep 2s


else
    print_error "Something has went wrong with creating the ssh keys check the logs." && clean_on_exit && exit 1

fi

#Create storage account for terraform, eliminate chicken and egg scenario
if

az storage account create \
    --location "${LONGHAND_LOCATION}" \
    --sku "Standard_LRS" \
    --access-tier "Hot" \
    --resource-group "${spokeMgmtRgName}" \
    --name "sa${SHORTHAND_NAME}${SHORTHAND_LOCATION}${SHORTHAND_ENV}mgt01" && \

    az storage container create \
    --account-name "sa${SHORTHAND_NAME}${SHORTHAND_LOCATION}${SHORTHAND_ENV}mgt01" \
    --public-access "off" \
    --resource-group "${spokeMgmtRgName}" \
    --name "blob${SHORTHAND_NAME}${SHORTHAND_LOCATION}${SHORTHAND_ENV}tfm01"

  spokeSaId=$(az storage account show \
        --name "sa${SHORTHAND_NAME}${SHORTHAND_LOCATION}${SHORTHAND_ENV}mgt01" \
        --resource-group "${spokeMgmtRgName}" \
        --subscription "${SUBSCRIPTION_ID}" \
    --query "id" -o tsv)

  spokeSaName=$(az storage account show \
      --name "sa${SHORTHAND_NAME}${SHORTHAND_LOCATION}${SHORTHAND_ENV}mgt01" \
      --resource-group "${spokeMgmtRgName}" \
      --subscription "${SUBSCRIPTION_ID}" \
  --query "name" -o tsv)

then
    print_success "Storage account created" && sleep 2s


else
    print_error "Something has went wrong with creating the storage account  Error Code CLOUD05" && clean_on_exit && exit 1

fi

if

export MSYS_NO_PATHCONV=1

az role assignment create \
--role "Storage Account Key Operator Service Role" \
--assignee "https://vault.azure.net" \
--scope "${spokeSaId}"

az keyvault set-policy \
--name "${spokeKvName}" \
--upn "${signedInUserUpn}" \
--storage-permissions get list delete set update regeneratekey getsas listsas deletesas setsas recover backup restore purge

az keyvault storage add \
--vault-name "${spokeKvName}" \
-n "${spokeSaName}" \
--active-key-name key1 \
--auto-regenerate-key \
--regeneration-period P90D \
--resource-id "${spokeSaId}"

az keyvault storage add \
--vault-name "${spokeKvName}" \
-n "${spokeSaName}" \
--active-key-name key2 \
--auto-regenerate-key \
--regeneration-period P90D \
--resource-id "${spokeSaId}"


then
  print_success "Storage account now being managed by keyvault" && sleep 2s

else

  print_error "Something has went wrong setting the storage account to be managed by keyvault  Error Code CLOUD06" && clean_on_exit && exit 1

fi