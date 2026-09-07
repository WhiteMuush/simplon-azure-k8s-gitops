provider "azurerm" {
  features {}

  subscription_id = var.subscription_id

  # Required because the account key is disabled.
  storage_use_azuread = true
}

provider "azuread" {}
