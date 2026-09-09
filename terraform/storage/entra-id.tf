data "terraform_remote_state" "identity" {
  backend = "http"

  config = {
    address = "https://gitlab.com/api/v4/projects/86169287/terraform/state/identity"
  }
}

resource "azurerm_role_assignment" "file_share_users" {
  scope                = azurerm_storage_account.files.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = data.terraform_remote_state.identity.outputs.file_share_group_object_id
}
