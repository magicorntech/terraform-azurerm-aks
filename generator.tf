# Writes out the manual/bootstrap steps for the AGC ALB Controller --
# mirrors this repo's own aws-eks/generator.tf pattern (see its
# alb_controller local_file): Terraform provisions the Azure-side identity
# and RBAC (alb.tf), but the actual Helm install and the
# ApplicationLoadBalancer custom resource are Kubernetes-API calls, which no
# module in this repo makes from Terraform itself -- they're written here as
# a ready-to-run runbook instead, with every value this module already knows
# (identity client ID, OIDC-enabled cluster, subnet ID) pre-filled in.
resource "local_file" "alb_controller" {
  count    = var.alb_controller_enabled ? 1 : 0
  filename = "${path.root}/_deployables/1_alb_controller.txt"
  content  = <<EOF
##### One-time per subscription: register the two resource providers AGC needs.
##### Safe to re-run; no-ops if already registered.
az provider register --namespace Microsoft.ServiceNetworking
az provider register --namespace Microsoft.NetworkFunction

##### Install the ALB Controller (managed deployment -- it provisions the
##### AGC Azure resource itself from the ApplicationLoadBalancer CR below).
helm upgrade --install alb-controller \
  oci://mcr.microsoft.com/application-lb/charts/alb-controller \
  --namespace azure-alb-system --create-namespace \
  --set albController.namespace=azure-alb-system \
  --set albController.podIdentity.clientID=${azurerm_user_assigned_identity.alb_controller[0].client_id}

##### Wait for the controller to come up before applying the CR below.
kubectl rollout status deployment/alb-controller -n azure-alb-system

##### Create the ApplicationLoadBalancer -- this is what actually provisions
##### the Application Gateway for Containers resource in Azure, associated
##### with the delegated subnet this module was given (var.alb_subnet_id).
##### Namespace here is arbitrary (it's just where the CR object lives in
##### k8s), unrelated to the ALB Controller's own azure-alb-system namespace
##### above -- pick one for your actual ingress workloads.
kubectl apply -f - <<YAML
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: ${var.tenant}-${var.name}-alb-${var.environment}
  namespace: alb-infra
spec:
  associations:
    - ${var.alb_subnet_id}
YAML

##### Verify -- status.operatingStatus should reach "Programmed"/"Ready"
##### within 5-6 minutes.
kubectl get applicationloadbalancer ${var.tenant}-${var.name}-alb-${var.environment} -n alb-infra -o yaml

##### Once Programmed, point magicorntech/charts' global.ingress[] at this
##### deployment with:
#####   albName:      ${var.tenant}-${var.name}-alb-${var.environment}
#####   albNamespace: alb-infra
EOF
}
