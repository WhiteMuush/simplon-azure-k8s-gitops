STACK ?=

include make/terraform.mk
include make/kubernetes.mk
include make/velero.mk

##@ General

.PHONY: help
help: ## Show this help
	@scripts/help.sh
