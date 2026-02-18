variable "engine" {
  description = "Policy engine a usar (kyverno ou gatekeeper)"
  type        = string
  default     = "kyverno"

  validation {
    condition     = contains(["kyverno", "gatekeeper"], var.engine)
    error_message = "Engine deve ser 'kyverno' ou 'gatekeeper'"
  }
}

variable "enforcement_mode" {
  description = "Modo de enforcement (audit ou enforce)"
  type        = string
  default     = "audit"

  validation {
    condition     = contains(["audit", "enforce"], var.enforcement_mode)
    error_message = "Modo deve ser 'audit' ou 'enforce'"
  }
}

variable "policies" {
  description = "Políticas a habilitar"
  type = object({
    block_privileged      = bool
    require_non_root      = bool
    require_resources     = bool
    block_latest_tag      = bool
    require_labels        = bool
    restrict_capabilities = bool
  })
  default = {
    block_privileged      = true
    require_non_root      = true
    require_resources     = true
    block_latest_tag      = true
    require_labels        = false
    restrict_capabilities = true
  }
}

variable "namespace" {
  description = "Namespace para instalar o policy engine"
  type        = string
  default     = "policy-system"
}

variable "chart_version_kyverno" {
  description = "Versão do Helm chart do Kyverno"
  type        = string
  default     = "3.1.0"
}

variable "chart_version_gatekeeper" {
  description = "Versão do Helm chart do Gatekeeper"
  type        = string
  default     = "3.14.0"
}

variable "node_selector" {
  description = "Node selector para pods do policy engine"
  type        = map(string)
  default     = { "role" = "system" }
}

variable "tolerations" {
  description = "Tolerations para pods do policy engine"
  type        = list(any)
  default = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}
