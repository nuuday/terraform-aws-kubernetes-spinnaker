locals {
  chart_name    = "spinnaker"
  chart_version = var.chart_version
  release_name  = "spinnaker"
  namespace     = var.namespace
  repository    = "https://kubernetes-charts.storage.googleapis.com"
  bucket_prefix = "spinnaker"
  bucket_name   = module.s3_bucket.this_s3_bucket_id
  role_name     = local.bucket_name
  provider_url  = replace(var.oidc_provider_issuer_url, "https://", "")

  values = {
    halyard = {
      image = {
        tag = "stable"
      }
      spinnakerVersion = var.spinnaker_version
      additionalScripts = {
        create = true
        data = {
          "enable_prometheus.sh" = <<EOF
            $HAL_COMMAND config metric-stores prometheus enable
            $HAL_COMMAND config security ui edit --override-base-url https://${var.ingress_deck_hostname}
            $HAL_COMMAND config security api edit --override-base-url https://${var.ingress_gate_hostname}
            $HAL_COMMAND config security authn oauth2 edit --provider github \
                --client-id ${var.oauth_github_client_id} \
                --client-secret ${var.oauth_github_client_secret} \
                --pre-established-redirect-uri https://${var.ingress_gate_hostname}/login
            $HAL_COMMAND config security authn oauth2 enable

            %{for account in var.accounts.kubernetes}
            if $HAL_COMMAND config provider kubernetes account get ${account.context}; then
              PROVIDER_COMMAND='edit'
            else
              PROVIDER_COMMAND='add'
            fi
            $HAL_COMMAND config provider kubernetes account $PROVIDER_COMMAND ${account.context}  \
                        --context ${account.context} \
                        --kubeconfig-file /opt/kube/kubeconfig \
                        --only-spinnaker-managed true \
                        --namespaces="${join(",", account.namespaces)}" \
                        --all-kinds \
                        --provider-version v2
            $HAL_COMMAND config provider kubernetes account edit ${account.context} --remove-omit-namespace kube-system
            $HAL_COMMAND config provider kubernetes account edit ${account.context} --remove-omit-namespace kube-public
            %{endfor}

            $HAL_COMMAND config artifact helm enable
            %{for account in var.accounts.helm}
            if $HAL_COMMAND config artifact helm account get ${account.name}; then
              PROVIDER_COMMAND='edit'
            else
              PROVIDER_COMMAND='add'
            fi
            $HAL_COMMAND config artifact helm account $PROVIDER_COMMAND ${account.name}  \
                        --repository ${account.url} \
                        --username-password-file /opt/halyard/additionalSecrets/helm-${account.name}.txt
            %{endfor}

            $HAL_COMMAND config provider docker-registry account delete dockerhub
            $HAL_COMMAND config ci wercker disable
            $HAL_COMMAND config repository artifactory disable
            EOF
        }
      }
      additionalServiceSettings = {
        "front50.yml" = {
          kubernetes = {
            serviceAccountName = kubernetes_service_account.spinnaker.metadata[0].name
            securityContext = {
              fsGroup = 100
            }
          }
        }
        "deck.yml" = {
          kubernetes = {
            serviceType = "ClusterIP"
          }
        }
        "gate.yml" = {
          kubernetes = {
            serviceType = "ClusterIP"
          }
        }
      }
      additionalSecrets = {
        create = true
        data = zipmap(
          concat([for i, v in var.accounts.helm : "helm-${v.name}.txt"], ["accounts.kubeconfig"]),
          concat([for i, v in var.accounts.helm : base64encode("${v.username}:${trimspace(v.password)}")], [module.kubeconfig.stdout])
        )
      }
    }
    spinnakerFeatureFlags = [
      "managed-pipeline-templates-v2-ui",
      "chaos"
    ]
    serviceAccount = {
      serviceAccountAnnotations = {
        "eks.amazonaws.com/role-arn" = module.iam.this_iam_role_arn
      }
    }
    kubeConfig = {
      enabled    = false
/*      secretName = kubernetes_secret.kubeconfig.metadata[0].name
      secretKey  = "kubeconfig"
      contexts = [
        var.deployment_context
      ]
      deploymentContext = var.deployment_context
      onlySpinnakerManaged = {
        enabled = true
      }*/
    }
    ingress = {
      enabled = var.ingress_enabled
      host    = var.ingress_deck_hostname
      annotations = {
        "kubernetes.io/ingress.class" : var.ingress_class
        "cert-manager.io/cluster-issuer" : var.ingress_cluster_issuer
      }
      tls = [
        {
          secretName = "spinnaker-deck-tls"
          hosts      = [var.ingress_deck_hostname]
        }
      ]
    }
    ingressGate = {
      enabled = var.ingress_enabled
      host    = var.ingress_gate_hostname
      annotations = {
        "kubernetes.io/ingress.class" : var.ingress_class
        "cert-manager.io/cluster-issuer" : var.ingress_cluster_issuer
      }
      tls = [
        {
          secretName = "spinnaker-gate-tls"
          hosts      = [var.ingress_gate_hostname]
        }
      ]
    }

    minio = {
      enabled = false
    }
    s3 = {
      enabled = true
      bucket  = local.bucket_name
      region  = data.aws_region.spinnaker.name
    }
  }

}

