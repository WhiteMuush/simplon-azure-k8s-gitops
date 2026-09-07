# Shares the account with the file share, so the Velero identity is scoped to
# this container and cannot read employee documents.
resource "azurerm_storage_container" "velero" {
  name                  = var.velero_container_name
  storage_account_id    = azurerm_storage_account.files.id
  container_access_type = "private"
}
