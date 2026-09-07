#!/usr/bin/env bash
# Run a Terraform action against one stack.
# Usage: scripts/tf.sh <init|validate|plan|apply|destroy|output> [stack]

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

action="${1:-}"
[ -n "$action" ] || die "Usage: $0 <init|validate|plan|apply|destroy|output> [stack]"

resolve_stack "${2:-}"
echo "==> stack: ${STACK_NAME}"
load_env

tf() {
  terraform -chdir="${TERRAFORM_DIR}/${STACK_NAME}" "$@"
}

# Every action that reaches a remote gets a fresh init first.
prepare() {
  tf init -reconfigure
  terraform fmt -recursive "$TERRAFORM_DIR"
  tf validate
}

case "$action" in
  init)     tf init -reconfigure ;;
  validate) tf validate ;;
  plan)     prepare && tf plan ;;
  apply)    prepare && tf apply ;;
  destroy)  tf destroy ;;
  output)   tf output ;;
  *)        die "Unknown action '${action}'." ;;
esac
