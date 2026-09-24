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
variable "default_os_sku" {}
variable "default_disk_size" {}
variable "default_max_pods" {}
variable "default_vm_size" {}
variable "default_scaling_config" {}
variable "extra_nodes_deploy" {}
variable "extra_os_sku" {}
variable "extra_disk_size" {}
variable "extra_max_pods" {}
variable "extra_vm_size" {}
variable "extra_scaling_config" {}
variable "gpu_nodes_deploy" {}
variable "gpu_os_sku" {}
variable "gpu_disk_size" {}
variable "gpu_max_pods" {}
variable "gpu_vm_size" {}
variable "gpu_scaling_config" {}
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