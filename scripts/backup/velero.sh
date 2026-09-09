#!/usr/bin/env bash
# Install Velero on the cluster and drive backups.
#
# Usage:
#   scripts/backup/velero.sh install   helm install, wired to the Terraform outputs
#   scripts/backup/velero.sh demo      deploy the namespace this backup protects
#   scripts/backup/velero.sh backup    run one backup now
#   scripts/backup/velero.sh status    show backup locations, schedules and backups
#   scripts/backup/velero.sh restore   delete the demo namespace and restore it

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

CHART_VERSION="12.1.0"
NAMESPACE="velero"
DEMO_NAMESPACE="demo"
MANIFESTS_DIR="${PROJECT_ROOT}/manifests"
STACK_DIR="${TERRAFORM_DIR}/kubernetes"

read_output() {
  terraform -chdir="$STACK_DIR" output -raw "$1" 2>/dev/null
}

require_tools() {
  local tool
  for tool in helm kubectl; do
    command -v "$tool" >/dev/null || die "${tool} is missing."
  done
}

# The pipeline reads the value from the Terraform state once and exports it, so
# the deploy job needs no Terraform binary and no state credentials.
resolve_client_id() {
  if [ -n "${VELERO_IDENTITY_CLIENT_ID:-}" ]; then
    echo "$VELERO_IDENTITY_CLIENT_ID"
    return
  fi
  command -v terraform >/dev/null ||
    die "terraform is missing. Set VELERO_IDENTITY_CLIENT_ID to skip it."
  read_output velero_identity_client_id
}

require_cluster() {
  kubectl cluster-info >/dev/null 2>&1 ||
    die "No cluster reachable. Run: make kubeconfig"
}

add_helm_repo() {
  helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts >/dev/null 2>&1 || true
  helm repo update vmware-tanzu >/dev/null
}

install() {
  step "Installing Velero"
  require_tools
  load_env
  require_cluster
  add_helm_repo

  local client_id
  client_id="$(resolve_client_id)"
  [ -n "$client_id" ] ||
    die "velero_identity_client_id is empty. Run: make apply STACK=kubernetes"

  helm upgrade --install velero vmware-tanzu/velero \
    --version "$CHART_VERSION" \
    --namespace "$NAMESPACE" --create-namespace \
    --values "${MANIFESTS_DIR}/velero/values.yaml" \
    --set "serviceAccount.server.annotations.azure\\.workload\\.identity/client-id=${client_id}" \
    --wait
  ok "chart ${CHART_VERSION} deployed"

  kubectl apply -f "${MANIFESTS_DIR}/velero/backup-schedule.yaml" >/dev/null
  ok "backup schedule applied"
}

demo() {
  step "Deploying the demo namespace"
  require_tools
  require_cluster
  # kubectl applies a directory in alphabetical order, so the namespace has to
  # be created on its own before the objects that live in it.
  kubectl apply -f "${MANIFESTS_DIR}/demo/namespace.yaml" >/dev/null
  kubectl apply -f "${MANIFESTS_DIR}/demo/" >/dev/null
  kubectl -n "$DEMO_NAMESPACE" rollout status deployment/notes --timeout=180s
  seed_demo_data
}

seed_demo_data() {
  local pod
  pod="$(kubectl -n "$DEMO_NAMESPACE" get pod -l app=notes -o name | head -1)"
  # shellcheck disable=SC2016  # the date must run inside the container
  kubectl -n "$DEMO_NAMESPACE" exec "$pod" -- \
    sh -c 'echo "backed up at $(date -u)" > /usr/share/nginx/html/index.html'
  ok "seeded $(kubectl -n "$DEMO_NAMESPACE" exec "$pod" -- cat /usr/share/nginx/html/index.html)"
}

require_demo_namespace() {
  kubectl get namespace "$DEMO_NAMESPACE" >/dev/null 2>&1 ||
    die "Namespace ${DEMO_NAMESPACE} does not exist. Run: make velero-demo"
}

backup() {
  step "Running a backup"
  require_tools
  require_cluster
  require_demo_namespace
  local name
  name="manual-$(date -u '+%Y%m%d-%H%M%S')"
  kubectl -n "$NAMESPACE" create -f - >/dev/null <<EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: ${name}
  namespace: ${NAMESPACE}
spec:
  includedNamespaces:
    - ${DEMO_NAMESPACE}
  defaultVolumesToFsBackup: true
  ttl: 168h
EOF
  ok "backup ${name} created"
  wait_for_backup "$name"
}

wait_for_backup() {
  local name="$1" phase=""
  for _ in $(seq 1 60); do
    phase="$(kubectl -n "$NAMESPACE" get backup "$name" -o jsonpath='{.status.phase}' 2>/dev/null)"
    case "$phase" in
      Completed) ok "phase Completed"; return 0 ;;
      Failed | PartiallyFailed)
        die "backup ended in phase ${phase}. Details: kubectl -n ${NAMESPACE} describe backup ${name}"
        ;;
    esac
    sleep 5
  done
  warn "still in phase ${phase:-unknown} after 5 minutes"
}

status() {
  require_tools
  require_cluster
  step "Backup storage locations"
  kubectl -n "$NAMESPACE" get backupstoragelocation
  step "Schedules"
  kubectl -n "$NAMESPACE" get schedule
  step "Backups"
  kubectl -n "$NAMESPACE" get backup
}

# The only test that proves a backup: destroy, restore, compare.
restore() {
  step "Restoring the demo namespace"
  require_tools
  require_cluster
  local latest
  latest="$(kubectl -n "$NAMESPACE" get backup \
    -o jsonpath='{range .items[?(@.status.phase=="Completed")]}{.metadata.name}{"\n"}{end}' |
    sort | tail -1)"
  [ -n "$latest" ] || die "No completed backup to restore from."
  ok "restoring from ${latest}"

  kubectl delete namespace "$DEMO_NAMESPACE" --wait >/dev/null
  ok "namespace ${DEMO_NAMESPACE} deleted"

  local name
  name="restore-$(date -u '+%Y%m%d-%H%M%S')"
  kubectl -n "$NAMESPACE" create -f - >/dev/null <<EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: ${name}
  namespace: ${NAMESPACE}
spec:
  backupName: ${latest}
EOF
  wait_for_restore "$name"
  kubectl -n "$DEMO_NAMESPACE" rollout status deployment/notes --timeout=300s
  seed_check
}

wait_for_restore() {
  local name="$1" phase=""
  for _ in $(seq 1 60); do
    phase="$(kubectl -n "$NAMESPACE" get restore "$name" -o jsonpath='{.status.phase}' 2>/dev/null)"
    case "$phase" in
      Completed)
        ok "restore Completed"
        return 0
        ;;
      Failed | PartiallyFailed)
        die "restore ended in phase ${phase}. Details: kubectl -n ${NAMESPACE} describe restore ${name}"
        ;;
    esac
    sleep 5
  done
  warn "still in phase ${phase:-unknown} after 5 minutes"
}

seed_check() {
  local pod
  pod="$(kubectl -n "$DEMO_NAMESPACE" get pod -l app=notes -o name | head -1)"
  field "Restored content" "$(kubectl -n "$DEMO_NAMESPACE" exec "$pod" -- cat /usr/share/nginx/html/index.html)"
}

main() {
  case "${1:-}" in
    install) install ;;
    demo) demo ;;
    backup) backup ;;
    status) status ;;
    restore) restore ;;
    *) die "Usage: $0 <install|demo|backup|status|restore>" ;;
  esac
}

main "$@"
