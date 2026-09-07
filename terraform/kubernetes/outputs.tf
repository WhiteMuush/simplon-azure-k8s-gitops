output "cluster_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = "Name of the AKS cluster"
}

output "node_resource_group" {
  value       = azurerm_kubernetes_cluster.main.node_resource_group
  description = "Resource group Azure creates for the cluster nodes"
}

# Velero needs no secret.
output "oidc_issuer_url" {
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
  description = "OIDC issuer URL of the cluster"
}

output "kubeconfig_command" {
  value       = "az aks get-credentials --resource-group ${data.azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
  description = "Command to fetch a kubeconfig for this cluster"
}

output "aks_admin_group_object_id" {
  value       = azuread_group.aks_admins.object_id
  description = "Object ID of the Entra ID group holding cluster administrators"
}
