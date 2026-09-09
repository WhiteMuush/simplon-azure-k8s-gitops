resource "azuread_group" "file_share_users" {
  display_name     = var.file_share_group_name
  description      = "Employees allowed to mount the corporate file shares over SMB."
  security_enabled = true
}

resource "azuread_group" "aks_admins" {
  display_name     = var.aks_admin_group_name
  description      = "Administrators of the ${var.cluster_name} AKS cluster."
  security_enabled = true
  members          = var.aks_admin_object_ids
}
