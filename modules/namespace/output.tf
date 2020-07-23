output "namespace" {
  value = data.kubernetes_namespace.spinnaker.metadata[0].name
}