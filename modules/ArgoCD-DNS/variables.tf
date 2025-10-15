# variables.tf
variable "resource_group_name" {
  type        = string
  description = "Resource group name containing the DNS zone"

  validation {
    condition     = length(var.resource_group_name) > 0
    error_message = "Resource group name cannot be empty."
  }
}

variable "dns_zone_name" {
  type        = string
  description = "Name of the DNS zone"
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.dns_zone_name))
    error_message = "The DNS zone name must be a valid domain (e.g., example.com)."
  }
}

variable "record_name" {
  type        = string
  description = "Name of the DNS record (subdomain)"

  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?$", var.record_name))
    error_message = "Record name must be a valid DNS subdomain name."
  }
}

variable "namespace" {
  type        = string
  default     = "argocd"
  description = "Kubernetes namespace where ArgoCD is deployed"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace must be a valid Kubernetes namespace name."
  }
}

variable "ttl" {
  type        = number
  default     = 300
  description = "TTL for DNS record in seconds"

  validation {
    condition     = var.ttl >= 60 && var.ttl <= 86400
    error_message = "TTL must be between 60 and 86400 seconds."
  }
}

variable "cluster_name" {
  type        = string
  description = "Name of the AKS cluster"

  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "Cluster name cannot be empty."
  }
}

variable "cluster_resource_group_name" {
  type        = string
  description = "Resource group name containing the AKS cluster"

  validation {
    condition     = length(var.cluster_resource_group_name) > 0
    error_message = "Cluster resource group name cannot be empty."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to the DNS record"
}
