#!/usr/bin/env bash
# Fetch a kubeconfig for the AKS cluster and make kubectl able to use it.
#
# Usage: scripts/kubernetes/kubeconfig.sh

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

STACK_DIR="${TERRAFORM_DIR}/kubernetes"
INSTALL_DIR="${HOME}/.local/bin"

CLUSTER_NAME=""

read_output() {
  terraform -chdir="$STACK_DIR" output -raw "$1" 2>/dev/null
}

require_azure_session() {
  command -v az >/dev/null || die "The Azure CLI is missing."
  az account get-access-token --output none 2>/dev/null ||
    die "Not signed in. Run: az login"
}

# The cluster has local accounts disabled, so kubectl authenticates through
# kubelogin rather than a static admin certificate.
install_kubelogin() {
  if command -v kubelogin >/dev/null; then
    ok "kubelogin present"
    return
  fi
  mkdir -p "$INSTALL_DIR"
  az aks install-cli \
    --install-location "${INSTALL_DIR}/kubectl" \
    --kubelogin-install-location "${INSTALL_DIR}/kubelogin" >/dev/null 2>&1 ||
    die "Could not install kubelogin. Install it manually: https://azure.github.io/kubelogin/install.html"
  ok "kubelogin installed in ${INSTALL_DIR}"
  case ":$PATH:" in
    *":${INSTALL_DIR}:"*) ;;
    *) warn "add ${INSTALL_DIR} to your PATH" ;;
  esac
}

fetch_credentials() {
  local rg
  rg="$(terraform -chdir="$STACK_DIR" output -raw resource_group_name 2>/dev/null || echo "mpetitRG")"
  CLUSTER_NAME="$(read_output cluster_name || true)"
  [ -n "$CLUSTER_NAME" ] || die "cluster_name is empty. Run: make apply STACK=kubernetes"

  az aks get-credentials --resource-group "$rg" --name "$CLUSTER_NAME" --overwrite-existing >/dev/null
  ok "kubeconfig written for ${CLUSTER_NAME}"
}

# azurecli mode reuses the token az already holds, so no browser or device code.
convert_to_azurecli() {
  kubelogin convert-kubeconfig -l azurecli >/dev/null ||
    die "kubelogin could not convert the kubeconfig."
  ok "kubelogin set to azurecli mode"
}

verify_access() {
  kubectl get nodes -o wide 2>/dev/null ||
    die "kubectl cannot reach the cluster. Are you a member of the aks-admins group?"
}

main() {
  step "Configuring kubectl"
  load_env
  require_azure_session
  install_kubelogin
  fetch_credentials
  convert_to_azurecli
  step "Nodes of ${CLUSTER_NAME}"
  verify_access
}

main "$@"
