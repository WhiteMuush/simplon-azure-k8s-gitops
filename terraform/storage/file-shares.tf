resource "azurerm_storage_share" "documents" {
  name               = "documents"
  storage_account_id = azurerm_storage_account.files.id
  quota              = 100    # Size in GiB
  access_tier        = "Cool" # Lower cost for infrequently accessed data
}
