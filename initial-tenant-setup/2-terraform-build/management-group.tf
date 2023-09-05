resource "azurerm_management_group" "mg_libredevops_parent" {
  display_name = "mg-libredevops"
}

resource "azurerm_management_group" "mg_libredevops_mgmt" {
  display_name = "mg-libredevops-management"

  subscription_ids = [
    data.azurerm_client_config.current.subscription_id,
  ]
}

resource "azurerm_management_group" "mg_libredevops_decommissioned" {
  parent_management_group_id = azurerm_management_group.mg_libredevops_parent.id
  display_name               = "mg-libredevops-decommissioned"

  subscription_ids = [
  ]
}

resource "azurerm_management_group" "mg_libredevops_dev" {
  count                      = var.dev_subscriptions_needed
  parent_management_group_id = azurerm_management_group.mg_libredevops_parent.id
  display_name               = "mg-libredevops-dev"

  subscription_ids = [
    azurerm_subscription.dev_subscription[count.index].subscription_id
  ]
}

resource "azurerm_management_group" "mg_libredevops_uat" {
  count                      = var.uat_subscriptions_needed
  parent_management_group_id = azurerm_management_group.mg_libredevops_parent.id
  display_name               = "mg-libredevops-uat"

  subscription_ids = [
    azurerm_subscription.uat_subscription[count.index].subscription_id
  ]
}

resource "azurerm_management_group" "mg_libredevops_ppd" {
  count                      = var.ppd_subscriptions_needed
  parent_management_group_id = azurerm_management_group.mg_libredevops_parent.id
  display_name               = "mg-libredevops-ppd"

  subscription_ids = [
    azurerm_subscription.ppd_subscription[count.index].subscription_id
  ]
}

resource "azurerm_management_group" "mg_libredevops_prd" {
  count                      = var.prd_subscriptions_needed
  parent_management_group_id = azurerm_management_group.mg_libredevops_parent.id
  display_name               = "mg-libredevops-prd"

  subscription_ids = [
    azurerm_subscription.prd_subscription[count.index].subscription_id
  ]
}
