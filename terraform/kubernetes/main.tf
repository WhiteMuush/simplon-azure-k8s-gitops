data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

resource "azuread_group" "aks_admins" {
  display_name     = var.aks_admin_group_name
  description      = "Administrators of the ${var.cluster_name} AKS cluster."
  security_enabled = true
  members          = [data.azuread_client_config.current.object_id]
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  sku_tier = "Free"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  local_account_disabled = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = [azuread_group.aks_admins.object_id]
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = var.node_vm_size
    zones      = var.node_zones
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
