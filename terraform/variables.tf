# ============================================================
# variables.tf — Input variables for the infrastructure
# ============================================================

variable "project_name" {
  description = "Name prefix for all Azure resources"
  type        = string
  default     = "cicd-demo"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "aks_node_count" {
  description = "Number of nodes in the AKS default node pool"
  type        = number
  default     = 2
}

variable "aks_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    project     = "cicd-demo"
    environment = "dev"
    managed_by  = "terraform"
  }
}
