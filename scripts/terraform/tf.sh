#!/usr/bin/env bash
# Run a Terraform action against one stack.
# Usage: scripts/tf.sh <init|validate|plan|apply|destroy|output> [stack]

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

USAGE="Usage: $0 <init|validate|plan|apply|destroy|output> [stack]"

tf() {
  terraform -chdir="${TERRAFORM_DIR}/${STACK_NAME}" "$@"
}

# Everything an action needs before it can touch a remote: a fresh backend, a
# formatted tree, and a configuration that parses.
prepare_stack() {
  tf init -reconfigure
  terraform fmt -recursive "$TERRAFORM_DIR"
  tf validate
}

select_stack() {
  local requested="${1:-}"
  resolve_stack "$requested"
  echo "==> stack: ${STACK_NAME}"
  load_env
}

run_action() {
  local action="$1"
  case "$action" in
    init) tf init -reconfigure ;;
    validate) tf validate ;;
    plan) prepare_stack && tf plan ;;
    apply) prepare_stack && tf apply ;;
    destroy) tf destroy ;;
    output) tf output ;;
    *) die "Unknown action '${action}'. ${USAGE}" ;;
  esac
}

main() {
  local action="${1:-}"
  [ -n "$action" ] || die "$USAGE"
  select_stack "${2:-}"
  run_action "$action"
}

main "$@"
