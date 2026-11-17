# terraform-azurerm-aks

Magicorn made Terraform Module for Azure Provider
--
```
module "aks" {
  source           = "magicorntech/aks/azurerm"
  version          = "0.3.0"
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

  # Node Configuration (default is required; set node_pools = {} to use legacy inputs)
  node_pools = {
    default = {
      os_sku         = "Ubuntu"
      disk_size      = 128
      max_pods       = 90
      vm_size        = "Standard_F8s_v2"
      scaling_config = { desired = 2, min = 3, max = 10, auto = true }
    }
    extra = {
      os_sku         = "Ubuntu"
      disk_size      = 128
      max_pods       = 90
      vm_size        = "Standard_F8s_v2"
      scaling_config = { desired = 2, min = 3, max = 10, auto = true }
      priority       = "Regular"
    }
    gpu = {
      os_sku         = "Ubuntu"
      disk_size      = 128
      max_pods       = 90
      vm_size        = "Standard_NC4as_T4_v3"
      scaling_config = { desired = 1, min = 1, max = 1, auto = true }
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]
    }
  }

  # Optional: Application Gateway for Containers (ALB Controller) prerequisites.
  # Both default off/null -- omit entirely if you don't need AGC ingress.
  alb_controller_enabled = true
  alb_subnet_id           = azurerm_subnet.alb.id # delegated to Microsoft.ServiceNetworking/trafficControllers, /24 or larger, NOT the AKS node/pod subnet
}

```

### Node pools

Each `node_pools` map key becomes the AKS node pool name. The required
`default` entry configures AKS' built-in system pool; all other entries
create user node pools. Optional `taints` on user pools uses the same
`[{ key, value, effect }]` shape as EKS. AWS effect names
(`NO_SCHEDULE`, `NO_EXECUTE`, `PREFER_NO_SCHEDULE`) are converted to AKS
taint effects. The AzureRM provider does not expose taints on the built-in
system pool, so `default.taints` is rejected. Optional `priority` is
`"Regular"` by default or `"Spot"`.
Existing scalar node-pool inputs remain supported when `node_pools` is empty.

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