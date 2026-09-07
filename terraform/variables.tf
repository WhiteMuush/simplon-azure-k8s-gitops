variable "subscription_id" {
  description = "Azure subscription the lab runs in, set through TF_VAR_subscription_id."
  type        = string
}

variable "resource_group_name" {
  description = "Ressource Group"
  type        = string
  default     = "mpetitRG"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "francecentral"
}
