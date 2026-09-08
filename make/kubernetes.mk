##@ Kubernetes

.PHONY: kubeconfig

kubeconfig: ## Fetch a kubeconfig for the AKS cluster and verify access
	@scripts/kubernetes/kubeconfig.sh
