terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.40.0"
    }
  }
}

provider "azurerm" {
  features {}
}



module "aks" {
  source              = "./modules/AKS"
  aks_name            = var.aks_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_name            = var.dns_name
}

module "argocd_dns" {
  source                      = "./modules/ArgoCD-DNS"
  cluster_name                = var.aks_name
  cluster_resource_group_name = var.resource_group_name
  dns_zone_name               = var.dns_name
  resource_group_name         = var.dnszone_resourcegroup_name
  record_name                 = replace(var.argocd_config["hostname"], "." + var.dns_name, "")
  namespace                   = var.namespace
  ttl                         = 300

}

module "argocd" {
  source                = "./modules/ArgoCD"
  resource_group_name   = var.resource_group_name
  aks_name              = var.aks_name
  namespace             = var.namespace
  ingress_class_name    = var.ingress_class_name
  argocd_config         = var.argocd_config
  deploy_cert_manager   = var.deploy_cert_manager
  create_cluster_issuer = var.create_cluster_issuer
  cluster_issuer        = var.cluster_issuer
  letsencrypt_email     = var.letsencrypt_email
}
