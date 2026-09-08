#!/usr/bin/env bash
# Install Argo CD and hand the cluster over to Git.
#
# Usage:
#   scripts/kubernetes/argocd.sh install   helm install, then apply the root app
#   scripts/kubernetes/argocd.sh status    show the applications and their sync state
#   scripts/kubernetes/argocd.sh ui        port-forward the UI and print the login
#   scripts/kubernetes/argocd.sh password  print the initial admin password

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

CHART_VERSION="10.8.2"
NAMESPACE="argocd"
MANIFESTS_DIR="${PROJECT_ROOT}/manifests/argocd"
UI_PORT="8080"

require_tools() {
  local tool
  for tool in helm kubectl; do
    command -v "$tool" >/dev/null || die "${tool} is missing."
  done
}

require_cluster() {
  kubectl cluster-info >/dev/null 2>&1 ||
    die "No cluster reachable. Run: make kubeconfig"
}

add_helm_repo() {
  helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
  helm repo update argo >/dev/null
}

install() {
  step "Installing Argo CD"
  require_tools
  require_cluster
  add_helm_repo

  helm upgrade --install argocd argo/argo-cd \
    --version "$CHART_VERSION" \
    --namespace "$NAMESPACE" --create-namespace \
    --values "${MANIFESTS_DIR}/values.yaml" \
    --wait --timeout 10m
  ok "chart ${CHART_VERSION} deployed"

  kubectl apply -f "${MANIFESTS_DIR}/root-app.yaml" >/dev/null
  ok "root application applied"
}

status() {
  require_tools
  require_cluster
  step "Applications"
  kubectl -n "$NAMESPACE" get applications \
    -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.spec.source.targetRevision
}

password() {
  require_cluster
  kubectl -n "$NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' 2>/dev/null | base64 -d ||
    die "No initial admin secret. It was deleted, or the password was changed."
  echo
}

ui() {
  require_tools
  require_cluster
  step "Argo CD UI"
  field "URL" "http://localhost:${UI_PORT}"
  field "User" "admin"
  field "Password" "$(password)"
  warn "Ctrl-C to stop the port-forward"
  kubectl -n "$NAMESPACE" port-forward svc/argocd-server "${UI_PORT}:80"
}

main() {
  case "${1:-}" in
    install) install ;;
    status) status ;;
    ui) ui ;;
    password) password ;;
    *) die "Usage: $0 <install|status|ui|password>" ;;
  esac
}

main "$@"
