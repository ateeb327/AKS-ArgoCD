terraform {
  required_version = ">= 1.1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.32"
    }
  }
}

provider "azurerm" {
  features {}
}

# Get AKS Cluster details
data "azurerm_kubernetes_cluster" "primary" {
  name                = var.cluster_name
  resource_group_name = var.cluster_resource_group_name
}

# Configure Kubernetes Provider with proper authentication
provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.primary.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.primary.kube_config[0].cluster_ca_certificate)
}

# Get the DNS Zone details
data "azurerm_dns_zone" "this" {
  name                = var.dns_zone_name
  resource_group_name = var.resource_group_name
}

# Wait for the ArgoCD service to get an external IP
data "kubernetes_service" "argocd_server" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }
}

# Create the DNS A record only if LoadBalancer IP is available
resource "azurerm_dns_a_record" "argocd" {

  name                = var.record_name
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = data.azurerm_dns_zone.this.resource_group_name
  ttl                 = var.ttl
  records = [
    try(data.kubernetes_service.argocd_server.status[0].load_balancer[0].ingress[0].ip, "")
  ]


}
