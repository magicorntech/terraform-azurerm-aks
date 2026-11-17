locals {
  zone_selector = (
    (length(var.aks_subnet_ids) == 1) ? [1] : false ||
    (length(var.aks_subnet_ids) == 2) ? [2] : []
  )

  node_taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  legacy_node_pools = merge(
    {
      default = {
        os_sku         = var.default_os_sku
        disk_size      = var.default_disk_size
        max_pods       = var.default_max_pods
        vm_size        = var.default_vm_size
        scaling_config = var.default_scaling_config
      }
    },
    var.extra_nodes_deploy ? {
      extra = {
        os_sku         = var.extra_os_sku
        disk_size      = var.extra_disk_size
        max_pods       = var.extra_max_pods
        vm_size        = var.extra_vm_size
        scaling_config = var.extra_scaling_config
        priority       = lookup(var.extra_scaling_config, "spot", false) ? "Spot" : "Regular"
      }
    } : {},
    var.gpu_nodes_deploy ? {
      gpu = {
        os_sku         = var.gpu_os_sku
        disk_size      = var.gpu_disk_size
        max_pods       = var.gpu_max_pods
        vm_size        = var.gpu_vm_size
        scaling_config = var.gpu_scaling_config
        priority       = lookup(var.gpu_scaling_config, "spot", false) ? "Spot" : "Regular"
        taints = [{
          key    = "nvidia.com/gpu"
          value  = "true"
          effect = "NO_SCHEDULE"
        }]
      }
    } : {}
  )

  node_pools = length(var.node_pools) > 0 ? var.node_pools : local.legacy_node_pools

  default_node_pool = local.node_pools["default"]

  user_node_pools = {
    for name, pool in local.node_pools : name => pool if name != "default"
  }

  node_pool_taints = {
    for name, pool in local.node_pools : name => [
      for taint in try(pool.taints == null ? [] : pool.taints, []) :
      format(
        "%s=%s:%s",
        taint.key,
        taint.value,
        lookup(local.node_taint_effects, taint.effect, taint.effect)
      )
    ]
  }

  node_pool_priorities = {
    for name, pool in local.node_pools : name => coalesce(try(pool.priority, null), "Regular")
  }
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