resource "azurecaf_name" "subscription" {
  name          = "mgmt"
  resource_type = "azurerm_resource_group"
  prefixes      = []
  suffixes      = [var.short, var.loc, var.env]
  random_length = 5
  clean_input   = true
}

output "test" {
  value = azurecaf_name.subscription.result
}