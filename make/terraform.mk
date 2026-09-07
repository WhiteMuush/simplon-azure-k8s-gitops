##@ Terraform

.PHONY: stacks status init fmt validate plan apply destroy output clean

stacks: ## List the available stacks
	@scripts/terraform/stacks.sh

status: ## Show what is deployed, per stack and in Azure
	@scripts/status.sh

init: ## Initialize the backend and download providers
	@scripts/terraform/tf.sh init "$(STACK)"

fmt: ## Rewrite every stack in canonical format
	@scripts/terraform/fmt.sh

validate: ## Check the stack is syntactically valid
	@scripts/terraform/tf.sh validate "$(STACK)"

plan: ## Init, format, validate, then show the planned changes
	@scripts/terraform/tf.sh plan "$(STACK)"

apply: ## Init, format, validate, then apply, asks for confirmation
	@scripts/terraform/tf.sh apply "$(STACK)"

destroy: ## Destroy the stack resources, asks for confirmation
	@scripts/terraform/tf.sh destroy "$(STACK)"

output: ## Print the stack outputs
	@scripts/terraform/tf.sh output "$(STACK)"

clean: ## Remove the local Terraform working directories
	@scripts/terraform/clean.sh
