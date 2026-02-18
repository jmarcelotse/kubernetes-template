# ============================================================================
# Configuração de Node Groups do EKS
# ============================================================================

# ----------------------------------------------------------------------------
# IAM Role para Node Groups
# ----------------------------------------------------------------------------

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_node_group" {
  name               = "${var.cluster_name}-eks-node-group-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-eks-node-group-role"
      Purpose = "EKS node group IAM role"
    }
  )
}

# Políticas necessárias para os nodes
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# Política adicional para SSM (útil para troubleshooting)
resource "aws_iam_role_policy_attachment" "eks_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_node_group.name
}

# ----------------------------------------------------------------------------
# Node Groups
# ----------------------------------------------------------------------------

resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.private[*].id

  # Configuração de scaling
  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  # Configuração de instâncias
  instance_types = each.value.instance_types
  disk_size      = each.value.disk_size

  # Labels Kubernetes
  labels = merge(
    each.value.labels,
    {
      "node-group" = each.key
    }
  )

  # Taints Kubernetes
  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  # Configuração de atualização
  update_config {
    max_unavailable_percentage = 33
  }

  # Configuração de lançamento
  launch_template {
    id      = aws_launch_template.node_group[each.key].id
    version = "$Latest"
  }

  tags = merge(
    var.tags,
    {
      Name                                        = "${var.cluster_name}-${each.key}-node-group"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      NodeGroup                                   = each.key
    }
  )

  # Garantir que as políticas IAM sejam criadas antes dos node groups
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_iam_role_policy_attachment.eks_ssm_policy,
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# ----------------------------------------------------------------------------
# Launch Templates para Node Groups
# ----------------------------------------------------------------------------

resource "aws_launch_template" "node_group" {
  for_each = var.node_groups

  name_prefix = "${var.cluster_name}-${each.key}-"
  description = "Launch template para node group ${each.key} do cluster ${var.cluster_name}"

  # Configuração de rede
  vpc_security_group_ids = [aws_security_group.eks_nodes.id]

  # Configuração de blocos de dispositivo
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = each.value.disk_size
      volume_type           = "gp3"
      iops                  = 3000
      throughput            = 125
      delete_on_termination = true
      encrypted             = true
    }
  }

  # Metadados da instância (IMDSv2)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Monitoramento detalhado
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      var.tags,
      {
        Name                                        = "${var.cluster_name}-${each.key}-node"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        NodeGroup                                   = each.key
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.tags,
      {
        Name                                        = "${var.cluster_name}-${each.key}-volume"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        NodeGroup                                   = each.key
      }
    )
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.cluster_name}-${each.key}-launch-template"
      NodeGroup = each.key
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
