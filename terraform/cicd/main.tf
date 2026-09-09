data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azuread_client_config" "current" {}

resource "azuread_application" "gitlab" {
  display_name = var.application_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "gitlab" {
  client_id = azuread_application.gitlab.client_id
  owners    = [data.azuread_client_config.current.object_id]
}

resource "azuread_application_federated_identity_credential" "default_branch" {
  application_id = azuread_application.gitlab.id
  display_name   = "gitlab-${var.gitlab_default_branch}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = var.gitlab_issuer
  subject        = "project_path:${var.gitlab_project_path}:ref_type:branch:ref:${var.gitlab_default_branch}"
}

resource "azurerm_role_assignment" "contributor" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.gitlab.object_id
}

resource "azurerm_role_assignment" "rbac_administrator" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Role Based Access Control Administrator"
  principal_id         = azuread_service_principal.gitlab.object_id
}
