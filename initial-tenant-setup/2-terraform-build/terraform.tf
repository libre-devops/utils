terraform {
  #Use the latest by default, uncomment below to pin or use hcl.lck
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azuread = {
      source = "hashicorp/azuread"
    }
    azapi = {
      source = "Azure/azapi"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
    }
    azurecaf = {
      source = "aztfmod/azurecaf"
    }
  }
  backend "azurerm" {
    storage_account_name = "saldouksprdmgmt01"
    container_name       = "blobldouksprdmgmt01"
    key                  = "management-setup.terraform.tfstate"
    use_azuread_auth     = true
  }
}
