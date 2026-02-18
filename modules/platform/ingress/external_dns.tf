# external-dns para gerenciamento automático de DNS

# IAM Policy para external-dns
data "aws_iam_policy_document" "external_dns" {
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${var.route53_zone_id}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_dns" {
  name        = "${var.cluster_name}-external-dns"
  description = "Policy for external-dns to manage Route53 records"
  policy      = data.aws_iam_policy_document.external_dns.json

  tags = {
    Name    = "${var.cluster_name}-external-dns"
    Cluster = var.cluster_name
  }
}

# IAM Role para IRSA
data "aws_iam_policy_document" "external_dns_trust" {
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
      values   = ["system:serviceaccount:${var.namespace_external_dns}:external-dns"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_issuer_url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "external_dns" {
  name               = "${var.cluster_name}-external-dns"
  assume_role_policy = data.aws_iam_policy_document.external_dns_trust.json

  tags = {
    Name    = "${var.cluster_name}-external-dns"
    Cluster = var.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}

# Instalação do external-dns via Helm
resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  version    = var.chart_version_external_dns
  namespace  = kubernetes_namespace.external_dns.metadata[0].name

  values = [
    yamlencode({
      provider = "aws"

      aws = {
        region = var.aws_region
        zoneType = "public"
      }

      domainFilters = [var.domain_name]

      policy = "sync"  # sync ou upsert-only

      serviceAccount = {
        create = true
        name   = "external-dns"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
        }
      }

      nodeSelector = var.node_selector
      tolerations  = var.tolerations

      sources = [
        "ingress",
        "service"
      ]

      txtOwnerId = var.cluster_name
      txtPrefix  = "external-dns-"
    })
  ]

  depends_on = [
    aws_iam_role_policy_attachment.external_dns
  ]
}
