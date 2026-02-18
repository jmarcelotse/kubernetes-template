# Documentação - Terraform EKS AWS Template

Bem-vindo à documentação completa do template Terraform EKS AWS!

## 📖 Guias

### Para Começar

- **[🎯 Passo a Passo Visual](PASSO-A-PASSO.md)** ⭐ **COMECE AQUI!**
  - Guia visual e simplificado
  - 7 passos claros do zero ao cluster funcionando
  - Exemplos práticos com comandos prontos
  - Checkpoints para validar cada etapa
  - Troubleshooting de problemas comuns

- **[📘 Guia de Uso Completo](getting-started.md)**
  - Pré-requisitos e instalação
  - Configuração inicial
  - Deploy do primeiro cluster
  - Configuração dos módulos de plataforma
  - Acesso ao cluster
  - Deploy de aplicações
  - Manutenção e atualizações

- **[⚡ Referência Rápida](quick-reference.md)**
  - Comandos Terraform, kubectl, AWS CLI
  - Debug e troubleshooting
  - Aliases úteis
  - Dicas e truques

- **[Arquitetura](architecture.md)**
  - Visão geral da arquitetura
  - Componentes principais
  - Fluxo de dados
  - Decisões de design
  - Diagramas

- **[Diferenças entre Ambientes](environment-differences.md)**
  - Staging vs Production
  - Configurações específicas
  - Estratégias de isolamento

### Operação e Manutenção

- **[Troubleshooting](troubleshooting.md)**
  - Problemas comuns
  - Soluções e workarounds
  - Comandos úteis de debug
  - Logs e monitoramento

- **[Otimização de Custos](cost-optimization.md)**
  - Estratégias de economia
  - Uso de Spot Instances
  - Savings Plans
  - Monitoramento de custos
  - Comparação staging vs prod

## 🧪 Testes

- **[README de Testes](../test/README.md)**
  - Visão geral dos testes
  - Como executar
  - Estrutura dos testes

- **[Setup de Testes](../test/SETUP.md)**
  - Instalação do Go
  - Configuração do ambiente
  - Dependências

- **[Lista Completa de Testes](../test/TESTS.md)**
  - 70 testes unitários
  - 17 testes de propriedade
  - Cobertura de requisitos

- **[Troubleshooting de Testes](../test/TROUBLESHOOTING.md)**
  - Problemas comuns
  - Soluções

- **[Resultados dos Testes](../test/TEST_RESULTS_FINAL.md)**
  - Status atual: 100% passando
  - Detalhes das correções

## 📦 Módulos

### Cluster EKS

- **[modules/clusters/eks/README.md](../modules/clusters/eks/README.md)**
  - VPC e networking
  - Cluster EKS
  - Node groups
  - IRSA (IAM Roles for Service Accounts)

### Plataforma

- **[modules/platform/argocd/README.md](../modules/platform/argocd/README.md)**
  - GitOps com ArgoCD
  - Configuração
  - Acesso

- **[modules/platform/policy-engine/README.md](../modules/platform/policy-engine/README.md)**
  - Kyverno ou Gatekeeper
  - Políticas de segurança
  - Modos de enforcement

- **[modules/platform/external-secrets/README.md](../modules/platform/external-secrets/README.md)**
  - Sincronização de secrets
  - AWS Secrets Manager
  - AWS Systems Manager Parameter Store

- **[modules/platform/observability/README.md](../modules/platform/observability/README.md)**
  - Prometheus
  - Grafana
  - Loki
  - OpenTelemetry

- **[modules/platform/ingress/README.md](../modules/platform/ingress/README.md)**
  - AWS Load Balancer Controller
  - Ingress NGINX
  - Cert-manager
  - External DNS

- **[modules/platform/velero/README.md](../modules/platform/velero/README.md)**
  - Backup e restore
  - Disaster recovery
  - Schedules

### Compliance

- **[modules/compliance/README.md](../modules/compliance/README.md)**
  - CloudTrail
  - AWS Config
  - GuardDuty
  - Auditoria

## 🔧 Configuração

### Arquivos de Configuração

