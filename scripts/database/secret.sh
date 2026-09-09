#!/usr/bin/env bash

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

STACK_DIR="${TERRAFORM_DIR}/kubernetes"

VAULT_NAME=""
SECRET_NAME=""

read_output() {
  terraform -chdir="$STACK_DIR" output -raw "$1" 2>/dev/null
}

require_azure_session() {
  command -v az >/dev/null || die "The Azure CLI is missing."
  az account get-access-token --output none 2>/dev/null ||
    die "Not signed in. Run: az login"
}

resolve_vault() {
  VAULT_NAME="$(read_output key_vault_name || true)"
  SECRET_NAME="$(read_output database_secret_name || echo "postgres-password")"
  [ -n "$VAULT_NAME" ] ||
    die "key_vault_name is empty. Run: make apply STACK=kubernetes"
}

secret_exists() {
  az keyvault secret show --vault-name "$VAULT_NAME" --name "$SECRET_NAME" \
    --query id -o tsv >/dev/null 2>&1
}

generate_password() {
  openssl rand -base64 32 | tr -d '\n/+=' | cut -c1-32
}

store_password() {
  local password
  password="$(generate_password)"
  az keyvault secret set --vault-name "$VAULT_NAME" --name "$SECRET_NAME" \
    --value "$password" --output none ||
    die "Could not write ${SECRET_NAME}. Are you Key Vault Secrets Officer on ${VAULT_NAME}?"
  ok "${SECRET_NAME} stored in ${VAULT_NAME}"
}

main() {
  local rotate="${1:-}"
  step "Database password"
  load_env
  require_azure_session
  resolve_vault

  if secret_exists && [ "$rotate" != "--rotate" ]; then
    ok "${SECRET_NAME} already set, pass --rotate to replace it"
  else
    store_password
    [ "$rotate" = "--rotate" ] &&
      warn "restart the database to pick it up: kubectl rollout restart statefulset/postgres -n database"
  fi
  printf '\n'
}

main "$@"
