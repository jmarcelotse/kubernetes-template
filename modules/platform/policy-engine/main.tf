terraform {
  required_version = ">= 1.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

# Namespace para policy engine
resource "kubernetes_namespace" "policy_engine" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Instalação do Kyverno
resource "helm_release" "kyverno" {
  count = var.engine == "kyverno" ? 1 : 0

  name       = "kyverno"
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = var.chart_version_kyverno
  namespace  = kubernetes_namespace.policy_engine.metadata[0].name

  values = [
    yamlencode({
      admissionController = {
        replicas = 3
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
      backgroundController = {
        replicas = 2
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
      cleanupController = {
        replicas = 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
      reportsController = {
        replicas = 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
    })
  ]
}

# Instalação do Gatekeeper
resource "helm_release" "gatekeeper" {
  count = var.engine == "gatekeeper" ? 1 : 0

  name       = "gatekeeper"
  repository = "https://open-policy-agent.github.io/gatekeeper/charts"
  chart      = "gatekeeper"
  version    = var.chart_version_gatekeeper
  namespace  = kubernetes_namespace.policy_engine.metadata[0].name

  values = [
    yamlencode({
      replicas = 3
      nodeSelector = var.node_selector
      tolerations  = var.tolerations
      audit = {
        replicas = 1
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
    })
  ]
}

# Aguardar instalação antes de aplicar políticas
resource "time_sleep" "wait_for_policy_engine" {
  depends_on = [
    helm_release.kyverno,
    helm_release.gatekeeper
  ]

  create_duration = "30s"
}
