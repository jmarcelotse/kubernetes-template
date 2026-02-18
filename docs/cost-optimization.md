# Guia de Otimização de Custos

Este documento fornece estratégias para otimizar custos ao usar o template Terraform EKS AWS.

## Estimativas de Custos

### Staging Environment

| Componente | Especificação | Custo Mensal (USD) |
|------------|---------------|-------------------|
| EKS Control Plane | 1 cluster | $73.00 |
| EC2 Nodes - System | 2x t3.medium (24/7) | $60.74 |
| EC2 Nodes - Apps | 3x t3.large (24/7) | $182.22 |
| NAT Gateway | 1x single NAT | $32.85 |
| EBS Volumes | 5x 50GB gp3 | $20.00 |
| Data Transfer | ~100GB/mês | $9.00 |
| CloudWatch Logs | ~50GB/mês | $2.50 |
| S3 (state + backups) | ~10GB | $0.23 |
| **TOTAL STAGING** | | **~$380/mês** |

### Production Environment

| Componente | Especificação | Custo Mensal (USD) |
|------------|---------------|-------------------|
| EKS Control Plane | 1 cluster | $73.00 |
| EC2 Nodes - System | 3x t3.large (24/7) | $182.22 |
| EC2 Nodes - Apps | 10x m5.xlarge (24/7) | $1,752.00 |
| NAT Gateways | 3x multi-AZ | $98.55 |
| EBS Volumes | 13x 100GB gp3 | $104.00 |
| Data Transfer | ~500GB/mês | $45.00 |
| CloudWatch Logs | ~200GB/mês | $10.00 |
| S3 (state + backups) | ~50GB | $1.15 |
| Load Balancers | 2x ALB | $36.00 |
| **TOTAL PRODUCTION** | | **~$2,302/mês** |

*Valores para região us-east-1. Custos reais variam com uso.*

## Estratégias de Otimização

### 1. Compute (EC2)

#### Savings Plans

**Economia: até 72%**

```bash
# Analisar uso atual
aws ce get-savings-plans-coverage \
  --time-period Start=2024-01-01,End=2024-01-31

# Recomendações
aws ce get-savings-plans-purchase-recommendation \
  --savings-plans-type COMPUTE_SP \
  --term-in-years ONE_YEAR \
  --payment-option NO_UPFRONT
```

**Recomendação:**
- Production: Compute Savings Plan de 1 ano, sem upfront
- Economia estimada: $500-700/mês

#### Reserved Instances

**Economia: até 75%**

Para workloads previsíveis:
- System nodes: Reserved Instances de 1 ano
- Apps nodes (baseline): Reserved Instances de 1 ano
- Apps nodes (burst): On-Demand ou Spot

#### Spot Instances

**Economia: até 90%**

```hcl
# Exemplo de node group com Spot
node_groups = {
  apps_spot = {
    instance_types = ["m5.xlarge", "m5a.xlarge", "m5n.xlarge"]
    capacity_type  = "SPOT"
    min_size       = 0
    max_size       = 20
    desired_size   = 5
    
    labels = {
      role = "apps"
      lifecycle = "spot"
    }
    
    taints = [{
      key    = "spot"
      value  = "true"
      effect = "NoSchedule"
    }]
  }
}
```

**Workloads adequados para Spot:**
- Batch processing
- CI/CD pipelines
- Desenvolvimento/teste
- Workloads stateless com retry logic

**Workloads NÃO adequados:**
- Databases
- Stateful applications
- Real-time processing
- Workloads sem tolerância a interrupções

#### Right-sizing

```bash
# Analisar uso de recursos
kubectl top nodes
kubectl top pods -A

# Identificar pods com baixo uso
kubectl get pods -A -o json | jq -r '.items[] | 
  select(.status.phase=="Running") | 
  "\(.metadata.namespace)/\(.metadata.name)"' | 
  while read pod; do
    echo "=== $pod ==="
    kubectl top pod $pod
  done
```

**Ações:**
- Reduzir instance types se uso < 40%
- Aumentar se uso > 80% consistentemente
- Usar autoscaling para variações

### 2. Networking

#### NAT Gateway

**Economia: $65/mês em staging**

```hcl
# Staging: Single NAT Gateway
single_nat_gateway = true

# Production: Multi-AZ para HA (não otimizar)
single_nat_gateway = false
```

**Alternativas:**
- NAT Instances (mais barato, menos gerenciado)
- VPC Endpoints (elimina tráfego via NAT)

#### VPC Endpoints

**Economia: $20-50/mês**

```hcl
# Criar endpoints para serviços AWS frequentemente usados
enable_vpc_endpoints = true

# Endpoints incluídos:
# - ECR (api + dkr): ~$14/mês
# - S3: gratuito (gateway endpoint)
# - STS: ~$7/mês
# - CloudWatch Logs: ~$7/mês
# - SSM: ~$7/mês
```

**Benefícios:**
- Reduz data transfer via NAT
- Melhora performance
- Aumenta segurança

#### Data Transfer

**Economia: variável**

- Usar CloudFront para conteúdo estático
- Comprimir dados em trânsito
- Manter tráfego dentro da mesma região
- Usar VPC endpoints quando possível

### 3. Storage

#### EBS Volumes

**Economia: 20-40%**

```hcl
# Usar gp3 ao invés de gp2
disk_type = "gp3"

# gp3: $0.08/GB/mês
# gp2: $0.10/GB/mês

# Right-size volumes
disk_size = 50  # staging
disk_size = 100 # prod (apenas se necessário)
```

**Snapshots:**
```bash
# Deletar snapshots antigos
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<=`2023-01-01`].[SnapshotId]' \
  --output text | xargs -n1 aws ec2 delete-snapshot --snapshot-id
```

