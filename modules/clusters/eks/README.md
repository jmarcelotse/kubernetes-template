# Módulo EKS - Cluster Kubernetes na AWS

Este módulo Terraform provisiona um cluster Amazon EKS (Elastic Kubernetes Service) completo com toda a infraestrutura de rede necessária.

## Recursos Criados

### Rede VPC
- **VPC**: VPC dedicada com DNS habilitado
- **Subnets Públicas**: Uma subnet pública por AZ para NAT Gateways e Load Balancers
- **Subnets Privadas**: Uma subnet privada por AZ para nodes do EKS
- **Internet Gateway**: Para acesso à internet das subnets públicas
- **NAT Gateways**: Para acesso à internet das subnets privadas (configurável: single ou multi-AZ)
- **Route Tables**: Configuradas automaticamente para rotear tráfego

### VPC Endpoints (Opcional)
Quando habilitado, cria endpoints privados para:
- **ECR API**: Para autenticação no ECR
- **ECR DKR**: Para pull de imagens Docker
- **STS**: Para autenticação IAM (IRSA)
- **CloudWatch Logs**: Para envio de logs
- **SSM**: Para Parameter Store
- **S3**: Para acesso a buckets (tipo Gateway)

### Tags Kubernetes
Todas as subnets são automaticamente tagueadas para descoberta pelo Kubernetes:
- `kubernetes.io/cluster/<cluster_name>` = "shared"
- `kubernetes.io/role/elb` = "1" (subnets públicas)
- `kubernetes.io/role/internal-elb` = "1" (subnets privadas)

## Uso Básico

```hcl
module "eks" {
  source = "../../modules/clusters/eks"

  cluster_name       = "my-cluster"
  cluster_version    = "1.28"
  environment        = "staging"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  # NAT Gateway
  enable_nat_gateway = true
  single_nat_gateway = true  # Economia para staging

  # VPC Endpoints
  enable_vpc_endpoints = true

  # Node Groups
  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      disk_size      = 50
      labels = {
        role = "system"
      }
      taints = [{
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NoSchedule"
      }]
    }
    apps = {
      instance_types = ["t3.large"]
      min_size       = 2
      max_size       = 10
      desired_size   = 3
      disk_size      = 100
      labels = {
        role = "apps"
      }
      taints = []
    }
  }

  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
    Project     = "eks-template"
  }
}
```

## Configuração por Ambiente

### Staging (Economia de Custos)
```hcl
single_nat_gateway = true  # Apenas 1 NAT Gateway
node_groups = {
  system = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 3
    # ...
  }
}
```

### Produção (Alta Disponibilidade)
```hcl
single_nat_gateway = false  # NAT Gateway por AZ
node_groups = {
  system = {
    instance_types = ["t3.large"]
    min_size       = 3
    max_size       = 5
    # ...
  }
}
```

## Variáveis

Veja o arquivo `variables.tf` para documentação completa de todas as variáveis disponíveis.

### Variáveis Obrigatórias
- `cluster_name`: Nome do cluster EKS
- `vpc_cidr`: CIDR block da VPC
- `availability_zones`: Lista de AZs (mínimo 2)
- `environment`: Ambiente (staging ou prod)
- `node_groups`: Configuração dos node groups

### Variáveis Opcionais com Defaults
- `cluster_version`: "1.28"
- `enable_nat_gateway`: true
- `single_nat_gateway`: false
- `enable_vpc_endpoints`: true
- `enable_control_plane_logs`: true
- `enable_secrets_encryption`: true

## Outputs

### VPC
- `vpc_id`: ID da VPC
- `vpc_cidr`: CIDR da VPC
- `private_subnet_ids`: IDs das subnets privadas
- `public_subnet_ids`: IDs das subnets públicas

### NAT Gateway
- `nat_gateway_ids`: IDs dos NAT Gateways
- `nat_gateway_public_ips`: IPs públicos dos NAT Gateways

### VPC Endpoints
- `vpc_endpoint_ecr_api_id`: ID do endpoint ECR API
- `vpc_endpoint_ecr_dkr_id`: ID do endpoint ECR DKR
- `vpc_endpoint_sts_id`: ID do endpoint STS
- `vpc_endpoint_logs_id`: ID do endpoint CloudWatch Logs
- `vpc_endpoint_ssm_id`: ID do endpoint SSM
- `vpc_endpoint_s3_id`: ID do endpoint S3

## Requisitos

- Terraform >= 1.5.0
- AWS Provider >= 5.0

## Custos Estimados

### Staging (single NAT Gateway)
- VPC: Gratuito
- NAT Gateway: ~$32/mês + tráfego
- VPC Endpoints: ~$7/mês por endpoint (~$42/mês total)

### Produção (3 AZs, 3 NAT Gateways)
- VPC: Gratuito
- NAT Gateways: ~$96/mês + tráfego
- VPC Endpoints: ~$21/mês por endpoint (~$126/mês total)

**Nota**: Custos de nodes do EKS não incluídos (dependem dos instance types escolhidos).

## Otimização de Custos

1. **Staging**: Use `single_nat_gateway = true` para economizar ~$64/mês
2. **Desenvolvimento**: Use `enable_nat_gateway = false` se não precisar de acesso à internet
3. **VPC Endpoints**: Mantenha habilitado para reduzir custos de tráfego NAT Gateway
4. **Instance Types**: Use tipos menores em staging (t3.medium vs m5.xlarge)

## Segurança

### Melhores Práticas Implementadas
- ✅ Subnets privadas para nodes do EKS
- ✅ VPC Endpoints para reduzir exposição à internet
- ✅ Security groups restritivos para VPC endpoints
- ✅ Tags Kubernetes para descoberta automática
- ✅ DNS habilitado na VPC

### Próximos Passos (Implementados em Outros Arquivos)
- Criptografia de secrets com KMS
- Logs do control plane para CloudWatch
- IRSA (IAM Roles for Service Accounts)
- Network policies no Kubernetes

## Troubleshooting

### Erro: "Insufficient subnet IPs"
**Causa**: CIDR muito pequeno para o número de AZs
**Solução**: Use CIDR /16 ou maior (ex: 10.0.0.0/16)

### Erro: "NAT Gateway timeout"
**Causa**: Internet Gateway não criado antes do NAT Gateway
**Solução**: O módulo já trata isso com `depends_on`, mas se persistir, execute `terraform apply` novamente

### Erro: "VPC endpoint already exists"
**Causa**: Endpoint já existe na VPC
**Solução**: Importe o recurso existente ou delete manualmente

## Validação

```bash
# Validar configuração
terraform init
terraform validate

# Verificar plano
terraform plan

# Aplicar
terraform apply
```

## Referências

- [Amazon EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [EKS Networking](https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html)
