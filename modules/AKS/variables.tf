variable "aks_name" {}
variable "location" {}
variable "dns_name" {}
variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {}

