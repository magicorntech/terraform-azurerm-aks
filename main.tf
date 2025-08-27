resource "azurerm_kubernetes_cluster" "main" {
  name                                = "${var.tenant}-${var.name}-aks-${var.instance_name}-${var.environment}"
  resource_group_name                 = var.rg_name
  location                            = var.rg_location
  dns_prefix_private_cluster          = "${var.tenant}-${var.name}-aks-${var.instance_name}-${var.environment}-dns"
  kubernetes_version                  = var.aks_version
  sku_tier                            = var.sku_tier
  http_application_routing_enabled    = false
  role_based_access_control_enabled   = true
  private_cluster_public_fqdn_enabled = false
  private_cluster_enabled             = true
  private_dns_zone_id                 = var.aks_prv_dns_id
  image_cleaner_enabled               = false
  image_cleaner_interval_hours        = 48
  node_os_upgrade_channel             = "None"
  cost_analysis_enabled               = var.cost_analysis_enabled

  default_node_pool {
    name                        = "default"
    temporary_name_for_rotation = "defaulttemp"
    type                        = "VirtualMachineScaleSets"
    vm_size                     = var.default_vm_size
    max_pods                    = var.default_max_pods
    min_count                   = lookup(var.default_scaling_config, "auto") == false ? null : lookup(var.default_scaling_config, "min")
    max_count                   = lookup(var.default_scaling_config, "auto") == false ? null : lookup(var.default_scaling_config, "max")
    node_count                  = lookup(var.default_scaling_config, "desired")
    vnet_subnet_id              = var.pvt_subnet_ids[0]
    pod_subnet_id               = var.aks_subnet_ids[0]
    os_disk_size_gb             = var.default_disk_size
    os_disk_type                = "Managed"
    os_sku                      = var.default_os_sku
    kubelet_disk_type           = "OS"
    scale_down_mode             = "Delete"
    workload_runtime            = "OCIContainer"
    auto_scaling_enabled        = lookup(var.default_scaling_config, "auto")
    node_public_ip_enabled      = false
    zones                       = [var.zones]

    upgrade_settings {
      max_surge = "20%"
    }

    tags = {
      Name        = "default"
      Tenant      = var.tenant
      Project     = var.name
      Environment = var.environment
      Maintainer  = "Magicorn"
      Terraform   = "yes"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidrs     = [var.service_cidrs]
    dns_service_ip    = var.dns_service_ip
    ip_versions       = ["IPv4"]
    load_balancer_sku = "standard"
    outbound_type     = "userAssignedNATGateway"

    nat_gateway_profile {
      idle_timeout_in_minutes = 5
    }
  }

  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  auto_scaler_profile {
    balance_similar_node_groups      = lookup(var.auto_scaler_profile, "balance_similar_node_groups", null)
    expander                         = lookup(var.auto_scaler_profile, "expander", null)
    max_graceful_termination_sec     = lookup(var.auto_scaler_profile, "max_graceful_termination_sec", null)
    max_node_provisioning_time       = lookup(var.auto_scaler_profile, "max_node_provisioning_time", null)
    max_unready_nodes                = lookup(var.auto_scaler_profile, "max_unready_nodes", null)
    max_unready_percentage           = lookup(var.auto_scaler_profile, "max_unready_percentage", null)
    new_pod_scale_up_delay           = lookup(var.auto_scaler_profile, "new_pod_scale_up_delay", null)
    scale_down_delay_after_add       = lookup(var.auto_scaler_profile, "scale_down_delay_after_add", null)
    scale_down_delay_after_delete    = lookup(var.auto_scaler_profile, "scale_down_delay_after_delete", null)
    scale_down_delay_after_failure   = lookup(var.auto_scaler_profile, "scale_down_delay_after_failure", null)
    scale_down_unneeded              = lookup(var.auto_scaler_profile, "scale_down_unneeded", null)
    scale_down_unready               = lookup(var.auto_scaler_profile, "scale_down_unready", null)
    scale_down_utilization_threshold = lookup(var.auto_scaler_profile, "scale_down_utilization_threshold", null)
    empty_bulk_delete_max            = lookup(var.auto_scaler_profile, "empty_bulk_delete_max", null)
    skip_nodes_with_local_storage    = lookup(var.auto_scaler_profile, "skip_nodes_with_local_storage", null)
    skip_nodes_with_system_pods      = lookup(var.auto_scaler_profile, "skip_nodes_with_system_pods", null)
  }

  # oms_agent {
  #   log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  # }

  lifecycle {
    ignore_changes = [
      network_profile[0].load_balancer_profile,
      network_profile[0].nat_gateway_profile,
      default_node_pool[0].node_count,
      upgrade_override
    ]
  }

  tags = {
    Name        = "${var.tenant}-${var.name}-aks-${var.instance_name}-${var.environment}"
    Tenant      = var.tenant
    Project     = var.name
    Environment = var.environment
    Maintainer  = "Magicorn"
    Terraform   = "yes"
  }

  depends_on = [
    azurerm_role_assignment.owner,
    azurerm_role_assignment.additional
  ]
}
