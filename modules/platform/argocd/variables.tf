# ============================================================================
# Variáveis de Configuração do ArgoCD
# ============================================================================

# ----------------------------------------------------------------------------
# Configuração Básica
# ----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Nome do cluster EKS onde o ArgoCD será instalado. Usado para tagging e identificação."
  type        = string
}

variable "namespace" {
  description = "Namespace Kubernetes onde o ArgoCD será instalado. Será criado se não existir."
  type        = string
  default     = "argocd"

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace))
    error_message = "Namespace deve seguir convenções DNS: letras minúsculas, números e hífens, começando e terminando com alfanumérico."
  }
}

# ----------------------------------------------------------------------------
# Configuração do Helm Chart
# ----------------------------------------------------------------------------

variable "chart_version" {
  description = "Versão do Helm chart do ArgoCD a ser instalado. Recomenda-se fixar a versão para ambientes produtivos."
  type        = string
  default     = "5.51.0"
}

variable "chart_repository" {
  description = "URL do repositório Helm contendo o chart do ArgoCD."
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

# ----------------------------------------------------------------------------
# Configuração de Scheduling
# ----------------------------------------------------------------------------

variable "node_selector" {
  description = "Node selector para agendar pods do ArgoCD em nodes específicos. Útil para isolar componentes de plataforma."
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = <<-EOT
    Tolerations para permitir que pods do ArgoCD sejam agendados em nodes com taints.
    Por padrão, tolera o taint CriticalAddonsOnly usado no node group system.
  EOT
  type = list(object({
    key      = string
    operator = string
    value    = optional(string)
    effect   = string
  }))
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}

# ----------------------------------------------------------------------------
# Configuração de Valores Customizados
# ----------------------------------------------------------------------------

variable "values" {
  description = <<-EOT
    Valores customizados adicionais para o Helm chart do ArgoCD.
    Estes valores serão mesclados com as configurações padrão do módulo.
    Use para configurações avançadas não cobertas pelas variáveis do módulo.
  EOT
  type        = any
  default     = {}
}

# ----------------------------------------------------------------------------
# Configuração de Alta Disponibilidade
# ----------------------------------------------------------------------------

variable "enable_ha" {
  description = "Habilitar modo de alta disponibilidade com múltiplas réplicas dos componentes do ArgoCD."
  type        = bool
  default     = false
}

variable "replicas" {
  description = "Número de réplicas para componentes do ArgoCD quando HA está habilitado."
  type = object({
    server                 = number
    repo_server            = number
    application_controller = number
  })
  default = {
    server                 = 2
    repo_server            = 2
    application_controller = 1
  }

  validation {
    condition     = var.replicas.server >= 1 && var.replicas.repo_server >= 1 && var.replicas.application_controller >= 1
    error_message = "Todas as réplicas devem ser no mínimo 1."
  }
}

# ----------------------------------------------------------------------------
# Configuração de Recursos
# ----------------------------------------------------------------------------

variable "resources" {
  description = "Requisitos de recursos (CPU e memória) para os componentes do ArgoCD."
  type = object({
    server = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    repo_server = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
    application_controller = object({
      requests = object({
        cpu    = string
        memory = string
      })
      limits = object({
        cpu    = string
        memory = string
      })
    })
  })
  default = {
    server = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    repo_server = {
      requests = {
        cpu    = "100m"
        memory = "128Mi"
      }
      limits = {
        cpu    = "200m"
        memory = "256Mi"
      }
    }
    application_controller = {
      requests = {
        cpu    = "250m"
        memory = "512Mi"
      }
      limits = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
  }
}

# ----------------------------------------------------------------------------
# Configuração de Tags
# ----------------------------------------------------------------------------

variable "tags" {
  description = "Tags para aplicar aos recursos criados pelo módulo. Útil para organização, billing e compliance."
  type        = map(string)
  default     = {}
}
