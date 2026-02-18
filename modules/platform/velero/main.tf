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

# Namespace para Velero
resource "kubernetes_namespace" "velero" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Bucket S3 para backups
resource "aws_s3_bucket" "velero_backups" {
  bucket = var.backup_bucket_name

  tags = merge(
    {
      Name    = var.backup_bucket_name
      Cluster = var.cluster_name
      Purpose = "velero-backups"
    },
    var.tags
  )
}

# Versionamento do bucket
resource "aws_s3_bucket_versioning" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia do bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acesso público
resource "aws_s3_bucket_public_access_block" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle policy para retenção
resource "aws_s3_bucket_lifecycle_configuration" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Bucket policy para prevenir deleção acidental
resource "aws_s3_bucket_policy" "velero_backups" {
  bucket = aws_s3_bucket.velero_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyDeleteBucket"
        Effect = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy"
        ]
        Resource = aws_s3_bucket.velero_backups.arn
      }
    ]
  })
}

# IAM Policy para Velero
data "aws_iam_policy_document" "velero" {
  # Permissões para bucket S3
  statement {
    sid    = "VeleroS3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "${aws_s3_bucket.velero_backups.arn}/*"
    ]
  }

  statement {
    sid    = "VeleroS3List"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.velero_backups.arn
    ]
  }

  # Permissões para snapshots EBS (se habilitado)
  dynamic "statement" {
    for_each = var.enable_volume_snapshots ? [1] : []
    content {
      sid    = "VeleroEBSSnapshots"
      effect = "Allow"
      actions = [
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot"
      ]
      resources = ["*"]
    }
  }
}

resource "aws_iam_policy" "velero" {
  name        = "${var.cluster_name}-velero"
  description = "Policy for Velero to manage backups"
  policy      = data.aws_iam_policy_document.velero.json

  tags = {
    Name    = "${var.cluster_name}-velero"
    Cluster = var.cluster_name
  }
}

# IAM Role para IRSA
data "aws_iam_policy_document" "velero_trust" {
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

resource "aws_iam_role" "velero" {
  name               = "${var.cluster_name}-velero"
  assume_role_policy = data.aws_iam_policy_document.velero_trust.json

  tags = {
    Name    = "${var.cluster_name}-velero"
    Cluster = var.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "velero" {
  role       = aws_iam_role.velero.name
  policy_arn = aws_iam_policy.velero.arn
}

# Instalação do Velero via Helm
resource "helm_release" "velero" {
  name       = "velero"
  repository = "https://vmware-tanzu.github.io/helm-charts"
  chart      = "velero"
  version    = var.chart_version
  namespace  = kubernetes_namespace.velero.metadata[0].name

  values = [
    yamlencode({
      initContainers = [{
        name  = "velero-plugin-for-aws"
        image = "velero/velero-plugin-for-aws:v1.8.2"
        volumeMounts = [{
          mountPath = "/target"
          name      = "plugins"
        }]
      }]

      configuration = {
        provider = "aws"

        backupStorageLocation = {
          bucket = aws_s3_bucket.velero_backups.id
          config = {
            region = var.aws_region
          }
        }

        volumeSnapshotLocation = var.enable_volume_snapshots ? {
          config = {
            region = var.aws_region
          }
        } : null
      }

      serviceAccount = {
        server = {
          create = true
          name   = var.service_account_name
          annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.velero.arn
          }
        }
      }

      nodeSelector = var.node_selector
      tolerations  = var.tolerations

      metrics = {
        enabled = true
        serviceMonitor = {
          enabled = true
        }
      }

      schedules = {
        default = {
          disabled = false
          schedule = var.backup_schedule
          template = {
            ttl = "${var.backup_retention_days * 24}h"
            includedNamespaces = length(var.backup_namespaces) > 0 ? var.backup_namespaces : ["*"]
            excludedNamespaces = var.exclude_namespaces
            snapshotVolumes    = var.enable_volume_snapshots
          }
        }
      }
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.velero,
    aws_s3_bucket.velero_backups
  ]
}

# Aguardar instalação do Velero
resource "time_sleep" "wait_for_velero" {
  depends_on = [helm_release.velero]

  create_duration = "30s"
}
