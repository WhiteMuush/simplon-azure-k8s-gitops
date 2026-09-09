terraform {
  required_version = ">= 1.9"

  # GitLab-managed state. Credentials come from the environment at runtime.
  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/86169287/terraform/state/kubernetes"
    lock_address   = "https://gitlab.com/api/v4/projects/86169287/terraform/state/kubernetes/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/kubernetes/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}
