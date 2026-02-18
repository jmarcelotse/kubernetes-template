# ============================================================================
# Variables for Staging Environment
# ============================================================================

# ----------------------------------------------------------------------------
# AWS Configuration
# ----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

# ----------------------------------------------------------------------------
# Cluster Basic Configuration
# ----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-staging"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|30)$", var.cluster_version))
    error_message = "Kubernetes version must be between 1.24 and 1.30"
  }
}

# ----------------------------------------------------------------------------
# Network Configuration
# ----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Invalid CIDR block"
  }
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ----------------------------------------------------------------------------
# NAT Gateway Configuration
# ----------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization (staging only)"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# VPC Endpoints Configuration
# ----------------------------------------------------------------------------

variable "enable_vpc_endpoints" {
  description = "Create VPC endpoints for AWS services"
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Control Plane Logging
# ----------------------------------------------------------------------------

variable "enable_control_plane_logs" {
  description = "Enable EKS control plane logs"
  type        = bool
  default     = true
}

variable "control_plane_log_types" {
  description = "Types of control plane logs to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "control_plane_log_retention_days" {
  description = "Number of days to retain control plane logs"
  type        = number
  default     = 7
}

# ----------------------------------------------------------------------------
# Secrets Encryption
# ----------------------------------------------------------------------------

variable "enable_secrets_encryption" {
  description = "Enable encryption of Kubernetes secrets using KMS"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

# ----------------------------------------------------------------------------
# Node Groups Configuration
# ----------------------------------------------------------------------------

variable "node_groups" {
  description = "Configuration for EKS node groups"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    labels         = map(string)
    taints = list(object({
      key    = string
      value  = string
      effect = string
    }))
  }))
  default = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
      labels = {
        role = "system"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    apps = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      disk_size      = 100
      labels = {
        role = "apps"
      }
      taints = []
    }
  }
}

# ----------------------------------------------------------------------------
# Cluster Access Configuration
# ----------------------------------------------------------------------------

variable "cluster_endpoint_private_access" {
  description = "Enable private access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public access to the cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ----------------------------------------------------------------------------
# Tags
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default = {
    CostCenter = "engineering"
  }
}

# ----------------------------------------------------------------------------
# Platform Configuration
# ----------------------------------------------------------------------------

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
}

variable "route53_zone_id" {
  description = "Route53 hosted zone ID for DNS management"
  type        = string
}

variable "domain_name" {
  description = "Base domain name for applications"
  type        = string
}

variable "cert_manager_email" {
  description = "Email address for Let's Encrypt certificate notifications"
  type        = string
}
