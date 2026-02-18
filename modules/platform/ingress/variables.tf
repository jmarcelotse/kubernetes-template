variable "ingress_type" {
  description = "Tipo de ingress controller (alb ou nginx)"
  type        = string
  default     = "alb"

  validation {
    condition     = contains(["alb", "nginx"], var.ingress_type)
    error_message = "Tipo deve ser 'alb' ou 'nginx'"
  }
}

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

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
}

variable "route53_zone_id" {
  description = "ID da zona Route53 para external-dns"
  type        = string
}

variable "domain_name" {
  description = "Nome de domínio base"
  type        = string
}

variable "cert_manager_email" {
  description = "Email para Let's Encrypt"
  type        = string
}

variable "namespace_ingress" {
  description = "Namespace para ingress controller"
  type        = string
  default     = "ingress"
}

variable "namespace_cert_manager" {
  description = "Namespace para cert-manager"
  type        = string
  default     = "cert-manager"
}

variable "namespace_external_dns" {
  description = "Namespace para external-dns"
  type        = string
  default     = "external-dns"
}

variable "chart_version_alb" {
  description = "Versão do Helm chart do AWS Load Balancer Controller"
  type        = string
  default     = "1.6.2"
}

variable "chart_version_nginx" {
  description = "Versão do Helm chart do ingress-nginx"
  type        = string
  default     = "4.8.3"
}

variable "chart_version_cert_manager" {
  description = "Versão do Helm chart do cert-manager"
  type        = string
  default     = "1.13.3"
}

variable "chart_version_external_dns" {
  description = "Versão do Helm chart do external-dns"
  type        = string
  default     = "1.14.0"
}

variable "node_selector" {
  description = "Node selector para pods de ingress"
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = "Tolerations para pods de ingress"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}

variable "letsencrypt_environment" {
  description = "Ambiente Let's Encrypt (staging ou production)"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["staging", "production"], var.letsencrypt_environment)
    error_message = "Ambiente deve ser 'staging' ou 'production'"
  }
}
