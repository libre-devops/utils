data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {
  subscription_id = data.azurerm_client_config.current.subscription_id
}

data "azurerm_resource_group" "mgmt_rg" {
  name = "rg-${var.short}-${var.loc}-prd-mgmt"
}

data "azurerm_key_vault" "mgmt_kv" {
  name                = "kv-${var.short}-${var.loc}-prd-mgmt-01"
  resource_group_name = data.azurerm_resource_group.mgmt_rg.name
}

data "azurerm_key_vault_secret" "billing_account_name" {
  key_vault_id = data.azurerm_key_vault.mgmt_kv.id
  name         = "BillingAccountName"
}

data "azurerm_key_vault_secret" "billing_profile_name" {
  key_vault_id = data.azurerm_key_vault.mgmt_kv.id
  name         = "BillingProfileName"
}

data "azurerm_key_vault_secret" "invoice_section_name" {
  key_vault_id = data.azurerm_key_vault.mgmt_kv.id
  name         = "InvoiceSectionName"
}

data "azurerm_billing_mca_account_scope" "this" {
  billing_account_name = data.azurerm_key_vault_secret.billing_account_name.value
  billing_profile_name = data.azurerm_key_vault_secret.billing_profile_name.value
  invoice_section_name = data.azurerm_key_vault_secret.invoice_section_name.value
}

data "azurerm_management_group" "tenant_root_group" {
  display_name = "Tenant Root Group"
}
