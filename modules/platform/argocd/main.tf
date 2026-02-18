# ============================================================================
# Módulo ArgoCD - Bootstrap GitOps
# ============================================================================
# Este módulo instala o ArgoCD via Helm para habilitar GitOps no cluster EKS.
# O ArgoCD é instalado no node group "system" usando tolerations apropriadas.
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# ----------------------------------------------------------------------------
# Namespace para ArgoCD
# ----------------------------------------------------------------------------

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace

    labels = merge(
      {
        "app.kubernetes.io/name"       = "argocd"
        "app.kubernetes.io/component"  = "gitops"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.tags
    )
  }
}

# ----------------------------------------------------------------------------
# Instalação do ArgoCD via Helm
# ----------------------------------------------------------------------------

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = var.chart_repository
  chart      = "argo-cd"
  version    = var.chart_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  # Aguardar até que todos os recursos estejam prontos
  wait          = true
  wait_for_jobs = true
  timeout       = 600

  # Valores padrão do módulo
  values = [
    yamlencode({
      # Configuração global
      global = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Configuração do ArgoCD Server
      server = {
        replicas     = var.enable_ha ? var.replicas.server : 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
        resources    = var.resources.server

        # Configuração de métricas
        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }

      # Configuração do Repo Server
      repoServer = {
        replicas     = var.enable_ha ? var.replicas.repo_server : 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
        resources    = var.resources.repo_server

        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }

      # Configuração do Application Controller
      controller = {
        replicas     = var.enable_ha ? var.replicas.application_controller : 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
        resources    = var.resources.application_controller

        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }
      }

      # Configuração do Redis (usado para cache)
      redis = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Configuração do Dex (SSO/OAuth)
      dex = {
        enabled      = false # Desabilitado por padrão, pode ser habilitado via values customizados
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Configuração do ApplicationSet Controller
      applicationSet = {
        enabled      = true
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Configuração do Notifications Controller
      notifications = {
        enabled      = true
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Configurações de segurança
      configs = {
        params = {
          # Habilitar criação de namespaces automaticamente
          "application.namespaces" = "*"
        }
      }
    }),
    # Mesclar valores customizados fornecidos pelo usuário
    yamlencode(var.values)
  ]

  # Dependências
  depends_on = [
    kubernetes_namespace.argocd
  ]
}
