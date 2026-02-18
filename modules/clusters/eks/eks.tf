# ============================================================================
# Configuração do Cluster EKS
# ============================================================================

# ----------------------------------------------------------------------------
# Chave KMS para Criptografia de Secrets
# ----------------------------------------------------------------------------

resource "aws_kms_key" "eks" {
  count = var.enable_secrets_encryption ? 1 : 0

  description             = "Chave KMS para criptografia de secrets do cluster EKS ${var.cluster_name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-secrets"
      Purpose = "EKS secrets encryption"
    }
  )
}

resource "aws_kms_alias" "eks" {
  count = var.enable_secrets_encryption ? 1 : 0

  name          = "alias/${var.cluster_name}-eks-secrets"
  target_key_id = aws_kms_key.eks[0].key_id
}

# ----------------------------------------------------------------------------
# CloudWatch Log Group para Logs do Control Plane
# ----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_control_plane_logs ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.control_plane_log_retention_days

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-logs"
      Purpose = "EKS control plane logs"
    }
  )
}

# ----------------------------------------------------------------------------
# IAM Role para o Cluster EKS
# ----------------------------------------------------------------------------

data "aws_iam_policy_document" "eks_cluster_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${var.cluster_name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-cluster-role"
      Purpose = "EKS cluster IAM role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

# ----------------------------------------------------------------------------
# Security Group para o Cluster EKS
# ----------------------------------------------------------------------------

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.cluster_name}-eks-cluster-"
  description = "Security group para o control plane do cluster EKS ${var.cluster_name}"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-cluster-sg"
      Purpose = "EKS cluster security group"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Regra para permitir comunicação entre control plane e nodes
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  description              = "Allow nodes to communicate with cluster API"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "cluster_egress_all" {
  description       = "Allow cluster to communicate with nodes and internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_cluster.id
}

# ----------------------------------------------------------------------------
# Security Group para Nodes do EKS
# ----------------------------------------------------------------------------

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.cluster_name}-eks-nodes-"
  description = "Security group para nodes do cluster EKS ${var.cluster_name}"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.cluster_name}-eks-nodes-sg"
      Purpose                                     = "EKS nodes security group"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Permitir comunicação entre nodes
resource "aws_security_group_rule" "nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

# Permitir comunicação do control plane para nodes
resource "aws_security_group_rule" "nodes_cluster_ingress" {
  description              = "Allow cluster control plane to communicate with nodes"
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

# Permitir tráfego de saída dos nodes
resource "aws_security_group_rule" "nodes_egress_all" {
  description       = "Allow nodes to communicate with internet"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_nodes.id
}

# ----------------------------------------------------------------------------
# Cluster EKS
# ----------------------------------------------------------------------------

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat(aws_subnet.private[*].id, aws_subnet.public[*].id)
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Habilitar logs do control plane
  enabled_cluster_log_types = var.enable_control_plane_logs ? var.control_plane_log_types : []

  # Habilitar criptografia de secrets
  dynamic "encryption_config" {
    for_each = var.enable_secrets_encryption ? [1] : []
    content {
      provider {
        key_arn = aws_kms_key.eks[0].arn
      }
      resources = ["secrets"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_vpc_resource_controller,
    aws_cloudwatch_log_group.eks_cluster
  ]
}
