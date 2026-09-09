##@ Kubernetes

.PHONY: kubeconfig wake

kubeconfig: ## Fetch a kubeconfig for the AKS cluster and verify access
	@scripts/kubernetes/kubeconfig.sh

wake: ## Bring the cluster nodes back after they have been deallocated
	@scripts/kubernetes/wake.sh
