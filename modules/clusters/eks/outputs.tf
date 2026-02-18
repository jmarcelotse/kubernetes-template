# ============================================================================
# Outputs do Módulo EKS
# ============================================================================

# ----------------------------------------------------------------------------
# Outputs de VPC
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID da VPC criada para o cluster EKS"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block da VPC"
  value       = aws_vpc.main.cidr_block
}

# ----------------------------------------------------------------------------
# Outputs de Subnets
# ----------------------------------------------------------------------------

output "private_subnet_ids" {
  description = "IDs das subnets privadas onde os nodes do EKS serão provisionados"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas onde load balancers podem ser provisionados"
  value       = aws_subnet.public[*].id
}

output "private_subnet_cidrs" {
  description = "CIDR blocks das subnets privadas"
  value       = aws_subnet.private[*].cidr_block
}

output "public_subnet_cidrs" {
  description = "CIDR blocks das subnets públicas"
  value       = aws_subnet.public[*].cidr_block
}

# ----------------------------------------------------------------------------
# Outputs de NAT Gateway
# ----------------------------------------------------------------------------

output "nat_gateway_ids" {
  description = "IDs dos NAT Gateways criados"
  value       = aws_nat_gateway.main[*].id
}

output "nat_gateway_public_ips" {
  description = "IPs públicos dos NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# ----------------------------------------------------------------------------
# Outputs de VPC Endpoints
# ----------------------------------------------------------------------------

output "vpc_endpoint_ecr_api_id" {
  description = "ID do VPC endpoint para ECR API"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.interface["ecr_api"].id : null
}

output "vpc_endpoint_ecr_dkr_id" {
  description = "ID do VPC endpoint para ECR DKR"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.interface["ecr_dkr"].id : null
}

output "vpc_endpoint_sts_id" {
  description = "ID do VPC endpoint para STS"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.interface["sts"].id : null
}

output "vpc_endpoint_logs_id" {
  description = "ID do VPC endpoint para CloudWatch Logs"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.interface["logs"].id : null
}

output "vpc_endpoint_ssm_id" {
  description = "ID do VPC endpoint para SSM"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.interface["ssm"].id : null
}

output "vpc_endpoint_s3_id" {
  description = "ID do VPC endpoint para S3"
  value       = var.enable_vpc_endpoints ? aws_vpc_endpoint.gateway["s3"].id : null
}

# ----------------------------------------------------------------------------
# Outputs de Security Groups
# ----------------------------------------------------------------------------

output "vpc_endpoints_security_group_id" {
  description = "ID do security group usado pelos VPC endpoints"
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
}

# ----------------------------------------------------------------------------
# Outputs do Cluster EKS
# ----------------------------------------------------------------------------

output "cluster_id" {
  description = "ID do cluster EKS"
  value       = aws_eks_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = aws_eks_cluster.main.name
}

output "cluster_arn" {
  description = "ARN do cluster EKS"
  value       = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Endpoint do API server do cluster EKS"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Versão do Kubernetes do cluster EKS"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "Versão da plataforma do cluster EKS"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_certificate_authority_data" {
  description = "Dados do certificado CA do cluster EKS (base64 encoded)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "ID do security group do control plane do cluster EKS"
  value       = aws_security_group.eks_cluster.id
}

output "node_security_group_id" {
  description = "ID do security group dos nodes do cluster EKS"
  value       = aws_security_group.eks_nodes.id
}

# ----------------------------------------------------------------------------
# Outputs de IRSA (IAM Roles for Service Accounts)
# ----------------------------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "URL do OIDC provider do cluster (com https://)"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "oidc_provider_arn" {
  description = "ARN do OIDC provider para uso com IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "oidc_provider_url" {
  description = "URL do OIDC provider (sem https://) para uso em trust policies"
  value       = local.oidc_issuer_url
}

# ----------------------------------------------------------------------------
# Outputs de Criptografia
# ----------------------------------------------------------------------------

output "kms_key_id" {
  description = "ID da chave KMS usada para criptografia de secrets"
  value       = var.enable_secrets_encryption ? aws_kms_key.eks[0].id : null
}

output "kms_key_arn" {
  description = "ARN da chave KMS usada para criptografia de secrets"
  value       = var.enable_secrets_encryption ? aws_kms_key.eks[0].arn : null
}

# ----------------------------------------------------------------------------
# Outputs de Logs
# ----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Nome do CloudWatch Log Group para logs do control plane"
  value       = var.enable_control_plane_logs ? aws_cloudwatch_log_group.eks_cluster[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "ARN do CloudWatch Log Group para logs do control plane"
  value       = var.enable_control_plane_logs ? aws_cloudwatch_log_group.eks_cluster[0].arn : null
}

# ----------------------------------------------------------------------------
# Outputs de Node Groups
# ----------------------------------------------------------------------------

output "node_group_ids" {
  description = "IDs dos node groups criados"
  value       = { for k, v in aws_eks_node_group.main : k => v.id }
}

output "node_group_arns" {
  description = "ARNs dos node groups criados"
  value       = { for k, v in aws_eks_node_group.main : k => v.arn }
}

output "node_group_status" {
  description = "Status dos node groups criados"
  value       = { for k, v in aws_eks_node_group.main : k => v.status }
}

output "node_group_role_arn" {
  description = "ARN da IAM role usada pelos node groups"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_group_role_name" {
  description = "Nome da IAM role usada pelos node groups"
  value       = aws_iam_role.eks_node_group.name
}

output "launch_template_ids" {
  description = "IDs dos launch templates criados para os node groups"
  value       = { for k, v in aws_launch_template.node_group : k => v.id }
}

output "launch_template_latest_versions" {
  description = "Versões mais recentes dos launch templates"
  value       = { for k, v in aws_launch_template.node_group : k => v.latest_version }
}

# ----------------------------------------------------------------------------
# Outputs de IAM Roles
# ----------------------------------------------------------------------------

output "cluster_iam_role_arn" {
  description = "ARN da IAM role usada pelo control plane do cluster EKS"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_iam_role_name" {
  description = "Nome da IAM role usada pelo control plane do cluster EKS"
  value       = aws_iam_role.eks_cluster.name
}

output "node_iam_role_arn" {
  description = "ARN da IAM role usada pelos nodes do cluster EKS (alias para node_group_role_arn)"
  value       = aws_iam_role.eks_node_group.arn
}

output "node_iam_role_name" {
  description = "Nome da IAM role usada pelos nodes do cluster EKS (alias para node_group_role_name)"
  value       = aws_iam_role.eks_node_group.name
}
