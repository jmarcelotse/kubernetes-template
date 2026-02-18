# Observability Stack Module

Este módulo instala e configura um stack completo de observabilidade no cluster Kubernetes com Prometheus, Grafana, Loki e OpenTelemetry Collector.

## Funcionalidades

- **Prometheus**: Coleta e armazenamento de métricas
- **Grafana**: Visualização de métricas, logs e traces
- **Alertmanager**: Gerenciamento de alertas
- **Loki**: Agregação e consulta de logs
- **Promtail**: Coleta de logs dos pods
- **OpenTelemetry Collector**: Coleta de traces e métricas
- Retenção configurável por ambiente
- Persistent volumes para armazenamento
- Dashboards e datasources pré-configurados

## Uso

```hcl
module "observability" {
  source = "../../modules/platform/observability"

  environment              = "staging"  # ou "prod"
  prometheus_retention_days = 7         # staging: 7, prod: 30
  loki_retention_days      = 3         # staging: 3, prod: 15
  grafana_admin_password   = "changeme"
  
  prometheus_storage_size = "50Gi"
  loki_storage_size       = "100Gi"
  storage_class           = "gp3"
}
```

## Diferenças entre Ambientes

### Staging
- Prometheus retention: 7 dias
- Loki retention: 3 dias
- Storage menor
- Configurações mais econômicas

### Production
- Prometheus retention: 30 dias
- Loki retention: 15 dias
- Storage maior
- Alta disponibilidade

## Acessando Grafana

### Port Forward

```bash
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80
```

Acesse: http://localhost:3000
- Usuário: `admin`
- Senha: valor de `grafana_admin_password`

### Via Ingress (recomendado para produção)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana
  namespace: observability
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - grafana.example.com
      secretName: grafana-tls
  rules:
    - host: grafana.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kube-prometheus-stack-grafana
                port:
                  number: 80
```

## Consultando Métricas

### Prometheus

```bash
# Port forward
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090

# Acesse: http://localhost:9090
```

Exemplos de queries PromQL:

```promql
# CPU usage por pod
sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)

# Memory usage por namespace
sum(container_memory_working_set_bytes) by (namespace)

# Request rate
rate(http_requests_total[5m])
```

### Grafana

Dashboards pré-instalados:
- Kubernetes / Compute Resources / Cluster
- Kubernetes / Compute Resources / Namespace
- Kubernetes / Compute Resources / Pod
- Node Exporter / Nodes

## Consultando Logs

### Via Grafana

1. Acesse Grafana
2. Vá para Explore
3. Selecione datasource "Loki"
4. Use LogQL para consultar logs

Exemplos de queries LogQL:

```logql
# Logs de um namespace
{namespace="default"}

# Logs de um pod específico
{pod="my-app-xyz"}

# Logs com erro
{namespace="default"} |= "error"

# Logs com filtro regex
{namespace="default"} |~ "error|exception"

# Agregação: contar erros por minuto
sum(rate({namespace="default"} |= "error" [1m]))
```

### Via kubectl

```bash
# Logs de um pod
kubectl logs -n default my-app-xyz

# Logs com follow
kubectl logs -n default my-app-xyz -f

# Logs de todos os containers de um pod
kubectl logs -n default my-app-xyz --all-containers
```

## Enviando Traces

### Configurar aplicação para enviar traces

```yaml
# Variáveis de ambiente para OpenTelemetry
env:
  - name: OTEL_EXPORTER_OTLP_ENDPOINT
    value: "http://opentelemetry-collector.observability.svc.cluster.local:4317"
  - name: OTEL_SERVICE_NAME
    value: "my-app"
  - name: OTEL_TRACES_SAMPLER
    value: "always_on"
```

### Exemplo em Python

```python
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

# Configurar tracer
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# Configurar exporter
otlp_exporter = OTLPSpanExporter(
    endpoint="opentelemetry-collector.observability.svc.cluster.local:4317",
    insecure=True
)
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(otlp_exporter)
)

