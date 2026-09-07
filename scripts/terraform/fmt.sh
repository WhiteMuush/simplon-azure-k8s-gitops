#!/usr/bin/env bash
# Rewrite every stack in canonical Terraform format.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

terraform fmt -recursive "$TERRAFORM_DIR"
