# Ingress NGINX Controller

resource "helm_release" "nginx_controller" {
  count = var.ingress_type == "nginx" ? 1 : 0

  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = var.chart_version_nginx
  namespace  = kubernetes_namespace.ingress.metadata[0].name

  values = [
    yamlencode({
      controller = {
        replicaCount = 2

        nodeSelector = var.node_selector
        tolerations  = var.tolerations

        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type"              = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
            "service.beta.kubernetes.io/aws-load-balancer-backend-protocol"  = "tcp"
          }
        }

        metrics = {
          enabled = true
          serviceMonitor = {
            enabled = true
          }
        }

        config = {
          use-forwarded-headers = "true"
          compute-full-forwarded-for = "true"
          use-proxy-protocol = "false"
        }
      }

      defaultBackend = {
        enabled = true
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }
    })
  ]
}
