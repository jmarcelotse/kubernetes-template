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

variable "secrets_manager_arns" {
  description = "Lista de ARNs de secrets no Secrets Manager que podem ser acessados"
  type        = list(string)
  default     = ["*"]
}

variable "ssm_parameter_arns" {
  description = "Lista de ARNs de parâmetros no SSM que podem ser acessados"
  type        = list(string)
  default     = ["*"]
}

variable "namespace" {
  description = "Namespace para instalar External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "chart_version" {
  description = "Versão do Helm chart do External Secrets Operator"
  type        = string
  default     = "0.9.11"
}

variable "service_account_name" {
  description = "Nome da service account para External Secrets Operator"
  type        = string
  default     = "external-secrets"
}

variable "node_selector" {
  description = "Node selector para pods do External Secrets Operator"
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = "Tolerations para pods do External Secrets Operator"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}
