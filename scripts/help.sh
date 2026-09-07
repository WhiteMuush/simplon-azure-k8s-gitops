#!/usr/bin/env bash
# Print the Makefile targets and their descriptions.

# shellcheck source=scripts/lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

echo "Usage: make <target> [STACK=<name>]"
echo "Without STACK, targets ask which stack to use."
grep -E '^[a-z-]+:.*?## ' "${PROJECT_ROOT}/Makefile" |
  awk -F':.*?## ' '{printf "  \033[36m%-10s\033[0m %s\n", $1, $2}'
