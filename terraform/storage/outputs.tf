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

locals {
  smb_host = trimsuffix(trimprefix(azurerm_storage_account.files.primary_file_endpoint, "https://"), "/")
  smb_path = "${local.smb_host}/${azurerm_storage_share.documents.name}"
}

output "mount_commands" {
  value = {
    windows = "net use Z: \\\\${replace(local.smb_path, "/", "\\")}"
    macos   = "open smb://${local.smb_path}"
    linux   = "az login && STORAGE_ACCOUNT=${azurerm_storage_account.files.name} SHARE_NAME=${azurerm_storage_share.documents.name} scripts/storage/mount-file-share.sh"
  }
  description = "Commands employees run to mount the share, none of which carry a credential. Windows and macOS present an Entra ID Kerberos ticket over SMB, which needs an Entra joined device or Platform SSO. Linux has no Entra Kerberos client, so it trades the token for a Kerberos ticket through SMB OAuth instead. See the wiki page Mounting the file share on Linux."
}

output "storage_account_id" {
  value       = azurerm_storage_account.files.id
  description = "Resource ID of the storage account"
}

output "velero_container_name" {
  value       = azurerm_storage_container.velero.name
  description = "Blob container Velero writes backups to"
}

output "velero_container_id" {
  value       = "${azurerm_storage_account.files.id}/blobServices/default/containers/${azurerm_storage_container.velero.name}"
  description = "Resource ID of the Velero container, used as the RBAC scope"
}
