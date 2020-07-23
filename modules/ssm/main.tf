locals {
  cluster_id = replace(var.cluster_arn, "/[:\\/]/", "-")
}

resource "aws_ssm_parameter" "spinnaker_kubeconfig" {
  count      = var.enabled ? 1 : 0
  name       = "/spinnaker/${local.cluster_id}/kubeconfig"
  type       = "SecureString"
  value      = var.kubeconfig
}

resource "aws_ssm_parameter" "spinnaker_context" {
  count      = var.enabled ? 1 : 0
  name       = "/spinnaker/${local.cluster_id}/context"
  type       = "String"
  value      = var.context_name
}

resource "aws_ssm_parameter" "spinnaker_namespaces" {
  count      = var.enabled ? 1 : 0
  name       = "/spinnaker/${local.cluster_id}/namespaces"
  type       = "String"
  value      = jsonencode(var.namespaces)
}