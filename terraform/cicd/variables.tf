variable "subscription_id" {
  description = "Azure subscription the lab runs in, set through TF_VAR_subscription_id."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the pipeline is allowed to manage."
  type        = string
  default     = "mpetitRG"
}

variable "application_name" {
  description = "Entra ID application the GitLab pipeline authenticates as."
  type        = string
  default     = "gitlab-ci"
}

variable "gitlab_issuer" {
  description = "OIDC issuer of the GitLab instance."
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_project_path" {
  description = "Namespace and name of the GitLab project, as it appears in its URL."
  type        = string
  default     = "WhiteMuush/simplon-azure-k8s-gitops"
}

variable "gitlab_default_branch" {
  description = "Branch the pipeline is allowed to deploy from."
  type        = string
  default     = "main"
}
