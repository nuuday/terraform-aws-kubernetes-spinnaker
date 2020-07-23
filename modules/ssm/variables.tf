variable "cluster_arn" {
  type = string
}

variable "kubeconfig" {
  type = string
}
variable "enabled" {
  type = bool
  default = true
}
variable "context_name" {
  type = string
}
variable "namespaces" {
  type = list(string)
  default = []
}
