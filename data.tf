locals {
  zone_selector = (
    (length(var.aks_subnet_ids) == 1) ? [1] : false ||
    (length(var.aks_subnet_ids) == 2) ? [2] : []
  )
}

# Only consumed by alb.tf, to build the full resource ID of the AKS node
# resource group for the two AGC-related role assignment scopes (role
# assignments need a full "/subscriptions/.../resourceGroups/X" ID, and
# azurerm_kubernetes_cluster.node_resource_group only exposes the bare name).
# Gated the same way as everything in alb.tf -- an existing consumer that
# hasn't opted into alb_controller_enabled should never pay for an extra
# live Azure API read on every plan/apply.
data "azurerm_subscription" "current" {
  count = var.alb_controller_enabled ? 1 : 0
}