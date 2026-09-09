##@ Database

.PHONY: db-secret db-rotate db-wire db-shell

db-secret: ## Generate the PostgreSQL password in the Key Vault if missing
	@scripts/database/secret.sh

db-rotate: ## Replace the PostgreSQL password in the Key Vault
	@scripts/database/secret.sh --rotate

db-wire: ## Write the database identity client ID into the manifests
	@scripts/database/wire.sh

db-shell: ## Open a psql session on the database pod
	@scripts/database/shell.sh
