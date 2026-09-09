#!/usr/bin/env bash

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

STACK_DIR="${TERRAFORM_DIR}/kubernetes"
READY_TIMEOUT="${READY_TIMEOUT:-600s}"

RESOURCE_GROUP_NAME=""
CLUSTER_NAME=""

require_azure_session() {
  command -v az >/dev/null || die "The Azure CLI is missing."
  az account get-access-token --output none 2>/dev/null ||
    die "Not signed in. Run: az login"
}

read_output() {
  terraform -chdir="$STACK_DIR" output -raw "$1" 2>/dev/null
}

resolve_cluster() {
  RESOURCE_GROUP_NAME="$(read_output resource_group_name || echo "${RESOURCE_GROUP:-mpetitRG}")"
  CLUSTER_NAME="$(read_output cluster_name || true)"
  [ -n "$CLUSTER_NAME" ] ||
    CLUSTER_NAME="$(az aks list -g "$RESOURCE_GROUP_NAME" --query "[0].name" -o tsv 2>/dev/null || true)"
  [ -n "$CLUSTER_NAME" ] ||
    die "No AKS cluster in ${RESOURCE_GROUP_NAME}. Run: make apply STACK=kubernetes"
}

aks_field() {
  az aks show -g "$RESOURCE_GROUP_NAME" -n "$CLUSTER_NAME" --query "$1" -o tsv 2>/dev/null
}

wait_until_settled() {
  local state
  while true; do
    state="$(aks_field provisioningState)"
    case "$state" in
      Succeeded | Failed | "") return ;;
    esac
    warn "cluster is ${state}, waiting"
    sleep 30
  done
}

ready_nodes() {
  kubectl get nodes --no-headers 2>/dev/null | awk '$2 == "Ready"' | grep -c . || true
}

start_cluster() {
  az aks start -g "$RESOURCE_GROUP_NAME" -n "$CLUSTER_NAME" -o none ||
    die "Could not start ${CLUSTER_NAME}."
  ok "started"
}

revive_cluster() {
  warn "cluster reports Running but no node is Ready"
  az aks stop -g "$RESOURCE_GROUP_NAME" -n "$CLUSTER_NAME" -o none ||
    die "Could not stop ${CLUSTER_NAME}."
  ok "stopped"
  start_cluster
}

wake_cluster() {
  step "Waking ${CLUSTER_NAME}"
  wait_until_settled
  local power
  power="$(aks_field powerState.code)"
  case "$power" in
    Stopped) start_cluster ;;
    Running)
      if [ "$(ready_nodes)" -gt 0 ]; then
        ok "already up"
        return
      fi
      revive_cluster
      ;;
    *) die "Unexpected power state '${power}'." ;;
  esac
}

verify_nodes() {
  step "Nodes of ${CLUSTER_NAME}"
  command -v kubectl >/dev/null || {
    warn "kubectl is missing, run: make kubeconfig"
    return
  }
  kubectl wait --for=condition=Ready nodes --all --timeout="$READY_TIMEOUT" >/dev/null ||
    die "The nodes are still not Ready after ${READY_TIMEOUT}."
  kubectl get nodes -o wide
}

main() {
  load_env
  require_azure_session
  resolve_cluster
  wake_cluster
  verify_nodes
  printf '\n'
}

main "$@"
