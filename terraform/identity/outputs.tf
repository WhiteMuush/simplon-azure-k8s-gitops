output "file_share_group_object_id" {
  value       = azuread_group.file_share_users.object_id
  description = "Object ID of the Entra ID group allowed to mount the shares"
}

output "aks_admin_group_object_id" {
  value       = azuread_group.aks_admins.object_id
  description = "Object ID of the Entra ID group holding cluster administrators"
}
