resource "azurerm_kubernetes_cluster_node_pool" "main" {
  name                  = "extra"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = var.extra_vm_size
  max_pods              = var.extra_max_pods
  min_count             = lookup(var.extra_scaling_config, "auto") == false ? null : lookup(var.extra_scaling_config, "min")
  max_count             = lookup(var.extra_scaling_config, "auto") == false ? null : lookup(var.extra_scaling_config, "max")
  node_count            = lookup(var.extra_scaling_config, "desired")
  vnet_subnet_id        = (length(var.pvt_subnet_ids) == 2) ? var.pvt_subnet_ids[1] : var.pvt_subnet_ids[0]
  pod_subnet_id         = (length(var.aks_subnet_ids) == 2) ? var.aks_subnet_ids[1] : var.aks_subnet_ids[0]
  os_disk_size_gb       = var.extra_disk_size
  os_disk_type          = "Managed"
  os_sku                = var.extra_os_sku
  kubelet_disk_type     = "OS"
  scale_down_mode       = "Delete"
  workload_runtime      = "OCIContainer"
  auto_scaling_enabled  = lookup(var.extra_scaling_config, "auto")
  priority              = lookup(var.extra_scaling_config, "spot") == true ? "Spot" : "Regular"
  spot_max_price        = lookup(var.extra_scaling_config, "spot") == true ? -1 : null
  zones                 = local.zone_selector

  dynamic "upgrade_settings" {
    for_each = (lookup(var.extra_scaling_config, "spot") == false) ? [true] : []
    content {
      max_surge = "20%"
    }
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }

  tags = {
    Name        = "extra"
    Tenant      = var.tenant
    Project     = var.name
    Environment = var.environment
    Maintainer  = "Magicorn"
    Terraform   = "yes"
  }

  depends_on = [
    azurerm_kubernetes_cluster.main
  ]
}