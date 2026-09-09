terraform {
  required_version = ">= 1.9"

  backend "http" {
    address        = "https://gitlab.com/api/v4/projects/86169287/terraform/state/identity"
    lock_address   = "https://gitlab.com/api/v4/projects/86169287/terraform/state/identity/lock"
    unlock_address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/identity/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }

  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}
