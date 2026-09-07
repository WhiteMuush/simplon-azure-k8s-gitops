variable "subscription_id" {
  description = "Azure subscription the lab runs in, set through TF_VAR_subscription_id."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group holding every resource of this stack."
  type        = string
  default     = "mpetitRG"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "francecentral"
}

variable "storage_account_name" {
  description = "Storage account holding the SMB shares. Must be globally unique, 3 to 24 lowercase alphanumeric characters."
  type        = string
  default     = "mpfilesprod2026"

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "The storage account name must be 3 to 24 lowercase alphanumeric characters."
  }
}

variable "file_share_group_name" {
  description = "Entra ID group whose members get read and write access to the shares."
  type        = string
  default     = "file-share-users"
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    environment = "production"
    managed_by  = "terraform"
  }
}

variable "velero_container_name" {
  description = "Blob container holding the Kubernetes backups written by Velero."
  type        = string
  default     = "velero"
}
