# ============================================================================
# Configuração IRSA (IAM Roles for Service Accounts)
# ============================================================================

# ----------------------------------------------------------------------------
# OIDC Provider para IRSA
# ----------------------------------------------------------------------------

# Obter o certificado TLS do OIDC provider do cluster
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Criar OIDC provider no IAM
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-oidc-provider"
      Purpose = "IRSA (IAM Roles for Service Accounts)"
    }
  )
}

# ----------------------------------------------------------------------------
# Outputs para uso em módulos de plataforma
# ----------------------------------------------------------------------------

# URL do OIDC issuer (sem https://)
locals {
  oidc_issuer_url = replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")
}
