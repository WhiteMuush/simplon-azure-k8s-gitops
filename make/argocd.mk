##@ ArgoCD

.PHONY: argocd-install argocd-status argocd-ui argocd-password

argocd-install: ## Install Argo CD and apply the root application
	@scripts/kubernetes/argocd.sh install

argocd-status: ## Show the applications and their sync state
	@scripts/kubernetes/argocd.sh status

argocd-ui: ## Port-forward the Argo CD UI and print the login
	@scripts/kubernetes/argocd.sh ui

argocd-password: ## Print the initial admin password
	@scripts/kubernetes/argocd.sh password
