output "namespace" {
  description = "Namespace onde stack de observabilidade foi instalado"
  value       = kubernetes_namespace.observability.metadata[0].name
}

output "grafana_endpoint" {
  description = "Endpoint do Grafana (service interno)"
  value       = "http://kube-prometheus-stack-grafana.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local"
}

output "prometheus_endpoint" {
  description = "Endpoint do Prometheus (service interno)"
  value       = "http://kube-prometheus-stack-prometheus.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:9090"
}

output "loki_endpoint" {
  description = "Endpoint do Loki (service interno)"
  value       = "http://loki-gateway.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local"
}

output "alertmanager_endpoint" {
  description = "Endpoint do Alertmanager (service interno)"
  value       = "http://kube-prometheus-stack-alertmanager.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:9093"
}

output "otel_collector_endpoint" {
  description = "Endpoint do OpenTelemetry Collector (service interno)"
  value       = "http://opentelemetry-collector.${kubernetes_namespace.observability.metadata[0].name}.svc.cluster.local:4317"
}

output "grafana_admin_user" {
  description = "Usuário admin do Grafana"
  value       = "admin"
}
