resource "kubernetes_namespace" "spinnaker" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
  }
}

data "kubernetes_namespace" "spinnaker" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_role" "spinnaker" {
  metadata {
    namespace = data.kubernetes_namespace.spinnaker.metadata[0].name
    name      = var.serviceaccount_name
  }
  rule {
    api_groups = [""]
    verbs      = ["get", "list"]
    resources  = ["namespaces", "configmaps", "events", "replicationcontrollers", "serviceaccounts", "pods/log"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods", "services", "secrets", "configmaps", "serviceaccounts"]
    verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
  }
  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["controllerrevisions", "statefulsets"]
    verbs      = ["list"]
  }
  rule {
    api_groups = ["extensions", "apps"]
    resources  = ["deployments", "replicasets", "ingresses", "statefulsets"]
    verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
  }
  rule {
    api_groups = [""]
    resources  = ["services/proxy", "pods/portforward"]
    verbs      = ["create", "delete", "deletecollection", "get", "list", "patch", "update", "watch"]
  }
}

resource "kubernetes_role_binding" "spinnaker" {
  metadata {
    namespace = data.kubernetes_namespace.spinnaker.metadata[0].name
    name      = var.serviceaccount_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "spinnaker"
  }
  subject {
    namespace = var.serviceaccount_namespace
    kind      = "ServiceAccount"
    name      = var.serviceaccount_name
  }
}
