#!/usr/bin/env bash
# Remove the local Terraform working directories.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

find "$TERRAFORM_DIR" -mindepth 2 -maxdepth 2 -type d -name .terraform -exec rm -rf {} +
