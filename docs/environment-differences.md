# Diferenças entre Ambientes: Staging vs Production

Este documento detalha as diferenças de configuração entre os ambientes staging e production, explicando as razões por trás de cada escolha.

## Visão Geral

O template implementa dois ambientes completamente isolados:
- **Staging**: Otimizado para custo, usado para testes e validação
- **Production**: Otimizado para resiliência e performance, usado para workloads críticos

## Diferenças de Configuração

### 1. Isolamento de Recursos

| Aspecto | Staging | Production |
|---------|---------|------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 |
| **Cluster Name** | eks-staging | eks-prod |
| **State Path** | staging/terraform.tfstate | prod/terraform.tfstate |
| **Environment Tag** | staging | prod |

**Razão**: Isolamento completo garante que mudanças em um ambiente não afetem o outro.

### 2. Alta Disponibilidade

| Aspecto | Staging | Production |
|---------|---------|------------|
| **NAT Gateway** | Single (1 NAT compartilhado) | Multi-AZ (1 NAT por AZ) |
| **Custo Mensal NAT** | ~$32/mês | ~$96/mês (3 AZs) |
| **Resiliência** | Ponto único de falha | Sem ponto único de falha |

**Razão**: Staging prioriza economia de custos (~$64/mês de economia), enquanto production prioriza disponibilidade.

### 3. Node Groups - System

| Aspecto | Staging | Production |
|---------|---------|------------|
| **Instance Type** | t3.medium | t3.large |
| **Min Size** | 2 | 3 |
| **Max Size** | 3 | 5 |
| **Desired Size** | 2 | 3 |
| **Disk Size** | 50 GB | 100 GB |
| **vCPU Total** | 4 vCPUs | 6 vCPUs |
| **Memory Total** | 8 GB | 12 GB |

**Razão**: Production precisa de mais recursos para componentes críticos do sistema (ArgoCD, monitoring, etc.).

### 4. Node Groups - Apps

| Aspecto | Staging | Production |
|---------|---------|------------|
| **Instance Types** | t3.large | m5.xlarge, m5.2xlarge |
| **Min Size** | 2 | 5 |
| **Max Size** | 10 | 50 |
| **Desired Size** | 3 | 10 |
| **Disk Size** | 100 GB | 200 GB |
| **vCPU Range** | 6-20 vCPUs | 20-200 vCPUs |
| **Memory Range** | 12-40 GB | 80-800 GB |

**Razão**: 
- Staging usa instâncias burstable (t3) para economia
- Production usa instâncias compute-optimized (m5) para performance consistente
- Production tem capacidade de escalar 5x mais para lidar com picos de tráfego

### 5. Autoscaling

| Aspecto | Staging | Production |
|---------|---------|------------|
| **System Scaling** | Conservador (2-3 nodes) | Moderado (3-5 nodes) |
| **Apps Scaling** | Conservador (2-10 nodes) | Agressivo (5-50 nodes) |
| **Scaling Ratio** | 5x | 10x |

**Razão**: Production precisa responder rapidamente a aumentos de carga, enquanto staging pode ter escalonamento mais lento.

### 6. Logs e Retenção

| Aspecto | Staging | Production |
|---------|---------|------------|
| **Control Plane Logs** | Habilitado | Habilitado |
| **Log Types** | Todos (5 tipos) | Todos (5 tipos) |
| **Retenção** | 7 dias | 30 dias |
| **Custo Mensal Logs** | ~$5/mês | ~$20/mês |

**Razão**: Production mantém logs por mais tempo para auditoria e troubleshooting de incidentes passados.

### 7. Criptografia

| Aspecto | Staging | Production |
|---------|---------|------------|
| **Secrets Encryption** | Habilitado | Habilitado |
| **KMS Key** | Dedicada | Dedicada |
| **Deletion Window** | 30 dias | 30 dias |

**Razão**: Ambos os ambientes usam criptografia por padrão para segurança.

### 8. Acesso ao Cluster

| Aspecto | Staging | Production |
|---------|---------|------------|
| **Private Access** | Habilitado | Habilitado |
| **Public Access** | Habilitado | Habilitado |
| **Public CIDR** | 0.0.0.0/0 | 0.0.0.0/0 |

**Razão**: Ambos permitem acesso público para facilitar CI/CD. Em produção real, recomenda-se restringir o CIDR público.

## Estimativa de Custos Mensais

### Staging (Configuração Econômica)

| Recurso | Quantidade | Custo Unitário | Custo Total |
|---------|------------|----------------|-------------|
| NAT Gateway | 1 | $32/mês | $32 |
| t3.medium (system) | 2 | $30/mês | $60 |
| t3.large (apps) | 3 | $60/mês | $180 |
| EBS gp3 (system) | 100 GB | $8/mês | $8 |
| EBS gp3 (apps) | 300 GB | $24/mês | $24 |
| EKS Control Plane | 1 | $73/mês | $73 |
| CloudWatch Logs | - | ~$5/mês | $5 |
| **Total Estimado** | | | **~$382/mês** |

### Production (Configuração Resiliente)

| Recurso | Quantidade | Custo Unitário | Custo Total |
|---------|------------|----------------|-------------|
| NAT Gateway | 3 | $32/mês | $96 |
| t3.large (system) | 3 | $60/mês | $180 |
| m5.xlarge (apps) | 10 | $140/mês | $1,400 |
| EBS gp3 (system) | 300 GB | $24/mês | $24 |
| EBS gp3 (apps) | 2000 GB | $160/mês | $160 |
| EKS Control Plane | 1 | $73/mês | $73 |
| CloudWatch Logs | - | ~$20/mês | $20 |
| **Total Estimado** | | | **~$1,953/mês** |

**Nota**: Custos são estimativas baseadas em us-east-1. Custos reais variam com uso de rede, storage adicional, e outros serviços.

## Otimizações de Custo Recomendadas

### Para Staging
1. **Desligar fora do horário comercial**: Pode economizar ~60% dos custos de compute
2. **Usar Spot Instances**: Pode economizar até 70% nos custos de nodes
3. **Reduzir desired_size**: Manter apenas 1 system node e 2 app nodes quando não em uso

### Para Production
1. **Savings Plans**: Compromisso de 1-3 anos pode economizar até 40%
2. **Reserved Instances**: Para workloads previsíveis
3. **Spot Instances para apps não-críticas**: Misturar On-Demand e Spot
4. **Right-sizing**: Monitorar uso e ajustar instance types conforme necessário

## Próximos Passos

Após provisionar os ambientes, considere:

1. **Configurar Cluster Autoscaler**: Para escalonamento automático baseado em demanda
2. **Implementar Pod Disruption Budgets**: Para garantir disponibilidade durante updates
3. **Configurar HPA (Horizontal Pod Autoscaler)**: Para escalonamento de aplicações
4. **Implementar Network Policies**: Para segmentação de rede entre namespaces
5. **Configurar Backup com Velero**: Para disaster recovery

## Referências

- [AWS EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [EC2 Instance Pricing](https://aws.amazon.com/ec2/pricing/on-demand/)
- [NAT Gateway Pricing](https://aws.amazon.com/vpc/pricing/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
