# Entra ID group granting employees access to the file shares
resource "azuread_group" "file_share_users" {
  display_name     = var.file_share_group_name
  description      = "Employees allowed to mount the corporate file shares over SMB."
  security_enabled = true
}

# Share level permission. NTFS permissions inside the share are still managed
# from a client that has mounted it.
resource "azurerm_role_assignment" "file_share_users" {
  scope                = azurerm_storage_account.files.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azuread_group.file_share_users.object_id
}
