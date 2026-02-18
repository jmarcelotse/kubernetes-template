variable "environment" {
  description = "Ambiente (staging, prod)"
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Ambiente deve ser 'staging' ou 'prod'"
  }
}

variable "prometheus_retention_days" {
  description = "Dias de retenção de métricas no Prometheus"
  type        = number
}

variable "loki_retention_days" {
  description = "Dias de retenção de logs no Loki"
  type        = number
}

variable "grafana_admin_password" {
  description = "Senha do admin do Grafana"
  type        = string
  sensitive   = true
}

variable "storage_class" {
  description = "Storage class para persistent volumes"
  type        = string
  default     = "gp3"
}

variable "prometheus_storage_size" {
  description = "Tamanho do volume para Prometheus"
  type        = string
  default     = "50Gi"
}

variable "loki_storage_size" {
  description = "Tamanho do volume para Loki"
  type        = string
  default     = "100Gi"
}

variable "namespace" {
  description = "Namespace para stack de observabilidade"
  type        = string
  default     = "observability"
}

variable "chart_version_prometheus" {
  description = "Versão do Helm chart do kube-prometheus-stack"
  type        = string
  default     = "55.5.0"
}

variable "chart_version_loki" {
  description = "Versão do Helm chart do Loki"
  type        = string
  default     = "5.41.0"
}

variable "chart_version_otel" {
  description = "Versão do Helm chart do OpenTelemetry Collector"
  type        = string
  default     = "0.78.0"
}

variable "node_selector" {
  description = "Node selector para pods de observabilidade"
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = "Tolerations para pods de observabilidade"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}
