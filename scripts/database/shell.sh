#!/usr/bin/env bash
# Open a psql session on the database pod.
#
# Usage:
#   scripts/database/shell.sh          interactive session
#   scripts/database/shell.sh -c 'sql' run one statement and exit

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

NAMESPACE="database"
POD="postgres-0"
DB_USER="notes"
DB_NAME="notes"

require_cluster() {
  command -v kubectl >/dev/null || die "kubectl is missing."
  kubectl cluster-info >/dev/null 2>&1 ||
    die "No cluster reachable. Run: make kubeconfig"
}

require_pod() {
  kubectl -n "$NAMESPACE" get pod "$POD" >/dev/null 2>&1 ||
    die "Pod ${POD} not found in ${NAMESPACE}. Check: make argocd-status"

  local phase
  phase="$(kubectl -n "$NAMESPACE" get pod "$POD" -o jsonpath='{.status.phase}')"
  [ "$phase" = "Running" ] || die "Pod ${POD} is in phase ${phase}, not Running."
}

main() {
  require_cluster
  require_pod
  # -it only when a terminal is attached, so the target stays usable in a pipe.
  local flags="-i"
  [ -t 0 ] && flags="-it"
  kubectl -n "$NAMESPACE" exec "$flags" "$POD" -- psql -U "$DB_USER" -d "$DB_NAME" "$@"
}

main "$@"