# Criar span
with tracer.start_as_current_span("my-operation"):
    # Seu código aqui
    pass
```

## Alertas

### Criar AlertmanagerConfig

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: example-alerts
  namespace: observability
spec:
  route:
    groupBy: ['alertname']
    groupWait: 10s
    groupInterval: 10s
    repeatInterval: 12h
    receiver: 'slack'
  
  receivers:
    - name: 'slack'
      slackConfigs:
        - apiURL: 'https://hooks.slack.com/services/YOUR/WEBHOOK/URL'
          channel: '#alerts'
          title: '{{ .GroupLabels.alertname }}'
          text: '{{ range .Alerts }}{{ .Annotations.description }}{{ end }}'
```

### Criar PrometheusRule

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: example-rules
  namespace: observability
spec:
  groups:
    - name: example
      interval: 30s
      rules:
        - alert: HighPodMemory
          expr: |
            sum(container_memory_working_set_bytes{pod!=""}) by (pod, namespace) 
            / sum(container_spec_memory_limit_bytes{pod!=""}) by (pod, namespace) 
            > 0.9
          for: 5m
          labels:
            severity: warning
          annotations:
            summary: "Pod {{ $labels.pod }} high memory usage"
            description: "Pod {{ $labels.pod }} in namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of memory limit"
```

## Monitorando Aplicações Customizadas

### ServiceMonitor

Para que Prometheus colete métricas da sua aplicação:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  namespace: default
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
      interval: 30s
      path: /metrics
```

Sua aplicação deve expor métricas no formato Prometheus em `/metrics`.

## Troubleshooting

### Prometheus não coleta métricas

1. Verificar ServiceMonitor:
```bash
kubectl get servicemonitor -A
kubectl describe servicemonitor my-app -n default
```

2. Verificar targets no Prometheus:
- Acesse Prometheus UI
- Vá para Status > Targets
- Verifique se seu service aparece e está UP

3. Verificar labels do Service:
```bash
kubectl get svc my-app -n default -o yaml
```

### Loki não recebe logs

1. Verificar Promtail:
```bash
kubectl get pods -n observability -l app.kubernetes.io/name=promtail
kubectl logs -n observability -l app.kubernetes.io/name=promtail
```

2. Verificar Loki:
```bash
kubectl logs -n observability -l app.kubernetes.io/name=loki
```

### Grafana não carrega dashboards

1. Verificar datasources:
- Acesse Grafana
- Vá para Configuration > Data Sources
- Teste conexão com Prometheus e Loki

2. Verificar logs:
```bash
kubectl logs -n observability -l app.kubernetes.io/name=grafana
```

## Otimização de Custos

### Staging

- Retenção menor (7 dias métricas, 3 dias logs)
- Storage menor
- Menos réplicas
- Sampling de traces mais agressivo

### Production

- Retenção maior (30 dias métricas, 15 dias logs)
- Storage maior
- Alta disponibilidade
- Sampling de traces configurável

### Reduzir Custos

1. Ajustar retenção baseado em necessidade
2. Usar storage class mais econômico (gp2 vs gp3)
3. Configurar sampling de traces (não coletar 100%)
4. Limitar métricas coletadas (usar relabeling)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Ambiente (staging ou prod) | string | - | yes |
| prometheus_retention_days | Dias de retenção Prometheus | number | - | yes |
| loki_retention_days | Dias de retenção Loki | number | - | yes |
| grafana_admin_password | Senha admin Grafana | string | - | yes |
| storage_class | Storage class para PVs | string | "gp3" | no |
| prometheus_storage_size | Tamanho volume Prometheus | string | "50Gi" | no |
| loki_storage_size | Tamanho volume Loki | string | "100Gi" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace da stack |
| grafana_endpoint | Endpoint do Grafana |
| prometheus_endpoint | Endpoint do Prometheus |
| loki_endpoint | Endpoint do Loki |
| alertmanager_endpoint | Endpoint do Alertmanager |
| otel_collector_endpoint | Endpoint do OTEL Collector |