```
live/aws/
├── staging/
│   ├── backend.tf              # Configuração do backend S3
│   ├── main.tf                 # Chamada dos módulos
│   ├── variables.tf            # Definição de variáveis
│   ├── outputs.tf              # Outputs do ambiente
│   └── terraform.tfvars        # Valores das variáveis (criar a partir do .example)
└── prod/
    ├── backend.tf
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars
```

### Variáveis Principais

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `aws_region` | Região AWS | `us-east-1` |
| `cluster_name` | Nome do cluster | `eks-staging` |
| `environment` | Ambiente | `staging` ou `prod` |
| `vpc_cidr` | CIDR da VPC | `10.0.0.0/16` |
| `azs` | Availability Zones | `["us-east-1a", "us-east-1b"]` |
| `node_groups` | Configuração dos node groups | Ver exemplo |

## 🚀 Workflows

### CI/CD com GitHub Actions

- **[.github/workflows/terraform-plan.yml](../.github/workflows/terraform-plan.yml)**
  - Validação em PRs
  - Terraform fmt, validate, plan
  - Tflint e Checkov
  - Comentário com plan no PR

- **Terraform Apply** (staging e prod)
  - Apply automático em staging
  - Apply manual em prod (com aprovação)

## 📊 Monitoramento

### Métricas

- Prometheus coleta métricas do cluster
- Grafana para visualização
- Dashboards pré-configurados

### Logs

- Loki para agregação de logs
- Logs do control plane no CloudWatch
- CloudTrail para auditoria

### Alertas

- Alertmanager para notificações
- Integração com Slack/PagerDuty (configurável)

## 🔒 Segurança

### Práticas Implementadas

- ✅ Criptografia de secrets com KMS
- ✅ Logs do control plane habilitados
- ✅ VPC endpoints para comunicação privada
- ✅ Security groups restritivos
- ✅ Políticas de segurança automatizadas (Kyverno/Gatekeeper)
- ✅ CloudTrail, Config e GuardDuty habilitados
- ✅ IRSA para permissões granulares
- ✅ Network policies
- ✅ Pod Security Standards

### Compliance

- AWS Config Rules
- GuardDuty para detecção de ameaças
- CloudTrail para auditoria
- Bucket policies de proteção

## 💰 Custos

### Estimativas

| Componente | Staging | Production |
|------------|---------|------------|
| EKS Control Plane | ~$73/mês | ~$73/mês |
| EC2 Nodes | ~$150/mês | ~$600/mês |
| NAT Gateway | ~$32/mês | ~$96/mês |
| Load Balancers | ~$20/mês | ~$60/mês |
| **Total** | **~$275/mês** | **~$829/mês** |

*Valores aproximados para us-east-1*

### Otimização

- Spot Instances para workloads tolerantes a falhas
- Savings Plans para economia de longo prazo
- Autoscaling para ajustar capacidade
- Retenção de logs otimizada por ambiente

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch: `git checkout -b feature/nova-feature`
3. Commit: `git commit -m 'Adiciona nova feature'`
4. Push: `git push origin feature/nova-feature`
5. Abra um Pull Request

### Padrões de Código

- Use `terraform fmt` antes de commitar
- Execute `terraform validate`
- Execute testes: `cd test && go test -v ./...`
- Atualize documentação se necessário

## 📞 Suporte

### Canais de Suporte

- **Issues no GitHub**: Para bugs e feature requests
- **Documentação**: Consulte os guias acima
- **Time de Plataforma**: Para questões urgentes

### Reportar Problemas

Ao reportar um problema, inclua:

1. Descrição do problema
2. Passos para reproduzir
3. Versão do Terraform
4. Logs relevantes
5. Configuração (sem dados sensíveis)

## 📝 Changelog

Consulte o arquivo [CHANGELOG.md](../CHANGELOG.md) para ver o histórico de mudanças.

## 📄 Licença

Este projeto está sob a licença MIT. Consulte [LICENSE](../LICENSE) para mais detalhes.

---

**Última atualização**: 13 de Fevereiro de 2026

**Versão da documentação**: 1.0.0
