# Velero writes cluster backups here. It shares the storage account with the
# corporate file share, so the Velero identity is granted access to this
# container only, never to the account, and cannot reach the employee files.
resource "azurerm_storage_container" "velero" {
  name                  = var.velero_container_name
  storage_account_id    = azurerm_storage_account.files.id
  container_access_type = "private"
}
