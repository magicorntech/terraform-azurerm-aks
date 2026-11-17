variable "tenant" {}
variable "name" {}
variable "environment" {}
variable "rg_id" {}
variable "rg_name" {}
variable "rg_location" {}
variable "additional_rg_id" {}
variable "aks_prv_dns_id" {}
variable "pvt_subnet_ids" {}
variable "aks_subnet_ids" {}
variable "instance_name" {}
variable "aks_version" {}
variable "sku_tier" {}
variable "service_cidrs" {}
variable "dns_service_ip" {}
variable "cost_analysis_enabled" {}
variable "auto_scaler_profile" {}
variable "node_pools" {
  description = "AKS node pools keyed by pool name. Include a default entry; other entries create user node pools."
  default     = {}

  validation {
    condition = length(var.node_pools) == 0 || (
      contains(keys(var.node_pools), "default") &&
      try(length(var.node_pools["default"].taints), 0) == 0
    )
    error_message = "node_pools must include a \"default\" pool; taints are only supported on user pools."
  }
}

# Deprecated compatibility inputs. Used only when node_pools is empty.
variable "default_os_sku" {
  default = null
}
variable "default_disk_size" {
  default = null
}
variable "default_max_pods" {
  default = null
}
variable "default_vm_size" {
  default = null
}
variable "default_scaling_config" {
  default = null
}
variable "extra_nodes_deploy" {
  default = false
}
variable "extra_os_sku" {
  default = null
}
variable "extra_disk_size" {
  default = null
}
variable "extra_max_pods" {
  default = null
}
variable "extra_vm_size" {
  default = null
}
variable "extra_scaling_config" {
  default = null
}
variable "gpu_nodes_deploy" {
  default = false
}
variable "gpu_os_sku" {
  default = null
}
variable "gpu_disk_size" {
  default = null
}
variable "gpu_max_pods" {
  default = null
}
variable "gpu_vm_size" {
  default = null
}
variable "gpu_scaling_config" {
  default = null
}
variable "zones" {}

# Optional: Application Gateway for Containers (AGC) ALB Controller
# prerequisites — identity/RBAC/OIDC only. Default false/null so every
# existing consumer of this module is completely unaffected; the only two
# variables in this file with a default, deliberately, so adding them can
# never be a breaking change. See alb.tf and generator.tf.
variable "alb_controller_enabled" {
  default = false
}

# Resource ID of a subnet delegated to Microsoft.ServiceNetworking/
# trafficControllers (min /24, not the AKS node/pod subnet) — required only
# when alb_controller_enabled is true. Subnet creation itself is out of
# scope for this module (subnets live in azurerm-network).
variable "alb_subnet_id" {
  default = null
}