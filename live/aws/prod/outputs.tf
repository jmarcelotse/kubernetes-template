# ============================================================================
# Outputs for Production Environment
# ============================================================================

# ----------------------------------------------------------------------------
# Cluster Information
# ----------------------------------------------------------------------------

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks_cluster.cluster_id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = module.eks_cluster.cluster_endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = module.eks_cluster.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = module.eks_cluster.cluster_platform_version
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster authentication"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

# ----------------------------------------------------------------------------
# OIDC Provider (for IRSA)
# ----------------------------------------------------------------------------

output "cluster_oidc_issuer_url" {
  description = "URL of the OIDC provider for the cluster"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for IRSA"
  value       = module.eks_cluster.oidc_provider_arn
}

# ----------------------------------------------------------------------------
# Network Information
# ----------------------------------------------------------------------------

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.eks_cluster.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.eks_cluster.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.eks_cluster.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.eks_cluster.public_subnet_ids
}

# ----------------------------------------------------------------------------
# Security Groups
# ----------------------------------------------------------------------------

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks_cluster.cluster_security_group_id
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks_cluster.node_security_group_id
}

# ----------------------------------------------------------------------------
# Node Groups
# ----------------------------------------------------------------------------

output "node_group_ids" {
  description = "IDs of the EKS node groups"
  value       = module.eks_cluster.node_group_ids
}

output "node_group_arns" {
  description = "ARNs of the EKS node groups"
  value       = module.eks_cluster.node_group_arns
}

output "node_group_status" {
  description = "Status of the EKS node groups"
  value       = module.eks_cluster.node_group_status
}

# ----------------------------------------------------------------------------
# IAM Roles
# ----------------------------------------------------------------------------

output "cluster_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS cluster"
  value       = module.eks_cluster.cluster_iam_role_arn
}

output "node_iam_role_arn" {
  description = "ARN of the IAM role used by the EKS nodes"
  value       = module.eks_cluster.node_iam_role_arn
}

# ----------------------------------------------------------------------------
# KMS Key
# ----------------------------------------------------------------------------

output "kms_key_id" {
  description = "ID of the KMS key used for secrets encryption"
  value       = module.eks_cluster.kms_key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value       = module.eks_cluster.kms_key_arn
}

# ----------------------------------------------------------------------------
# CloudWatch Log Group
# ----------------------------------------------------------------------------

output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group for control plane logs"
  value       = module.eks_cluster.cloudwatch_log_group_name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the CloudWatch log group for control plane logs"
  value       = module.eks_cluster.cloudwatch_log_group_arn
}

# ============================================================================
# Platform Outputs
# ============================================================================

# ArgoCD
output "argocd_namespace" {
  description = "Namespace where ArgoCD is installed"
  value       = module.argocd.namespace
}

output "argocd_server_service" {
  description = "ArgoCD server service name"
  value       = module.argocd.server_service_name
}

# Policy Engine
output "policy_engine_namespace" {
  description = "Namespace where policy engine is installed"
  value       = module.policy_engine.namespace
}

output "policy_engine_type" {
  description = "Type of policy engine installed"
  value       = module.policy_engine.engine
}

output "policy_enforcement_mode" {
  description = "Policy enforcement mode"
  value       = module.policy_engine.enforcement_mode
}

# External Secrets
output "external_secrets_namespace" {
  description = "Namespace where External Secrets Operator is installed"
  value       = module.external_secrets.namespace
}

output "external_secrets_role_arn" {
  description = "IAM role ARN for External Secrets Operator"
  value       = module.external_secrets.service_account_role_arn
}

# Observability
output "observability_namespace" {
  description = "Namespace where observability stack is installed"
  value       = module.observability.namespace
}

output "grafana_endpoint" {
  description = "Grafana endpoint (internal)"
  value       = module.observability.grafana_endpoint
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint (internal)"
  value       = module.observability.prometheus_endpoint
}

# Ingress
output "ingress_namespace" {
  description = "Namespace where ingress controller is installed"
  value       = module.ingress.namespace_ingress
}

output "ingress_class" {
  description = "IngressClass to use in Ingress resources"
  value       = module.ingress.ingress_class
}

output "cluster_issuer_name" {
  description = "ClusterIssuer name for TLS certificates"
  value       = module.ingress.cluster_issuer_name
}

# Velero
output "velero_namespace" {
  description = "Namespace where Velero is installed"
  value       = module.velero.namespace
}

output "velero_backup_bucket" {
  description = "S3 bucket for Velero backups"
  value       = module.velero.backup_bucket_name
}

output "velero_backup_schedule" {
  description = "Velero backup schedule"
  value       = module.velero.backup_schedule
}


# Compliance
output "compliance_audit_logs_bucket" {
  description = "S3 bucket for audit logs"
  value       = module.compliance.audit_logs_bucket_name
}

output "compliance_cloudtrail_id" {
  description = "CloudTrail ID"
  value       = module.compliance.cloudtrail_id
}

output "compliance_guardduty_detector_id" {
  description = "GuardDuty Detector ID"
  value       = module.compliance.guardduty_detector_id
}
