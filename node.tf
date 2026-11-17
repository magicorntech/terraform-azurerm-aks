moved {
  from = azurerm_kubernetes_cluster_node_pool.extra[0]
  to   = azurerm_kubernetes_cluster_node_pool.main["extra"]
}

moved {
  from = azurerm_kubernetes_cluster_node_pool.gpu[0]
  to   = azurerm_kubernetes_cluster_node_pool.main["gpu"]
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each              = local.user_node_pools
  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = each.value.vm_size
  max_pods              = each.value.max_pods
  min_count             = lookup(each.value.scaling_config, "auto", true) == false ? null : lookup(each.value.scaling_config, "min", lookup(each.value.scaling_config, "desired", 1))
  max_count             = lookup(each.value.scaling_config, "auto", true) == false ? null : lookup(each.value.scaling_config, "max", lookup(each.value.scaling_config, "desired", 1))
  node_count            = lookup(each.value.scaling_config, "desired", 1)
  vnet_subnet_id        = (length(var.pvt_subnet_ids) == 2) ? var.pvt_subnet_ids[1] : var.pvt_subnet_ids[0]
  pod_subnet_id         = (length(var.aks_subnet_ids) == 2) ? var.aks_subnet_ids[1] : var.aks_subnet_ids[0]
  os_disk_size_gb       = each.value.disk_size
  os_disk_type          = "Managed"
  os_sku                = each.value.os_sku
  kubelet_disk_type     = "OS"
  scale_down_mode       = "Delete"
  workload_runtime      = "OCIContainer"
  auto_scaling_enabled  = lookup(each.value.scaling_config, "auto", true)
  priority              = local.node_pool_priorities[each.key]
  spot_max_price        = local.node_pool_priorities[each.key] == "Spot" ? lookup(each.value, "spot_max_price", -1) : null
  zones                 = local.zone_selector
  node_taints           = local.node_pool_taints[each.key]

  dynamic "upgrade_settings" {
    for_each = local.node_pool_priorities[each.key] == "Regular" ? [true] : []
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
    Name        = each.key
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
