variable "namespace" {
  type = string
}
variable "create_namespace" {
  type    = bool
  default = true
}

variable "serviceaccount_name" {
  default = "spinnaker"
  type    = string
}
variable "serviceaccount_namespace" {
  default = "kube-system"
  type    = string
}
