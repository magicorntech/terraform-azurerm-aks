# terraform-azurerm-aks

Magicorn made Terraform Module for Azure Provider
--
```
module "aks" {
  source           = "magicorntech/aks/azurerm"
  version          = "0.2.0"
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
  aks_version            = "1.31.9"
  sku_tier               = "Free"
  service_cidrs          = "10.33.0.0/16"
  dns_service_ip         = "10.33.0.10"
  cost_analysis_enabled  = true
  zones                  = ["2"]
  
  # Auto Scaler Configuration
  auto_scaler_profile = {
    balance_similar_node_groups      = true
    skip_nodes_with_local_storage    = false
    skip_nodes_with_system_pods      = false
    expander                         = "least-waste"
    scale_down_utilization_threshold = 0.65
  }

  # Node Configuration
  default_os_sku         = "Ubuntu"
  default_disk_size      = 128
  default_max_pods       = 90
  default_vm_size        = "Standard_F8s_v2"
  default_scaling_config = { desired = 2, min = 3, max = 10, auto = true }

  extra_nodes_deploy   = true
  extra_os_sku         = "Ubuntu"
  extra_disk_size      = 128
  extra_max_pods       = 90
  extra_vm_size        = "Standard_F8s_v2"
  extra_scaling_config = { desired = 2, min = 3, max = 10, auto = true, spot = false }

  gpu_nodes_deploy   = false
  gpu_os_sku         = "Ubuntu"
  gpu_disk_size      = 128
  gpu_max_pods       = 90
  gpu_vm_size        = "Standard_NC4as_T4_v3"
  gpu_scaling_config = { desired = 1, min = 1, max = 1, auto = true, spot = false }

  # Optional: Application Gateway for Containers (ALB Controller) prerequisites.
  # Both default off/null -- omit entirely if you don't need AGC ingress.
  alb_controller_enabled = true
  alb_subnet_id           = azurerm_subnet.alb.id # delegated to Microsoft.ServiceNetworking/trafficControllers, /24 or larger, NOT the AKS node/pod subnet
}

```

### Application Gateway for Containers (AGC) ALB Controller

Setting `alb_controller_enabled = true` (+ `alb_subnet_id`) provisions only
the **Azure-side** prerequisites for the ALB Controller's managed deployment
mode: enables OIDC issuer + Workload Identity on the cluster, a user-assigned
managed identity federated to the ALB Controller's own fixed ServiceAccount
(`system:serviceaccount:azure-alb-system:alb-controller-sa`), and the three
Azure RBAC roles it needs (Reader + "AppGw for Containers Configuration
Manager" on the AKS node resource group, Network Contributor scoped to just
`alb_subnet_id`).

It does **not** install the ALB Controller Helm chart or create the
`ApplicationLoadBalancer` custom resource — same split this module already
uses for cluster-autoscaler/aws-load-balancer-controller on the AWS side
(see `aws-eks`'s own `generator.tf`): nothing in this module talks to the
Kubernetes API. After `terraform apply`, run `terraform output` to find
`_deployables/1_alb_controller.txt` (or look in your root module's
`_deployables/` directory) for the ready-to-run `helm install` +
`kubectl apply` commands, with the managed identity's client ID and your
subnet already filled in.

The delegated `alb_subnet_id` subnet itself is **not** created by this
module (subnets live in `azurerm-network`) — provision one there or
manually before setting `alb_controller_enabled`.

See magicorntech/charts' README ("Azure (AKS)" section) for the matching
`global.ingress[].albName`/`albNamespace` chart values once the
`ApplicationLoadBalancer` is `Programmed`.