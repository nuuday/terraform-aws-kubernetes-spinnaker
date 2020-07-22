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

variable "ingress_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable creation of ingress resources"
}

variable "ingress_deck_hostname" {
  type        = string
  default     = "localhost"
  description = "Deck Ingress hostnames"
}

variable "ingress_gate_hostname" {
  type        = string
  default     = "localhost"
  description = "Gate Ingress hostnames"
}

variable "ingress_cluster_issuer" {
  type        = string
  default     = "letsencrypt"
  description = "Cert-manager cluster issuer"
}

variable "ingress_class" {
  type        = string
  default     = "nginx"
  description = "Ingress class"
}

variable "oauth_github_client_id" {
  description = "Github OAUTH client id"
  type        = string
}

variable "oauth_github_client_secret" {
  description = "Github OAUTH client secret"
  type        = string
}

variable "deployment_context" {
  type        = string
  description = "Context to use when deploying spinnaker"
}

variable "deployment_serviceaccount_name" {
  type        = string
  description = "service account to use when deploying spinnaker"
  default     = "spinnaker"
}

variable "deployment_serviceaccount_namespace" {
  type        = string
  description = "service account namespace"
  default     = "kube-system"
}

variable "accounts" {
  default = {
    kubernetes = []
  }
  type = object({
    kubernetes = list(object({
      context    = string
      kubeconfig = string
      namespaces = list(string)
    }))
  })
}

