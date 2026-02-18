output "namespace" {
  description = "Namespace onde o policy engine foi instalado"
  value       = kubernetes_namespace.policy_engine.metadata[0].name
}

output "engine" {
  description = "Policy engine instalado (kyverno ou gatekeeper)"
  value       = var.engine
}

output "enforcement_mode" {
  description = "Modo de enforcement configurado (audit ou enforce)"
  value       = var.enforcement_mode
}

output "enabled_policies" {
  description = "Políticas habilitadas"
  value = {
    block_privileged      = var.policies.block_privileged
    require_non_root      = var.policies.require_non_root
    require_resources     = var.policies.require_resources
    block_latest_tag      = var.policies.block_latest_tag
    require_labels        = var.policies.require_labels
    restrict_capabilities = var.policies.restrict_capabilities
  }
}
