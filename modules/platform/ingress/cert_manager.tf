# cert-manager para gerenciamento de certificados TLS

# Instalação do cert-manager via Helm
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.chart_version_cert_manager
  namespace  = kubernetes_namespace.cert_manager.metadata[0].name

  values = [
    yamlencode({
      installCRDs = true

      nodeSelector = var.node_selector
      tolerations  = var.tolerations

      webhook = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      cainjector = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      prometheus = {
        enabled = true
        servicemonitor = {
          enabled = true
        }
      }
    })
  ]
}

# Aguardar instalação do cert-manager
resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]

  create_duration = "30s"
}

# ClusterIssuer para Let's Encrypt
resource "kubernetes_manifest" "letsencrypt_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-${var.letsencrypt_environment}"
    }
    spec = {
      acme = {
        server = var.letsencrypt_environment == "production" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
        email  = var.cert_manager_email
        privateKeySecretRef = {
          name = "letsencrypt-${var.letsencrypt_environment}"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = var.ingress_type == "alb" ? "alb" : "nginx"
            }
          }
        }]
      }
    }
  }

  depends_on = [time_sleep.wait_for_cert_manager]
}
