variable "environment" {
  description = "Ambiente (staging ou prod)"
  type        = string

  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "Ambiente deve ser 'staging' ou 'prod'"
  }
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "audit_log_retention_days" {
  description = "Dias de retenção de logs de auditoria"
  type        = number
  default     = 90
}

variable "enable_cloudtrail" {
  description = "Habilitar CloudTrail"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Habilitar AWS Config"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Habilitar GuardDuty"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para aplicar nos recursos"
  type        = map(string)
  default     = {}
}
