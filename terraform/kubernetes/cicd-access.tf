data "terraform_remote_state" "cicd" {
  backend = "http"

  config = {
    address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/cicd"
  }
}

# Local accounts are disabled on the cluster, so the pipeline reaches the API
# server through Entra ID only. Both roles are scoped to this cluster, not to
# the resource group.
resource "azurerm_role_assignment" "cicd_cluster_user" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = data.terraform_remote_state.cicd.outputs.service_principal_object_id
}

# Installing Argo CD and Velero creates CRDs and cluster roles, which no
# namespace-scoped role can grant.
resource "azurerm_role_assignment" "cicd_rbac_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.terraform_remote_state.cicd.outputs.service_principal_object_id
}
