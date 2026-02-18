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
  }
}

# Namespace para observabilidade
resource "kubernetes_namespace" "observability" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# kube-prometheus-stack (Prometheus + Grafana + Alertmanager)
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.chart_version_prometheus
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [
    yamlencode({
      # Prometheus configuration
      prometheus = {
        prometheusSpec = {
          retention = "${var.prometheus_retention_days}d"
          
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.prometheus_storage_size
                  }
                }
              }
            }
          }

          nodeSelector = var.node_selector
          tolerations  = var.tolerations

          # Service monitors para descoberta automática
          serviceMonitorSelectorNilUsesHelmValues = false
          podMonitorSelectorNilUsesHelmValues     = false
        }
      }

      # Grafana configuration
      grafana = {
        enabled = true
        
        adminPassword = var.grafana_admin_password
        
        persistence = {
          enabled          = true
          storageClassName = var.storage_class
          size             = "10Gi"
        }

        nodeSelector = var.node_selector
        tolerations  = var.tolerations

        # Datasources pré-configurados
        additionalDataSources = [
          {
            name   = "Loki"
            type   = "loki"
            url    = "http://loki-gateway.${var.namespace}.svc.cluster.local"
            access = "proxy"
          },
          {
            name   = "Tempo"
            type   = "tempo"
            url    = "http://tempo.${var.namespace}.svc.cluster.local:3100"
            access = "proxy"
          }
        ]

        # Dashboards pré-configurados
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [{
              name            = "default"
              orgId           = 1
              folder          = ""
              type            = "file"
              disableDeletion = false
              editable        = true
              options = {
                path = "/var/lib/grafana/dashboards/default"
              }
            }]
          }
        }
      }

      # Alertmanager configuration
      alertmanager = {
        alertmanagerSpec = {
          nodeSelector = var.node_selector
          tolerations  = var.tolerations
          
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }

      # Prometheus Operator
      prometheusOperator = {
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Node exporter (coleta métricas dos nodes)
      nodeExporter = {
        enabled = true
      }

      # Kube state metrics
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  timeout = 600
}

# Loki (agregação de logs)
resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.chart_version_loki
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [
    yamlencode({
      loki = {
        auth_enabled = false
        
        commonConfig = {
          replication_factor = 1
        }

        storage = {
          type = "filesystem"
        }

        limits_config = {
          retention_period = "${var.loki_retention_days * 24}h"
          
          # Limites de ingestão
          ingestion_rate_mb        = 10
          ingestion_burst_size_mb  = 20
          per_stream_rate_limit    = "5MB"
          per_stream_rate_limit_burst = "10MB"
        }

        compactor = {
          retention_enabled = true
          delete_request_store = "filesystem"
        }
      }

      # Modo single binary para simplicidade
      deploymentMode = "SingleBinary"

      singleBinary = {
        replicas = 1
        
        persistence = {
          enabled          = true
          storageClass     = var.storage_class
          size             = var.loki_storage_size
        }

        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Gateway para acesso
      gateway = {
        enabled = true
        nodeSelector = var.node_selector
        tolerations  = var.tolerations
      }

      # Desabilitar componentes não necessários em single binary
      backend = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      write = {
        replicas = 0
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}

# Promtail (coleta logs dos pods e envia para Loki)
resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.15.3"
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [
    yamlencode({
      config = {
        clients = [{
          url = "http://loki-gateway.${var.namespace}.svc.cluster.local/loki/api/v1/push"
        }]
      }

      # Promtail roda em todos os nodes como DaemonSet
      tolerations = [{
        effect   = "NoSchedule"
        operator = "Exists"
      }]
    })
  ]

  depends_on = [helm_release.loki]
}

# OpenTelemetry Collector (coleta traces)
resource "helm_release" "opentelemetry_collector" {
  name       = "opentelemetry-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = var.chart_version_otel
  namespace  = kubernetes_namespace.observability.metadata[0].name

  values = [
    yamlencode({
      mode = "deployment"

      config = {
        receivers = {
          otlp = {
            protocols = {
              grpc = {
                endpoint = "0.0.0.0:4317"
              }
              http = {
                endpoint = "0.0.0.0:4318"
              }
            }
          }
        }

        processors = {
          batch = {}
          memory_limiter = {
            check_interval  = "1s"
            limit_mib       = 512
            spike_limit_mib = 128
          }
        }

        exporters = {
          # Exportar para Prometheus
          prometheus = {
            endpoint = "0.0.0.0:8889"
          }
          
          # Logging para debug
          logging = {
            loglevel = "info"
          }
        }

        service = {
          pipelines = {
            traces = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["logging"]
            }
            metrics = {
              receivers  = ["otlp"]
              processors = ["memory_limiter", "batch"]
              exporters  = ["prometheus"]
            }
          }
        }
      }

      nodeSelector = var.node_selector
      tolerations  = var.tolerations
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}
