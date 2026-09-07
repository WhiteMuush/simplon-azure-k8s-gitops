terraform {
  required_version = ">= 1.9"

  # State is stored in the GitLab-managed Terraform state backend of this
  # project (WhiteMuush/simplon-azure-k8s-gitops, id 86169287). Credentials are
  # injected at runtime, so nothing secret is committed here.
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/86169287/terraform/state/storage"
    lock_address   = "https://gitlab.com/api/v4/projects/86169287/terraform/state/storage/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/storage/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}
