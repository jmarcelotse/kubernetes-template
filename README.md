# Terraform EKS AWS Template

Template Terraform para provisionamento de clusters Kubernetes (EKS) production-ready na AWS.

## 📋 Visão Geral

Este template implementa uma arquitetura modular e reutilizável para provisionamento de clusters EKS com:

- ✅ Isolamento completo entre ambientes (staging, prod)
- ✅ Backend S3 com locking nativo (sem DynamoDB)
- ✅ VPC production-ready com múltiplas AZs
- ✅ Node groups otimizados (system e apps)
- ✅ Plataforma Kubernetes padronizada (ArgoCD, observabilidade, segurança)
- ✅ CI/CD automatizado com GitHub Actions
- ✅ Compliance e auditoria integrados

## 🏗️ Estrutura do Projeto

```
terraform-eks-aws-template/
├── modules/              # Módulos Terraform reutilizáveis
│   ├── clusters/eks/    # Módulo principal do cluster EKS
│   └── platform/        # Módulos de componentes da plataforma
├── live/aws/            # Configurações por ambiente
│   ├── staging/         # Ambiente de staging
│   └── prod/            # Ambiente de produção
├── test/                # Testes automatizados
├── docs/                # Documentação adicional
└── .github/workflows/   # Pipelines CI/CD
```

## 🚀 Quick Start

**👉 Para instruções detalhadas passo a passo, consulte o [Guia de Uso Completo](docs/getting-started.md)**

### Pré-requisitos

- Terraform >= 1.5.0
- AWS CLI configurado
- Credenciais AWS com permissões apropriadas
- Bucket S3 para state (criar manualmente antes do primeiro apply)
- kubectl >= 1.24

### Configuração Rápida

1. **Criar bucket S3 para state:**

```bash
aws s3api create-bucket \
  --bucket terraform-state-eks-template \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket terraform-state-eks-template \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket terraform-state-eks-template \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

2. **Configurar ambiente (staging ou prod):**

```bash
cd live/aws/staging
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars com seus valores
```

3. **Inicializar e aplicar:**

```bash
terraform init
terraform plan
terraform apply
```

4. **Configurar kubectl:**

```bash
aws eks update-kubeconfig --region us-east-1 --name eks-staging
kubectl get nodes
```

## 📦 Módulos

### clusters/eks

Módulo principal que provisiona:
- VPC com subnets públicas e privadas
- NAT Gateways
- VPC Endpoints
- Cluster EKS com criptografia e logs
- Node groups (system e apps)
- IRSA (IAM Roles for Service Accounts)

### platform/*

Módulos de componentes da plataforma:
- **argocd**: GitOps com ArgoCD
- **policy-engine**: Kyverno ou Gatekeeper
- **external-secrets**: Sincronização de secrets
- **observability**: Prometheus, Grafana, Loki
- **ingress**: AWS LB Controller ou nginx
- **velero**: Backup e disaster recovery

## 🔧 Configuração

### Diferenças entre Ambientes

| Aspecto | Staging | Production |
|---------|---------|------------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 |
| NAT Gateway | Single | Multi-AZ |
| Instance Types | t3.medium/large | m5.xlarge/2xlarge |
| Autoscaling | Conservador | Agressivo |
| Policy Mode | Audit | Enforce |
| Retenção Métricas | 7 dias | 30 dias |
| Retenção Logs | 3 dias | 15 dias |
| Backup | Diário | A cada 6h |

## 🧪 Testes

```bash
# Validação
terraform fmt -check -recursive
terraform validate

# Linting
tflint --recursive

# Security scan
checkov -d . --framework terraform

# Testes unitários e de propriedade
cd test
go test -v ./...
```

## 📚 Documentação

### 🚀 Para Começar

- **[🎯 Passo a Passo Visual](docs/PASSO-A-PASSO.md)** ⭐ **COMECE AQUI!**
  - Guia visual simplificado
  - 7 passos claros com exemplos
  - Do zero ao cluster funcionando
  
- **[📘 Guia de Uso Completo](docs/getting-started.md)** - Instruções detalhadas
  - Pré-requisitos e instalação
  - Configuração inicial
  - Deploy do primeiro cluster
  - Configuração dos módulos
  - Acesso e operação
  
- **[⚡ Referência Rápida](docs/quick-reference.md)** - Comandos úteis
  - Terraform, kubectl, AWS CLI
  - Debug e troubleshooting
  - Aliases e dicas

### 🏗️ Arquitetura e Design

- **[🏛️ Arquitetura](docs/architecture.md)** - Diagramas e decisões de design
- **[🔄 Diferenças entre Ambientes](docs/environment-differences.md)** - Staging vs Production

### 🔧 Operação

- **[🔍 Troubleshooting](docs/troubleshooting.md)** - Problemas comuns e soluções
- **[💰 Otimização de Custos](docs/cost-optimization.md)** - Estratégias de economia

### 📦 Índice Completo

- **[📚 Índice de Documentação](docs/README.md)** - Todos os documentos disponíveis

## 🧪 Testes

Este template inclui **58 testes automatizados** que validam 100% dos requisitos:

- **41 testes unitários**: Validam exemplos específicos e casos extremos
- **17 testes de propriedade**: Validam corretude universal (Property-Based Testing)

### Executar Testes

```bash
# Instalar dependências
cd test
go mod download

# Executar todos os testes
go test -v ./...

# Apenas testes unitários
go test -v ./unit/...

# Apenas testes de propriedade (100 iterações)
go test -v ./property/... -count 100
```

### Documentação de Testes

- [README de Testes](test/README.md) - Visão geral e instruções
- [Lista Completa de Testes](test/TESTS.md) - Todos os 58 testes implementados
- [Setup](test/SETUP.md) - Configuração do ambiente
- [Troubleshooting](test/TROUBLESHOOTING.md) - Resolução de problemas

**Cobertura:** 100% dos requisitos validados através de testes automatizados.

## 🔒 Segurança

- Criptografia de secrets com KMS
- Logs do control plane habilitados
- VPC endpoints para comunicação privada
- Security groups restritivos
- Políticas de segurança automatizadas
- CloudTrail, Config e GuardDuty habilitados

## 💰 Custos Estimados

### Staging
- EKS Control Plane: ~$73/mês
- EC2 Nodes: ~$150/mês
- NAT Gateway: ~$32/mês
- **Total: ~$255/mês**

### Production
- EKS Control Plane: ~$73/mês
- EC2 Nodes: ~$600/mês
- NAT Gateways (3x): ~$96/mês
- **Total: ~$769/mês**

*Valores aproximados para us-east-1. Custos reais variam com uso.*

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT.

## 🆘 Suporte

Para problemas ou dúvidas:
- Abra uma issue no GitHub
- Consulte a [documentação](docs/)
- Entre em contato com o time de plataforma

---

**Nota:** Este template está em desenvolvimento ativo. Consulte as tasks para acompanhar o progresso da implementação.
