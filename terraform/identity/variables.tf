variable "file_share_group_name" {
  description = "Entra ID group whose members get read and write access to the shares."
  type        = string
  default     = "file-share-users"
}

variable "aks_admin_group_name" {
  description = "Entra ID group whose members are cluster administrators."
  type        = string
  default     = "aks-admins"
}

variable "cluster_name" {
  description = "Cluster the administrator group is named after, used in its description."
  type        = string
  default     = "mpetit-aks"
}

variable "aks_admin_object_ids" {
  description = "Entra ID object IDs made members of the cluster administrator group."
  type        = list(string)
  default     = ["a8530703-e121-4db0-a7ec-3fd78c1d7205"]
}
