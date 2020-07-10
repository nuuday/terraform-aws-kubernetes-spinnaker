variable "chart_version" {
  default     = "2.0.0-rc9"
  description = "Spinnaker version to install"
  type        = string
}

variable "namespace" {
  default     = "spinnaker"
  description = "Kubernetes namespace to deploy to"
  type        = string
}

variable "oidc_provider_issuer_url" {
  description = "Issuer used in the OIDC provider associated with the EKS cluster to support IRSA."
  type        = string
}

variable "tags" {
  description = "Tags to apply to taggable resources provisioned by this module."
  type        = map(string)
  default     = {}
}

variable "spinnaker_version" {
  default = "1.21.0"
}
