#!/usr/bin/env bash
# List the available Terraform stacks.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

list_stacks
