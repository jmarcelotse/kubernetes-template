terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Namespace para External Secrets Operator
resource "kubernetes_namespace" "external_secrets" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# IAM Policy para acesso ao Secrets Manager e SSM
data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = var.secrets_manager_arns
  }

  statement {
    sid    = "SSMParameterAccess"
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterHistory",
      "ssm:GetParametersByPath"
    ]
    resources = var.ssm_parameter_arns
  }

  statement {
    sid    = "ListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
      "ssm:DescribeParameters"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name        = "${var.cluster_name}-external-secrets"
  description = "Policy for External Secrets Operator to access AWS Secrets Manager and SSM"
  policy      = data.aws_iam_policy_document.external_secrets.json

  tags = {
    Name    = "${var.cluster_name}-external-secrets"
    Cluster = var.cluster_name
  }
}

# IAM Role para IRSA
data "aws_iam_policy_document" "external_secrets_trust" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.service_account_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_trust.json

  tags = {
    Name    = "${var.cluster_name}-external-secrets"
    Cluster = var.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "external_secrets" {
  role       = aws_iam_role.external_secrets.name
  policy_arn = aws_iam_policy.external_secrets.arn
}

# Instalação do External Secrets Operator via Helm
resource "helm_release" "external_secrets" {
  name       = "external-secrets"
  repository = "https://charts.external-secrets.io"
  chart      = "external-secrets"
  version    = var.chart_version
  namespace  = kubernetes_namespace.external_secrets.metadata[0].name

  values = [
    yamlencode({
      installCRDs = true
      
      serviceAccount = {
        create = true
        name   = var.service_account_name
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
        }
      }

      nodeSelector = var.node_selector
      tolerations  = var.tolerations

      webhook = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      certController = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.external_secrets
  ]
}

# Aguardar instalação antes de criar ClusterSecretStore
resource "time_sleep" "wait_for_external_secrets" {
  depends_on = [helm_release.external_secrets]

  create_duration = "30s"
}

# ClusterSecretStore para AWS Secrets Manager
resource "kubernetes_manifest" "cluster_secret_store" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-secrets-manager"
    }
    spec = {
      provider = {
        aws = {
          service = "SecretsManager"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.service_account_name
                namespace = var.namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_external_secrets]
}

# ClusterSecretStore para AWS SSM Parameter Store
resource "kubernetes_manifest" "cluster_secret_store_ssm" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "aws-parameter-store"
    }
    spec = {
      provider = {
        aws = {
          service = "ParameterStore"
          region  = var.aws_region
          auth = {
            jwt = {
              serviceAccountRef = {
                name      = var.service_account_name
                namespace = var.namespace
              }
            }
          }
        }
      }
    }
  }

  depends_on = [time_sleep.wait_for_external_secrets]
}
