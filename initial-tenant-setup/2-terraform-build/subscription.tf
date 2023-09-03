resource "azurerm_subscription" "dev_subscription" {
  count             = var.dev_subscriptions_needed
  subscription_name = "sub-${var.short}-${var.loc}-dev-${format("%02d", count.index + 1)}"
  billing_scope_id  = data.azurerm_billing_mca_account_scope.this.id
  tags              = local.tags
}

resource "azurerm_subscription" "uat_subscription" {
  count             = var.uat_subscriptions_needed
  subscription_name = "sub-${var.short}-${var.loc}-uat-${format("%02d", count.index + 1)}"
  billing_scope_id  = data.azurerm_billing_mca_account_scope.this.id
  tags              = local.tags
}

resource "azurerm_subscription" "ppd_subscription" {
  count             = var.ppd_subscriptions_needed
  subscription_name = "sub-${var.short}-${var.loc}-ppd-${format("%02d", count.index + 1)}"
  billing_scope_id  = data.azurerm_billing_mca_account_scope.this.id
  tags              = local.tags
}

resource "azurerm_subscription" "prd_subscription" {
  count             = var.prd_subscriptions_needed
  subscription_name = "sub-${var.short}-${var.loc}-prd-${format("%02d", count.index + 1)}"
  billing_scope_id  = data.azurerm_billing_mca_account_scope.this.id
  tags              = local.tags
}
