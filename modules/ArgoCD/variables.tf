# variables.tf
variable "aks_name" {
  type        = string
  description = "The name of the AKS cluster where ArgoCD will be deployed"

  validation {
    condition     = length(var.aks_name) > 0
    error_message = "AKS cluster name cannot be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the AKS cluster is located"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name cannot be empty."
  }
}

variable "argocd_config" {
  description = "ArgoCD configuration object"
  type = object({
    hostname                     = string
    ingress_class_name           = string
    redis_ha_enabled             = bool
    autoscaling_enabled          = bool
    argocd_notifications_enabled = bool
    cluster_issuer               = string
  })

}

variable "namespace" {
  type        = string
  description = "Name of the Kubernetes namespace where ArgoCD will be deployed"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "ingress_class_name" {
  type        = string
  description = "Ingress class name for ArgoCD ingress controller"
}

variable "argocd_chart_version" {
  type        = string
  default     = "7.6.8"
  description = "Version of the ArgoCD Helm chart to deploy"
}

variable "deploy_cert_manager" {
  type        = bool
  description = "Whether to deploy cert-manager"
}
variable "create_cluster_issuer" {
  type        = bool
  description = "Whether to create a ClusterIssuer resource"
}
variable "letsencrypt_email" {
  type        = string
  description = "Email address for Let's Encrypt notifications"
}
variable "cluster_issuer" {
  type        = string
  description = "The name of the ClusterIssuer to use for TLS certificates"

}
