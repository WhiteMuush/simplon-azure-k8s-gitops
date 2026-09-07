output "resource_group_name" {
  value       = data.azurerm_resource_group.main.name
  description = "Name of the resource group"
}

output "storage_account_name" {
  value       = azurerm_storage_account.files.name
  description = "Name of the storage account"
}

output "file_share_group_object_id" {
  value       = azuread_group.file_share_users.object_id
  description = "Object ID of the Entra ID group allowed to mount the shares"
}

output "file_share_url" {
  value       = "${azurerm_storage_account.files.primary_file_endpoint}${azurerm_storage_share.documents.name}"
  description = "URL of the corporate file share"
}
