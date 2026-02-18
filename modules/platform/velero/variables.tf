variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN do OIDC provider do cluster"
  type        = string
}

variable "oidc_issuer_url" {
  description = "URL do OIDC issuer do cluster"
  type        = string
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "backup_schedule" {
  description = "Schedule cron para backups"
  type        = string
}

variable "backup_retention_days" {
  description = "Dias de retenção de backups"
  type        = number
}

variable "backup_bucket_name" {
  description = "Nome do bucket S3 para backups (será criado)"
  type        = string
}

variable "namespace" {
  description = "Namespace para instalar Velero"
  type        = string
  default     = "velero"
}

variable "chart_version" {
  description = "Versão do Helm chart do Velero"
  type        = string
  default     = "5.2.0"
}

variable "service_account_name" {
  description = "Nome da service account para Velero"
  type        = string
  default     = "velero"
}

variable "node_selector" {
  description = "Node selector para pods do Velero"
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = "Tolerations para pods do Velero"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}

variable "backup_namespaces" {
  description = "Lista de namespaces para incluir no backup (vazio = todos)"
  type        = list(string)
  default     = []
}

variable "exclude_namespaces" {
  description = "Lista de namespaces para excluir do backup"
  type        = list(string)
  default     = ["kube-system", "kube-public", "kube-node-lease"]
}

variable "enable_volume_snapshots" {
  description = "Habilitar snapshots de volumes EBS"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para aplicar no bucket S3"
  type        = map(string)
  default     = {}
}
