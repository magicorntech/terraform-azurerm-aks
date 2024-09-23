locals {
  zone_selector = (
    (length(var.aks_subnet_ids) == 1) ? [1] : false ||
    (length(var.aks_subnet_ids) == 2) ? [2] : []
  )
}