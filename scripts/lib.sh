#!/usr/bin/env bash
# Shared helpers for the scripts in this directory. Meant to be sourced.

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
ENV_FILE="${PROJECT_ROOT}/.env"

# Set by resolve_stack, read by the callers.
export STACK_NAME=""

die() {
  echo "$*" >&2
  exit 1
}

list_stacks() {
  [ -d "$TERRAFORM_DIR" ] || die "No terraform/ directory at the project root."
  find "$TERRAFORM_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
}

# Set STACK_NAME to the stack to act on. Uses $1 when given, the only stack
# when there is one, and asks otherwise. Refuses to guess outside a terminal.
resolve_stack() {
  local requested="${1:-}"
  local -a stacks
  mapfile -t stacks < <(list_stacks)

  if [ -n "$requested" ]; then
    [ -d "${TERRAFORM_DIR}/${requested}" ] ||
      die "Unknown stack '${requested}'. Run 'make stacks' to list them."
    STACK_NAME="$requested"
    return
  fi

  case "${#stacks[@]}" in
    0) die "No stack found under terraform/." ;;
    1) STACK_NAME="${stacks[0]}"; return ;;
  esac

  [ -t 0 ] ||
    die "Several stacks available. Run with STACK=<name>, see 'make stacks'."

  local choice
  PS3="Which stack? "
  select choice in "${stacks[@]}"; do
    if [ -n "${choice:-}" ]; then
      STACK_NAME="$choice"
      return
    fi
  done
}

load_env() {
  [ -f "$ENV_FILE" ] ||
    die "Missing .env at the project root. See docs/RUNBOOK.md."
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
}