data aws_region "spinnaker" {}
data aws_caller_identity "spinnaker" {}

module "iam" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"

  create_role  = true
  role_name    = "${local.release_name}-irsa-${local.bucket_name}-halyard"
  provider_url = local.provider_url
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:${local.namespace}:${local.release_name}-spinnaker-halyard",
    "system:serviceaccount:${local.namespace}:spinnaker"
  ]
  tags = var.tags
}

data "aws_iam_policy_document" "spinnaker" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [module.s3_bucket.this_s3_bucket_arn, "${module.s3_bucket.this_s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "halyard" {
  name = local.bucket_name
  role = module.iam.this_iam_role_name

  policy = data.aws_iam_policy_document.spinnaker.json
}

resource "kubernetes_service_account" "spinnaker" {
  metadata {
    name      = "spinnaker"
    namespace = kubernetes_namespace.spinnaker.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = module.iam.this_iam_role_arn
    }
  }
}

resource "local_file" "kubeconfig" {
  count             = length(var.accounts.kubernetes)
  filename          = "kubeconfig-${count.index}"
  sensitive_content = var.accounts.kubernetes[count.index].kubeconfig
}

resource "kubernetes_namespace" "spinnaker" {
  metadata {
    name = var.namespace
  }
}

module "kubeconfig" {
  source = "matti/resource/shell"
  environment = {
    KUBECONFIG = join(":", [for i, file in local_file.kubeconfig : file.filename])
  }
  command = "kubectl config view --flatten #${timestamp()}"
}

resource "kubernetes_secret" "kubeconfig" {
  depends_on = [module.kubeconfig]
  metadata {
    name      = "kubernetes-accounts"
    namespace = var.namespace
  }
  data = {
    kubeconfig = module.kubeconfig.stdout
    timestamp  = timestamp()
  }
}

output "kubeconfig" {
  value = {
    stdout     = module.kubeconfig.stdout
    kubeconfig = join(";", [for i, file in local_file.kubeconfig : file.filename])
  }
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket_prefix = local.bucket_prefix
  acl           = "private"
  force_destroy = true
  versioning = {
    enabled = true
  }
  tags = var.tags
}

resource "helm_release" "spinnaker" {
  name             = local.release_name
  chart            = local.chart_name
  version          = local.chart_version
  repository       = local.repository
  namespace        = local.namespace
  create_namespace = false

  wait   = false
  values = [yamlencode(local.values)]
}

resource "kubernetes_cluster_role" "spinnaker" {
  metadata {
    name = "spinnaker"
  }
  rule {
    api_groups = [""]
    verbs      = ["get", "list"]
    resources  = ["namespaces"]
  }
}

resource "kubernetes_cluster_role_binding" "spinnaker" {
  metadata {
    name = "spinnaker"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "spinnaker"
  }
  subject {
    namespace = var.deployment_serviceaccount_namespace
    kind      = "ServiceAccount"
    name      = var.deployment_serviceaccount_name
  }
}

module "spinnaker_namespace" {
  source           = "./modules/namespace"
  namespace        = kubernetes_namespace.spinnaker.metadata[0].name
  create_namespace = false
}
