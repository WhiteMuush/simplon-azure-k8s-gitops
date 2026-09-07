data "terraform_remote_state" "storage" {
  backend = "http"

  config = {
    address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/storage"
  }
}

resource "azurerm_user_assigned_identity" "velero" {
  name                = var.velero_identity_name
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  tags                = var.tags
}

# Ties the identity to the Velero service account, so no secret is stored in the
# cluster. The subject must match the namespace and service account exactly.
resource "azurerm_federated_identity_credential" "velero" {
  name                      = "velero"
  user_assigned_identity_id = azurerm_user_assigned_identity.velero.id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = azurerm_kubernetes_cluster.main.oidc_issuer_url
  subject                   = "system:serviceaccount:${var.velero_namespace}:${var.velero_service_account}"
}

# Scoped to the container, not the storage account, so backups cannot reach the
# corporate file share sharing that account.
resource "azurerm_role_assignment" "velero_backup" {
  scope                = data.terraform_remote_state.storage.outputs.velero_container_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.velero.principal_id
}
