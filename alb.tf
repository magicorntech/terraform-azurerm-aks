##### Application Gateway for Containers (AGC) ALB Controller prerequisites
#####
##### This only provisions the AZURE-side identity/RBAC the ALB Controller
##### needs to run under Azure Workload Identity and manage AGC resources —
##### it does NOT install the ALB Controller Helm chart or apply the
##### ApplicationLoadBalancer custom resource. Same split this repo's own
##### aws-eks module already uses for aws-load-balancer-controller (see its
##### oidc.tf + iam_k8s.tf for the identity side, generator.tf for the
##### Helm-install instructions it writes out instead of applying): nothing
##### in this module talks to the Kubernetes API, only to Azure's control
##### plane. See generator.tf for the Helm/kubectl commands this identity
##### is for.
#####
##### All resources here are gated on var.alb_controller_enabled (default
##### false) and create nothing for an existing consumer of this module
##### that hasn't opted in.

resource "azurerm_user_assigned_identity" "alb_controller" {
  count               = var.alb_controller_enabled ? 1 : 0
  name                = "${var.tenant}-${var.name}-aks-${var.instance_name}-alb-mi-${var.environment}"
  resource_group_name = var.rg_name
  location            = var.rg_location
}

# Trusts the ALB Controller's own Kubernetes ServiceAccount to mint Azure AD
# tokens for this identity. Subject is the ALB Controller Helm chart's own
# fixed defaults (namespace "azure-alb-system", ServiceAccount
# "alb-controller-sa" -- the SA name is hardcoded in the chart's own
# templates, not configurable via any Helm value) -- confirmed directly
# against the chart, not just docs. If the chart is ever installed into a
# different namespace, this subject (and generator.tf's --namespace) must
# both change together.
resource "azurerm_federated_identity_credential" "alb_controller" {
  count               = var.alb_controller_enabled ? 1 : 0
  name                = "${var.tenant}-${var.name}-aks-${var.instance_name}-alb-fic-${var.environment}"
  resource_group_name = var.rg_name
  parent_id           = azurerm_user_assigned_identity.alb_controller[0].id
  issuer              = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject             = "system:serviceaccount:azure-alb-system:alb-controller-sa"
  audience            = ["api://AzureADTokenExchange"]
}

# Lets the controller read the AKS node resource group (MC_...) it runs
# alongside -- required by the ALB Controller's own install docs.
resource "azurerm_role_assignment" "alb_controller_reader" {
  count                = var.alb_controller_enabled ? 1 : 0
  scope                = "${data.azurerm_subscription.current[0].id}/resourceGroups/${azurerm_kubernetes_cluster.main.node_resource_group}"
  principal_id         = azurerm_user_assigned_identity.alb_controller[0].principal_id
  role_definition_name = "Reader"
}

# "AppGw for Containers Configuration Manager" -- lets the controller
# actually provision/manage the AGC resource itself (the managed-deployment
# model this module targets). Built-in role, referenced by its fixed GUID
# since it has no role_definition_name lookup path used elsewhere in this
# repo's modules.
resource "azurerm_role_assignment" "alb_controller_config_manager" {
  count              = var.alb_controller_enabled ? 1 : 0
  scope              = "${data.azurerm_subscription.current[0].id}/resourceGroups/${azurerm_kubernetes_cluster.main.node_resource_group}"
  principal_id       = azurerm_user_assigned_identity.alb_controller[0].principal_id
  role_definition_id = "${data.azurerm_subscription.current[0].id}/providers/Microsoft.Authorization/roleDefinitions/fbc52c3f-28ad-4303-a892-8a056630b8f1"
}

# Network Contributor, scoped to ONLY the delegated AGC subnet (never the
# whole VNet or the AKS node subnet) -- needed for
# Microsoft.Network/virtualNetworks/subnets/join/action when AGC attaches
# to it. Subnet itself is out of scope for this module; see variables.tf.
resource "azurerm_role_assignment" "alb_controller_network" {
  count                = var.alb_controller_enabled ? 1 : 0
  scope                = var.alb_subnet_id
  principal_id         = azurerm_user_assigned_identity.alb_controller[0].principal_id
  role_definition_name = "Network Contributor"
}
