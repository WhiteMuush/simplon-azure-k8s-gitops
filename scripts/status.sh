#!/usr/bin/env bash
# Show where every stack stands and what is actually running in Azure.
# Read-only: it never plans, applies or changes anything.
#
# Usage: scripts/status.sh

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# ----------------------------------------------------------------- azure ----

show_azure_context() {
  step "Azure"
  if ! az account show >/dev/null 2>&1; then
    warn "not signed in, run: az login"
    return
  fi
  field "Subscription" "$(az account show --query name -o tsv)"
  field "Identity" "$(az account show --query user.name -o tsv)"
  show_resource_group
}

show_resource_group() {
  local rg="${RESOURCE_GROUP:-mpetitRG}"
  local location
  location="$(az group show -n "$rg" --query location -o tsv 2>/dev/null || echo "")"
  if [ -z "$location" ]; then
    warn "resource group ${rg} not found"
    return
  fi
  field "Resource group" "${rg} (${location})"
}

# ---------------------------------------------------------------- stacks ----

show_stacks() {
  step "Stacks"
  local stack
  while read -r stack; do
    show_stack "$stack"
  done < <(list_stacks)
}

show_stack() {
  local stack="$1"
  local count
  count="$(count_state_resources "$stack")"
  case "$count" in
    unreachable) field "$stack" "state unreachable, check .env" ;;
    0) field "$stack" "not deployed" ;;
    *) field "$stack" "${count} resources" ;;
  esac
}

# terraform state list needs an initialized backend, so init quietly first.
count_state_resources() {
  local stack="$1"
  local dir="${TERRAFORM_DIR}/${stack}"
  terraform -chdir="$dir" init -reconfigure -input=false >/dev/null 2>&1 ||
    {
      echo "unreachable"
      return
    }
  # grep -c prints 0 and exits 1 on an empty state, so swallow the status.
  terraform -chdir="$dir" state list 2>/dev/null | grep -c . || true
}

# -------------------------------------------------------------- workloads ----

show_workloads() {
  az account show >/dev/null 2>&1 || return 0
  step "Running in ${RESOURCE_GROUP:-mpetitRG}"
  local found=0
  show_storage_accounts && found=1
  show_clusters && found=1
  [ "$found" -eq 1 ] || warn "no resource deployed yet"
}

show_storage_accounts() {
  local rg="${RESOURCE_GROUP:-mpetitRG}"
  local name
  name="$(az storage account list -g "$rg" --query "[0].name" -o tsv 2>/dev/null || echo "")"
  [ -n "$name" ] || return 1
  field "Storage account" "$name"
  return 0
}

# The power state matters for cost: a stopped cluster bills nothing for nodes.
show_clusters() {
  local rg="${RESOURCE_GROUP:-mpetitRG}"
  local clusters
  clusters="$(az aks list -g "$rg" \
    --query "[].{name:name,power:powerState.code,nodes:agentPoolProfiles[0].count,version:kubernetesVersion}" \
    -o tsv 2>/dev/null || echo "")"
  [ -n "$clusters" ] || return 1
  local name power nodes version
  while IFS=$'\t' read -r name power nodes version; do
    field "AKS cluster" "${name}  ${power}, ${nodes} node(s), v${version}"
  done <<<"$clusters"
  return 0
}

main() {
  show_azure_context
  show_stacks
  show_workloads
  printf '\n'
}

main "$@"
