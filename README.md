# terraform-azurerm-aks

Magicorn made Terraform Module for Azure Provider
--
```
module "aks" {
  source           = "magicorntech/aks/azurerm"
  version          = "0.0.2"
  tenant           = var.tenant
  name             = var.name
  environment      = var.environment
  rg_id            = azurerm_resource_group.main.id
  rg_name          = azurerm_resource_group.main.name
  rg_location      = azurerm_resource_group.main.location
  additional_rg_id = "/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/magicorn-main-rg-bastion" # can be false
  aks_prv_dns_id   = "/subscriptions/12345678-1234-1234-1234-123456789abc/resourceGroups/magicorn-main-rg-bastion/providers/Microsoft.Network/privateDnsZones/privatelink.westeurope.azmk8s.io"
  pvt_subnet_ids   = module.network.pvt_subnet_ids
  aks_subnet_ids   = module.network.aks_subnet_ids

  # AKS Configuration
  instance_name          = "cluster"
  aks_version            = "1.28.9"
  service_cidrs          = "10.33.0.0/16"
  dns_service_ip         = "10.33.0.10"
  default_os_sku         = "Ubuntu"
  extra_os_sku           = "Ubuntu"
  default_disk_size      = 100
  extra_disk_size        = 100
  default_max_pods       = 90
  extra_max_pods         = 90
  default_vm_size        = "Standard_F8s_v2"
  extra_vm_size          = "Standard_F8s_v2"
  default_scaling_config = { desired = 2, min = 2, max = 15, auto = true }
  extra_scaling_config   = { desired = 2, min = 2, max = 15, auto = true, spot = false }
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = false
    expander                         = "least-waste"
    scale_down_utilization_threshold = 0.65
  }
}

```