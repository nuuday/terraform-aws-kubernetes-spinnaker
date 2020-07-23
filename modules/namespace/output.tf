output "namespace" {
  value = kubernetes_namespace.spinnaker[0].metadata[0].name
}