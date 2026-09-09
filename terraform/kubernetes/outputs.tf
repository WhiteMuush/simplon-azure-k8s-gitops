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
  value       = local.aks_admin_group_object_id
  description = "Object ID of the Entra ID group holding cluster administrators"
}

output "velero_identity_client_id" {
  value       = azurerm_user_assigned_identity.velero.client_id
  description = "Client ID annotated on the Velero service account"
}

output "velero_backup_storage_account" {
  value       = data.terraform_remote_state.storage.outputs.storage_account_name
  description = "Storage account holding the backup container"
}

output "velero_backup_container" {
  value       = data.terraform_remote_state.storage.outputs.velero_container_name
  description = "Blob container Velero writes backups to"
}

output "key_vault_name" {
  value       = azurerm_key_vault.main.name
  description = "Key Vault holding the database password"
}

output "tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Tenant the Key Vault belongs to, referenced by the SecretProviderClass"
}

output "database_identity_client_id" {
  value       = azurerm_user_assigned_identity.database.client_id
  description = "Client ID annotated on the database service account"
}

output "database_secret_name" {
  value       = var.database_secret_name
  description = "Key Vault secret the database reads its password from"
}
