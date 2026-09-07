# Standard storage account for SMB file shares
resource "azurerm_storage_account" "files" {
  name                     = var.storage_account_name
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  # Enable large file shares (up to 100 TiB per share)
  large_file_share_enabled = true

  # Employees authenticate with their Entra ID account over SMB. Account keys
  # are disabled so no shared credential can be used or leaked.
  shared_access_key_enabled = false

  azure_files_authentication {
    directory_type = "AADKERB"
  }

  tags = var.tags
}
