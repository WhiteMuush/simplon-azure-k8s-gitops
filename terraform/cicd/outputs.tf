output "arm_client_id" {
  value       = azuread_application.gitlab.client_id
  description = "Set as the ARM_CLIENT_ID CI/CD variable"
}

output "arm_tenant_id" {
  value       = data.azuread_client_config.current.tenant_id
  description = "Set as the ARM_TENANT_ID CI/CD variable"
}

output "arm_subscription_id" {
  value       = var.subscription_id
  description = "Set as the ARM_SUBSCRIPTION_ID CI/CD variable"
}

output "federated_subject" {
  value       = azuread_application_federated_identity_credential.default_branch.subject
  description = "Subject Entra ID expects in the GitLab OIDC token"
}
