##@ Backup

.PHONY: velero-install velero-demo velero-backup velero-status velero-restore

velero-install: ## Install Velero on the cluster
	@scripts/backup/velero.sh install

velero-demo: ## Deploy the namespace the backup protects
	@scripts/backup/velero.sh demo

velero-backup: ## Run one backup now
	@scripts/backup/velero.sh backup

velero-status: ## Show backup locations, schedules and backups
	@scripts/backup/velero.sh status

velero-restore: ## Delete the demo namespace and restore it from the last backup
	@scripts/backup/velero.sh restore
