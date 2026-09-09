#!/usr/bin/env bash

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

STACK_DIR="${TERRAFORM_DIR}/kubernetes"
MANIFEST_DIR="${PROJECT_ROOT}/manifests/database"
PLACEHOLDER="REPLACE_WITH_database_identity_client_id"

main() {
  step "Wiring the database manifests"
  load_env

  local client_id
  client_id="$(terraform -chdir="$STACK_DIR" output -raw database_identity_client_id 2>/dev/null || true)"
  [ -n "$client_id" ] ||
    die "database_identity_client_id is empty. Run: make apply STACK=kubernetes"

  local files
  files="$(grep -rl "$PLACEHOLDER" "$MANIFEST_DIR" || true)"
  if [ -z "$files" ]; then
    ok "manifests already wired"
    printf '\n'
    return
  fi

  while read -r file; do
    sed -i "s|${PLACEHOLDER}|${client_id}|g" "$file"
    ok "$(basename "$file")"
  done <<<"$files"

  warn "commit manifests/database/ so Argo CD sees the change"
  printf '\n'
}

main "$@"
