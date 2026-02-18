# ============================================================================
# Outputs do Módulo ArgoCD
# ============================================================================

# ----------------------------------------------------------------------------
# Outputs de Namespace
# ----------------------------------------------------------------------------

output "namespace" {
  description = "Namespace onde o ArgoCD foi instalado"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "namespace_uid" {
  description = "UID do namespace do ArgoCD"
  value       = kubernetes_namespace.argocd.metadata[0].uid
}

# ----------------------------------------------------------------------------
# Outputs de Service
# ----------------------------------------------------------------------------

output "server_service_name" {
  description = "Nome do service do ArgoCD server. Use para configurar ingress ou port-forward."
  value       = "argocd-server"
}

output "server_service_port" {
  description = "Porta do service do ArgoCD server"
  value       = 443
}

output "server_service_http_port" {
  description = "Porta HTTP do service do ArgoCD server (não-TLS)"
  value       = 80
}

# ----------------------------------------------------------------------------
# Outputs de Credenciais
# ----------------------------------------------------------------------------

output "initial_admin_password_secret" {
  description = <<-EOT
    Nome do secret Kubernetes contendo a senha inicial do usuário admin.
    Use: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  EOT
  value       = "argocd-initial-admin-secret"
}

output "admin_username" {
  description = "Nome de usuário padrão do admin do ArgoCD"
  value       = "admin"
}

# ----------------------------------------------------------------------------
# Outputs de Helm Release
# ----------------------------------------------------------------------------

output "helm_release_name" {
  description = "Nome do Helm release do ArgoCD"
  value       = helm_release.argocd.name
}

output "helm_release_version" {
  description = "Versão do Helm chart instalada"
  value       = helm_release.argocd.version
}

output "helm_release_status" {
  description = "Status do Helm release"
  value       = helm_release.argocd.status
}

output "helm_release_namespace" {
  description = "Namespace do Helm release"
  value       = helm_release.argocd.namespace
}

# ----------------------------------------------------------------------------
# Outputs de Acesso
# ----------------------------------------------------------------------------

output "access_instructions" {
  description = "Instruções para acessar o ArgoCD"
  value       = <<-EOT
    Para acessar o ArgoCD:
    
    1. Obter a senha inicial do admin:
       kubectl -n ${kubernetes_namespace.argocd.metadata[0].name} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    
    2. Port-forward para acessar localmente:
       kubectl port-forward svc/argocd-server -n ${kubernetes_namespace.argocd.metadata[0].name} 8080:443
    
    3. Acessar via navegador:
       https://localhost:8080
    
    4. Login:
       Username: admin
       Password: (obtida no passo 1)
    
    5. (Recomendado) Alterar a senha após primeiro login:
       argocd account update-password
  EOT
}

# ----------------------------------------------------------------------------
# Outputs de Componentes
# ----------------------------------------------------------------------------

output "components" {
  description = "Informações sobre os componentes do ArgoCD instalados"
  value = {
    server = {
      replicas = var.enable_ha ? var.replicas.server : 1
      service  = "argocd-server"
    }
    repo_server = {
      replicas = var.enable_ha ? var.replicas.repo_server : 1
      service  = "argocd-repo-server"
    }
    application_controller = {
      replicas = var.enable_ha ? var.replicas.application_controller : 1
    }
    redis = {
      service = "argocd-redis"
    }
    application_set = {
      enabled = true
    }
    notifications = {
      enabled = true
    }
  }
}

# ----------------------------------------------------------------------------
# Outputs de Configuração
# ----------------------------------------------------------------------------

output "chart_version" {
  description = "Versão do chart do ArgoCD instalada"
  value       = var.chart_version
}

output "high_availability_enabled" {
  description = "Indica se o modo de alta disponibilidade está habilitado"
  value       = var.enable_ha
}

output "node_selector" {
  description = "Node selector configurado para os pods do ArgoCD"
  value       = var.node_selector
}

output "tolerations" {
  description = "Tolerations configuradas para os pods do ArgoCD"
  value       = var.tolerations
}
