# ============================================================================
# Variáveis de Configuração do Cluster EKS
# ============================================================================

# ----------------------------------------------------------------------------
# Configuração Básica do Cluster
# ----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Nome do cluster EKS. Deve ser único na região AWS."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{0,99}$", var.cluster_name))
    error_message = "Nome do cluster deve começar com letra, conter apenas letras, números e hífens, e ter no máximo 100 caracteres."
  }
}

variable "cluster_version" {
  description = "Versão do Kubernetes para o cluster EKS. Deve ser uma versão suportada pela AWS."
  type        = string
  default     = "1.28"

  validation {
    condition     = can(regex("^1\\.(2[4-9]|30)$", var.cluster_version))
    error_message = "Versão do Kubernetes deve estar entre 1.24 e 1.30."
  }
}

variable "tags" {
  description = "Tags para aplicar em todos os recursos criados pelo módulo. Útil para organização, billing e compliance."
  type        = map(string)
  default     = {}
}

# ----------------------------------------------------------------------------
# Configuração de Rede - VPC
# ----------------------------------------------------------------------------

variable "vpc_cidr" {
  description = "CIDR block para a VPC. Deve ser um range privado válido (ex: 10.0.0.0/16)."
  type        = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "CIDR block inválido. Deve ser um CIDR válido no formato X.X.X.X/X."
  }
}

variable "availability_zones" {
  description = "Lista de zonas de disponibilidade para distribuir recursos. Mínimo de 2 AZs recomendado para alta disponibilidade."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Deve especificar no mínimo 2 zonas de disponibilidade para alta disponibilidade."
  }
}

# ----------------------------------------------------------------------------
# Configuração de NAT Gateway
# ----------------------------------------------------------------------------

variable "enable_nat_gateway" {
  description = "Habilitar NAT Gateway para permitir que recursos em subnets privadas acessem a internet. Necessário para download de imagens de container."
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Usar apenas um NAT Gateway compartilhado entre todas as AZs (economia de custos). Recomendado apenas para ambientes não-produtivos."
  type        = bool
  default     = false
}

# ----------------------------------------------------------------------------
# Configuração de VPC Endpoints
# ----------------------------------------------------------------------------

variable "enable_vpc_endpoints" {
  description = "Criar VPC endpoints para serviços AWS (ECR, STS, CloudWatch, SSM). Reduz custos de tráfego e melhora segurança."
  type        = bool
  default     = true
}

# ----------------------------------------------------------------------------
# Configuração de Logs do Control Plane
# ----------------------------------------------------------------------------

variable "enable_control_plane_logs" {
  description = "Habilitar logs do control plane do EKS para CloudWatch. Importante para auditoria e troubleshooting."
  type        = bool
  default     = true
}

variable "control_plane_log_types" {
  description = "Tipos de logs do control plane a habilitar. Opções: api, audit, authenticator, controllerManager, scheduler."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.control_plane_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Tipos de log válidos são: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "control_plane_log_retention_days" {
  description = "Número de dias para reter logs do control plane no CloudWatch."
  type        = number
  default     = 7

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.control_plane_log_retention_days)
    error_message = "Retenção deve ser um dos valores válidos do CloudWatch Logs."
  }
}

# ----------------------------------------------------------------------------
# Configuração de Criptografia
# ----------------------------------------------------------------------------

variable "enable_secrets_encryption" {
  description = "Habilitar criptografia de secrets do Kubernetes usando chave KMS dedicada. Recomendado para ambientes produtivos."
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "Janela de espera em dias antes de deletar a chave KMS (7-30 dias)."
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "Janela de deleção deve estar entre 7 e 30 dias."
  }
}

# ----------------------------------------------------------------------------
# Configuração de Node Groups
# ----------------------------------------------------------------------------

variable "node_groups" {
  description = <<-EOT
    Configuração dos node groups do EKS. Cada node group deve especificar:
    - instance_types: Lista de tipos de instância EC2
    - min_size: Número mínimo de nodes
    - max_size: Número máximo de nodes para autoscaling
    - desired_size: Número desejado de nodes inicialmente
    - disk_size: Tamanho do disco em GB
    - labels: Labels Kubernetes para node selection
    - taints: Taints para controlar scheduling de pods
  EOT
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

  validation {
    condition = alltrue([
      for ng_name, ng in var.node_groups :
      ng.min_size >= 0 && ng.max_size >= ng.min_size && ng.desired_size >= ng.min_size && ng.desired_size <= ng.max_size
    ])
    error_message = "Para cada node group: min_size >= 0, max_size >= min_size, e desired_size deve estar entre min_size e max_size."
  }

  validation {
    condition = alltrue([
      for ng_name, ng in var.node_groups :
      ng.disk_size >= 20
    ])
    error_message = "Disk size deve ser no mínimo 20 GB."
  }

  validation {
    condition = alltrue([
      for ng_name, ng in var.node_groups :
      length(ng.instance_types) > 0
    ])
    error_message = "Cada node group deve especificar pelo menos um instance type."
  }
}

# ----------------------------------------------------------------------------
# Configuração de Acesso ao Cluster
# ----------------------------------------------------------------------------

variable "cluster_endpoint_private_access" {
  description = "Habilitar acesso privado ao endpoint do cluster EKS (via VPC)."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar acesso público ao endpoint do cluster EKS. Pode ser restrito por CIDR."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "Lista de CIDRs permitidos para acessar o endpoint público do cluster. Use ['0.0.0.0/0'] para acesso irrestrito (não recomendado para produção)."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.cluster_endpoint_public_access_cidrs :
      can(cidrhost(cidr, 0))
    ])
    error_message = "Todos os CIDRs devem ser válidos."
  }
}

# ----------------------------------------------------------------------------
# Configuração de Ambiente
# ----------------------------------------------------------------------------

variable "environment" {
  description = "Ambiente de deployment (staging, prod). Usado para aplicar configurações específicas por ambiente."
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Ambiente deve ser 'staging' ou 'prod'."
  }
}
