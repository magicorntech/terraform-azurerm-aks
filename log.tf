# resource "random_id" "workspace" {
#   byte_length = 8
# }

# resource "azurerm_log_analytics_workspace" "main" {
#   name                            = "${var.tenant}-${var.name}-aks-la-${random_id.workspace.dec}-${var.environment}"
#   location                        = var.rg_location
#   resource_group_name             = var.rg_name
#   allow_resource_only_permissions = true
#   local_authentication_disabled   = false
#   internet_ingestion_enabled      = true
#   internet_query_enabled          = true
#   retention_in_days               = 30
#   sku                             = "PerGB2018"

#   tags = {
#     Name        = "${var.tenant}-${var.name}-aks-la-${random_id.workspace.dec}-${var.environment}"
#     Tenant      = var.tenant
#     Project     = var.name
#     Environment = var.environment
#     Maintainer  = "Magicorn"
#     Terraform   = "yes"
#   }
# }

# resource "azurerm_log_analytics_solution" "main" {
#   location              = var.rg_location
#   resource_group_name   = var.rg_name
#   solution_name         = "ContainerInsights"
#   workspace_name        = "${var.tenant}-${var.name}-aks-la-${random_id.workspace.dec}-${var.environment}"
#   workspace_resource_id = azurerm_log_analytics_workspace.main.id

#   plan {
#     publisher = "Microsoft"
#     product   = "OMSGallery/ContainerInsights"
#   }

#   tags = {
#     Name        = "${var.tenant}-${var.name}-aks-la-${random_id.workspace.dec}-${var.environment}"
#     Tenant      = var.tenant
#     Project     = var.name
#     Environment = var.environment
#     Maintainer  = "Magicorn"
#     Terraform   = "yes"
#   }
# }
