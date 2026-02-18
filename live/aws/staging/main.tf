# Main configuration for staging environment

terraform {
  required_version = ">= 1.5.0"

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
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      ManagedBy   = "Terraform"
      Project     = "eks-template"
      Owner       = "platform-team"
      Purpose     = "kubernetes-cluster"
    }
  }
}

# ============================================================================
# EKS Cluster Module
# ============================================================================

module "eks_cluster" {
  source = "../../../modules/clusters/eks"

  # Basic Configuration
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  environment     = "staging"

  # Network Configuration
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  # NAT Gateway Configuration - Single NAT for cost optimization in staging
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # VPC Endpoints
  enable_vpc_endpoints = var.enable_vpc_endpoints

  # Control Plane Logging
  enable_control_plane_logs       = var.enable_control_plane_logs
  control_plane_log_types         = var.control_plane_log_types
  control_plane_log_retention_days = var.control_plane_log_retention_days

  # Secrets Encryption
  enable_secrets_encryption = var.enable_secrets_encryption
  kms_key_deletion_window   = var.kms_key_deletion_window

  # Node Groups - Optimized for staging (smaller instances, conservative scaling)
  node_groups = var.node_groups

  # Cluster Access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  # Tags
  tags = var.tags
}

# ============================================================================
# Kubernetes and Helm Providers
# ============================================================================

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# ============================================================================
# Platform Modules
# ============================================================================

# ArgoCD - GitOps Platform
module "argocd" {
  source = "../../../modules/platform/argocd"

  cluster_name  = var.cluster_name
  chart_version = "5.51.0"

  depends_on = [module.eks_cluster]
}

# Policy Engine - Security Policies (Audit mode for staging)
module "policy_engine" {
  source = "../../../modules/platform/policy-engine"

  engine           = "kyverno"
  enforcement_mode = "audit"  # Audit mode for staging

  policies = {
    block_privileged      = true
    require_non_root      = true
    require_resources     = true
    block_latest_tag      = true
    require_labels        = false
    restrict_capabilities = true
  }

  depends_on = [module.eks_cluster]
}

# External Secrets Operator
module "external_secrets" {
  source = "../../../modules/platform/external-secrets"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_issuer_url   = module.eks_cluster.cluster_oidc_issuer_url
  aws_region        = var.aws_region

  # Allow access to all secrets in staging
  secrets_manager_arns = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:staging/*"]
  ssm_parameter_arns   = ["arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/staging/*"]

  depends_on = [module.eks_cluster]
}

# Observability Stack (7 days metrics, 3 days logs for staging)
module "observability" {
  source = "../../../modules/platform/observability"

  environment               = "staging"
  prometheus_retention_days = 7
  loki_retention_days       = 3
  grafana_admin_password    = var.grafana_admin_password

  prometheus_storage_size = "50Gi"
  loki_storage_size       = "100Gi"
  storage_class           = "gp3"

  depends_on = [module.eks_cluster]
}

# Ingress Controller (ALB) with cert-manager and external-dns
module "ingress" {
  source = "../../../modules/platform/ingress"

  ingress_type      = "alb"
  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_issuer_url   = module.eks_cluster.cluster_oidc_issuer_url
  vpc_id            = module.eks_cluster.vpc_id
  aws_region        = var.aws_region

  route53_zone_id    = var.route53_zone_id
  domain_name        = var.domain_name
  cert_manager_email = var.cert_manager_email

  letsencrypt_environment = "staging"  # Use Let's Encrypt staging for testing

  depends_on = [module.eks_cluster]
}

# Velero - Backup and Disaster Recovery (daily backups, 7 days retention)
module "velero" {
  source = "../../../modules/platform/velero"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks_cluster.oidc_provider_arn
  oidc_issuer_url   = module.eks_cluster.cluster_oidc_issuer_url
  aws_region        = var.aws_region

  backup_bucket_name    = "${var.cluster_name}-velero-backups"
  backup_schedule       = "0 2 * * *"  # Daily at 2 AM
  backup_retention_days = 7

  enable_volume_snapshots = true

  depends_on = [module.eks_cluster]
}

# Compliance and Audit
module "compliance" {
  source = "../../../modules/compliance"

  environment              = "staging"
  aws_region               = var.aws_region
  audit_log_retention_days = 90

  enable_cloudtrail = true
  enable_config     = true
  enable_guardduty  = true
}

# ============================================================================
# Data Sources
# ============================================================================

data "aws_caller_identity" "current" {}
