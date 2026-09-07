# Every target delegates to a script in scripts/. No shell logic lives here.

STACK ?=

.PHONY: help stacks status init fmt validate plan apply destroy output clean

help: ## Show this help
	@scripts/help.sh

stacks: ## List the available stacks
	@scripts/stacks.sh

status: ## Show what is deployed, per stack and in Azure
	@scripts/status.sh

init: ## Initialize the backend and download providers
	@scripts/tf.sh init "$(STACK)"

fmt: ## Rewrite every stack in canonical format
	@scripts/fmt.sh

validate: ## Check the stack is syntactically valid
	@scripts/tf.sh validate "$(STACK)"

plan: ## Init, format, validate, then show the planned changes
	@scripts/tf.sh plan "$(STACK)"

apply: ## Init, format, validate, then apply, asks for confirmation
	@scripts/tf.sh apply "$(STACK)"

destroy: ## Destroy the stack resources, asks for confirmation
	@scripts/tf.sh destroy "$(STACK)"

output: ## Print the stack outputs
	@scripts/tf.sh output "$(STACK)"

clean: ## Remove the local Terraform working directories
	@scripts/clean.sh
