variable "subscription_id" {
  description = "Azure subscription the lab runs in, set through TF_VAR_subscription_id."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding every resource of this stack."
  type        = string
  default     = "mpetitRG"
}

variable "cluster_name" {
  description = "Name of the AKS cluster."
  type        = string
  default     = "mpetit-aks"
}

variable "kubernetes_version" {
  description = "AKS control plane version. Null tracks the region default."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes in the system pool."
  type        = number
  default     = 2
}

# Three independent gates decide what is deployable here, and all three had to
# be checked: the Azure Policy allow list, the SKU availability per zone, and
# the family quota. Standard_D2_v3 is the only size that clears all three with
# room to grow. Standard_D2s_v3 also clears them but its family has 2 vCPU left,
# which caps the cluster at a single node.
variable "node_vm_size" {
  description = "VM size of the system pool. Must be allowed by policy, available in the zone, and within the family quota."
  type        = string
  default     = "Standard_D2_v3"
}

# Zone 3 is NotAvailableForSubscription for this SKU in francecentral. Pinning
# the pool to zones 1 and 2 keeps AKS away from it.
variable "node_zones" {
  description = "Availability zones the system pool may use."
  type        = list(string)
  default     = ["1", "2"]
}

variable "aks_admin_group_name" {
  description = "Entra ID group whose members are cluster administrators."
  type        = string
  default     = "aks-admins"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}
