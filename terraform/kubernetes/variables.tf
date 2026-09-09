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

variable "node_vm_size" {
  description = "VM size of the system pool. Must be allowed by policy, available in the zone, and within the family quota."
  type        = string
  default     = "Standard_D2_v3"
}

variable "node_zones" {
  description = "Availability zones the system pool may use."
  type        = list(string)
  default     = ["1", "2"]
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}

variable "velero_identity_name" {
  description = "User assigned identity Velero uses to write backups."
  type        = string
  default     = "velero"
}

variable "velero_namespace" {
  description = "Namespace Velero runs in."
  type        = string
  default     = "velero"
}

variable "velero_service_account" {
  description = "Service account Velero runs as, federated to the identity."
  type        = string
  default     = "velero"
}

variable "key_vault_name" {
  description = "Key Vault holding the database password. The name is globally unique."
  type        = string
  default     = "mpetit-kv-prod2026"
}

variable "database_identity_name" {
  description = "User assigned identity PostgreSQL uses to read its password."
  type        = string
  default     = "database"
}

variable "database_namespace" {
  description = "Namespace the database runs in."
  type        = string
  default     = "database"
}

variable "database_service_account" {
  description = "Service account the database runs as, federated to the identity."
  type        = string
  default     = "postgres"
}

variable "database_secret_name" {
  description = "Name of the Key Vault secret holding the PostgreSQL password."
  type        = string
  default     = "postgres-password"
}
