provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # Reach the storage data plane with the caller's Entra ID identity instead of
  # an account key, so shared_access_key_enabled can stay false.
  storage_use_azuread = true
}

provider "azuread" {}