#### S3

**Economia: 50-90%**

```hcl
# Lifecycle policies para backups
resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "transition-old-backups"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
```

### 4. Observability

#### CloudWatch Logs

**Economia: $5-20/mês**

```hcl
# Reduzir retenção
log_retention_days = 7  # staging
log_retention_days = 30 # prod

# Filtrar logs desnecessários
# Usar Loki para logs de aplicação (mais barato)
```

#### Prometheus/Grafana

**Economia: variável**

```hcl
# Reduzir retenção de métricas
prometheus_retention_days = 7  # staging
prometheus_retention_days = 30 # prod

# Reduzir scrape interval para métricas não críticas
scrape_interval = "60s"  # ao invés de 15s

# Usar remote write para Grafana Cloud (free tier)
```

### 5. Ambiente Staging

#### Shutdown Automático

**Economia: 65% em staging**

```bash
# Lambda para parar cluster fora do horário comercial
# Economia: ~$250/mês

# Parar nodes (manter control plane)
aws eks update-nodegroup-config \
  --cluster-name eks-staging \
  --nodegroup-name apps \
  --scaling-config minSize=0,maxSize=10,desiredSize=0
```

**Implementação:**
- Parar nodes: 19h-7h e fins de semana
- Manter apenas system nodes (1-2)
- Usar tags para identificar recursos

#### Recursos Reduzidos

```hcl
# Staging: configuração mínima
node_groups = {
  system = {
    instance_types = ["t3.small"]  # ao invés de t3.medium
    min_size       = 1
    max_size       = 2
    desired_size   = 1
  }
  
  apps = {
    instance_types = ["t3.medium"]  # ao invés de t3.large
    min_size       = 1
    max_size       = 5
    desired_size   = 2
  }
}
```

### 6. Autoscaling

#### Cluster Autoscaler

```yaml
# Configuração agressiva para reduzir custos
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-config
data:
  scale-down-enabled: "true"
  scale-down-delay-after-add: "5m"
  scale-down-unneeded-time: "5m"
  scale-down-utilization-threshold: "0.5"
```

#### Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### Vertical Pod Autoscaler

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  updatePolicy:
    updateMode: "Auto"
```

### 7. Monitoramento de Custos

#### AWS Cost Explorer

```bash
# Custos por serviço
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE

# Custos por tag
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

#### Budgets e Alertas

```hcl
resource "aws_budgets_budget" "eks_staging" {
  name              = "eks-staging-monthly"
  budget_type       = "COST"
  limit_amount      = "400"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["team@example.com"]
  }
}
```

#### Kubecost

```bash
# Instalar Kubecost para visibilidade de custos K8s
helm install kubecost kubecost/cost-analyzer \
  --namespace kubecost --create-namespace \
  --set kubecostToken="<token>"
```

## Plano de Otimização Recomendado

### Fase 1: Quick Wins (Semana 1)

1. ✅ Staging: Single NAT Gateway (-$65/mês)
2. ✅ Habilitar VPC Endpoints (-$30/mês)
3. ✅ Migrar EBS para gp3 (-$10/mês)
4. ✅ Reduzir retenção de logs (-$5/mês)

**Economia: ~$110/mês**

### Fase 2: Médio Prazo (Mês 1)

1. ✅ Right-size instances (-$200/mês)
2. ✅ Implementar autoscaling agressivo (-$150/mês)
3. ✅ Shutdown staging fora do horário (-$250/mês)
4. ✅ Lifecycle policies S3 (-$5/mês)

**Economia adicional: ~$605/mês**

### Fase 3: Longo Prazo (Mês 2-3)

1. ✅ Savings Plans para prod (-$600/mês)
2. ✅ Spot instances para workloads adequados (-$300/mês)
3. ✅ Reserved Instances para baseline (-$200/mês)

**Economia adicional: ~$1,100/mês**

### Total de Economia Potencial

- **Staging**: $380 → $115/mês (70% redução)
- **Production**: $2,302 → $1,487/mês (35% redução)
- **Total**: $2,682 → $1,602/mês (40% redução)
- **Economia anual**: ~$13,000

## Checklist de Otimização

### Compute
- [ ] Analisar uso de CPU/memória dos nodes
- [ ] Implementar autoscaling
- [ ] Avaliar Spot instances
- [ ] Considerar Savings Plans
- [ ] Right-size instance types

### Networking
- [ ] Single NAT em staging
- [ ] Habilitar VPC endpoints
- [ ] Otimizar data transfer
- [ ] Revisar load balancers

### Storage
- [ ] Migrar para gp3
- [ ] Right-size volumes
- [ ] Implementar lifecycle policies
- [ ] Deletar snapshots antigos

### Observability
- [ ] Reduzir retenção de logs
- [ ] Otimizar scrape intervals
- [ ] Filtrar logs desnecessários
- [ ] Considerar alternativas (Grafana Cloud)

### Staging
- [ ] Shutdown automático
- [ ] Reduzir instance types
- [ ] Minimizar réplicas
- [ ] Compartilhar recursos

### Monitoramento
- [ ] Configurar Cost Explorer
- [ ] Criar budgets e alertas
- [ ] Instalar Kubecost
- [ ] Revisar custos mensalmente

## Ferramentas Úteis

- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Pricing Calculator](https://calculator.aws/)
- [Kubecost](https://www.kubecost.com/)
- [Infracost](https://www.infracost.io/)
- [CloudHealth](https://www.cloudhealthtech.com/)

## Recursos

- [AWS EKS Best Practices - Cost Optimization](https://aws.github.io/aws-eks-best-practices/cost_optimization/)
- [AWS Well-Architected Framework - Cost Optimization](https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html)
- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
