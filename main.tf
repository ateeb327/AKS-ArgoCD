terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.40.0"
    }
  }
}



module "aks" {
  source              = "../modules/AKS"
  resource_group_name = var.resource_group_name
  name                = var.aks_name
  location            = var.location
  dns_name            = var.dns_name
}
