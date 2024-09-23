##### Create AKS Managed Identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "${var.tenant}-${var.name}-aks-${var.instance_name}-mi-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.rg_location
}

resource "azurerm_role_assignment" "owner" {
  scope                = var.rg_id
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  role_definition_name = "Owner"
}

resource "azurerm_role_assignment" "additional" {
  count                = (var.additional_rg_id == false) ? 0 : 1
  scope                = var.additional_rg_id
  principal_id         = azurerm_user_assigned_identity.main.principal_id
  role_definition_name = "Private DNS Zone Contributor"
}