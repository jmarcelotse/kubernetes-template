# Plano de Implementação: Template Terraform EKS AWS

## Visão Geral

Este plano detalha a implementação incremental do template Terraform para provisionamento de clusters EKS na AWS. A implementação segue uma abordagem modular, começando pela infraestrutura base (VPC, EKS) e progredindo para componentes da plataforma Kubernetes. Cada tarefa constrói sobre as anteriores, garantindo que não haja código órfão ou não integrado.

## Tarefas

- [x] 1. Configurar estrutura base do projeto e backend S3
  - Criar estrutura de diretórios (modules/, live/, test/, docs/)
  - Configurar backend S3 com locking nativo para staging e prod
  - Criar arquivos de configuração base (.gitignore, .terraform-docs.yml, .tflint.hcl)
  - _Requisitos: 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3_

- [x]* 1.1 Escrever testes unitários para validação de backend
  - Testar que backend.tf contém use_lockfile = true
  - Testar que backend.tf contém encrypt = true
  - Testar que backend.tf não contém dynamodb_table
  - _Requisitos: 2.1, 2.3, 2.4_

- [x] 2. Implementar módulo clusters/eks - Rede VPC
  - [x] 2.1 Criar variables.tf com todas as variáveis de entrada documentadas
    - Definir variáveis para VPC (cidr, azs, nat gateway, vpc endpoints)
    - Adicionar validation blocks para entradas críticas
    - _Requisitos: 3.5, 4.1, 4.2, 4.3, 4.4_

  - [x] 2.2 Implementar vpc.tf com VPC, subnets e NAT gateways
    - Criar VPC com CIDR configurável
    - Criar subnets privadas e públicas em múltiplas AZs
    - Criar NAT gateways (single ou multi-AZ baseado em variável)
    - Configurar route tables para tráfego privado
    - Aplicar tags Kubernetes para descoberta automática
    - _Requisitos: 4.1, 4.2, 4.3, 4.5, 4.6_

  - [x]* 2.3 Escrever teste de propriedade para subnets multi-AZ
    - **Propriedade 2: Subnets Multi-AZ**
    - **Valida: Requisitos 4.1, 4.2**

  - [x]* 2.4 Escrever teste de propriedade para NAT gateways por AZ
    - **Propriedade 3: NAT Gateway por AZ**
    - **Valida: Requisitos 4.3**

  - [x]* 2.5 Escrever teste de propriedade para tags Kubernetes
    - **Propriedade 5: Tags Kubernetes em Subnets**
    - **Valida: Requisitos 4.6**

  - [x] 2.6 Implementar VPC endpoints para serviços AWS
    - Criar endpoints para ECR (api e dkr), STS, CloudWatch Logs, SSM
    - Configurar security groups para endpoints
    - _Requisitos: 4.4_

  - [x]* 2.7 Escrever teste de propriedade para VPC endpoints completos
    - **Propriedade 4: VPC Endpoints Completos**
    - **Valida: Requisitos 4.4**

- [x] 3. Implementar módulo clusters/eks - Cluster EKS
  - [x] 3.1 Criar eks.tf com configuração do cluster
    - Criar cluster EKS com versão configurável
    - Habilitar logs do control plane (todos os 5 tipos)
    - Configurar criptografia de secrets com KMS
    - Configurar security groups para control plane
    - _Requisitos: 5.1, 5.2, 5.4, 5.5, 5.6_

  - [x]* 3.2 Escrever teste de propriedade para logs do control plane
    - **Propriedade 6: Logs do Control Plane Completos**
    - **Valida: Requisitos 5.1**

  - [x]* 3.3 Escrever teste de propriedade para criptografia KMS
    - **Propriedade 7: Criptografia de Secrets com KMS**
    - **Valida: Requisitos 5.2**

  - [x]* 3.4 Escrever teste de propriedade para versão Kubernetes válida
    - **Propriedade 8: Versão Kubernetes Válida**
    - **Valida: Requisitos 5.5**

  - [x] 3.5 Implementar irsa.tf com OIDC provider
    - Criar OIDC provider para IRSA
    - Configurar trust relationships
    - _Requisitos: 5.3_

  - [x]* 3.6 Escrever teste unitário para OIDC provider
    - Validar que recurso aws_iam_openid_connect_provider é criado
    - _Requisitos: 5.3_

- [x] 4. Implementar módulo clusters/eks - Node Groups
  - [x] 4.1 Criar node_groups.tf com configuração de node groups
    - Implementar node group "system" com taints CriticalAddonsOnly
    - Implementar node group "apps" sem taints
    - Configurar autoscaling (min, max, desired)
    - Configurar instance types, disk size, labels
    - _Requisitos: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7_

  - [x]* 4.2 Escrever testes unitários para node groups específicos
    - Testar que node group "system" tem taint correto
    - Testar que node group "apps" não tem taints
    - _Requisitos: 6.1, 6.2_

  - [x]* 4.3 Escrever teste de propriedade para node groups completos
    - **Propriedade 9: Node Groups Completos**
    - **Valida: Requisitos 6.3, 6.4, 6.5, 6.6**

  - [x]* 4.4 Escrever teste de propriedade para autoscaling conservador
    - **Propriedade 10: Autoscaling Conservador para System Nodes**
    - **Valida: Requisitos 6.7**

  - [x] 4.5 Criar outputs.tf com todos os outputs documentados
    - Expor cluster_id, cluster_endpoint, oidc_provider_arn
    - Expor vpc_id, subnet_ids, security_group_ids
    - _Requisitos: 3.5_

- [x] 5. Checkpoint - Validar módulo clusters/eks
  - Executar terraform validate no módulo
  - Executar tflint e checkov
  - Garantir que todos os testes passam
  - Perguntar ao usuário se há dúvidas

- [x] 6. Implementar configurações de ambiente (live/aws)
  - [x] 6.1 Criar configuração para staging
    - Criar backend.tf com path staging/terraform.tfstate
    - Criar main.tf chamando módulo clusters/eks
    - Criar terraform.tfvars com valores para staging
    - Configurar instance types menores, single NAT gateway
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 13.1, 13.3, 13.7, 17.3_

  - [x] 6.2 Criar configuração para prod
    - Criar backend.tf com path prod/terraform.tfstate
    - Criar main.tf chamando módulo clusters/eks
    - Criar terraform.tfvars com valores para prod
    - Configurar instance types maiores, multi-AZ NAT gateways
    - _Requisitos: 1.1, 1.2, 1.3, 1.4, 13.2, 13.4, 13.7_

  - [x]* 6.3 Escrever teste de propriedade para isolamento de ambientes
    - **Propriedade 1: Isolamento de Ambientes**
    - **Valida: Requisitos 1.1, 1.2, 1.3, 1.4**

  - [x]* 6.4 Escrever testes unitários para diferenças de ambiente
    - Testar instance types staging vs prod
    - Testar autoscaling staging vs prod
    - Testar single NAT gateway em staging
    - _Requisitos: 13.1, 13.2, 13.3, 13.4, 17.3_

- [x] 7. Implementar módulo platform/argocd
  - [x] 7.1 Criar módulo com Helm provider
    - Criar variables.tf com configurações do ArgoCD
    - Criar main.tf com kubernetes_namespace e helm_release
    - Configurar tolerations para node group system
    - Criar outputs.tf com namespace e credenciais
    - _Requisitos: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [x]* 7.2 Escrever testes unitários para ArgoCD
    - Testar que helm_release existe
    - Testar que namespace é criado
    - Testar que tolerations estão configuradas
    - Testar que outputs existem
    - _Requisitos: 7.1, 7.2, 7.3, 7.4_

- [x] 8. Implementar módulo platform/policy-engine
  - [x] 8.1 Criar módulo com suporte para Kyverno e Gatekeeper
    - Criar variables.tf com engine selection e policies config
    - Implementar lógica condicional para Kyverno
    - Implementar lógica condicional para Gatekeeper
    - Criar políticas: block_privileged, require_non_root, require_resources, block_latest_tag
    - _Requisitos: 8.1, 8.2, 8.3, 8.4, 8.5_

  - [x]* 8.2 Escrever teste unitário para seleção de engine
    - Testar que variável engine tem validation
    - _Requisitos: 8.1_

  - [x]* 8.3 Escrever teste de propriedade para políticas habilitadas
    - **Propriedade 11: Políticas de Segurança Habilitadas**
    - **Valida: Requisitos 8.2, 8.3, 8.4, 8.5**

  - [x]* 8.4 Escrever testes unitários para enforcement mode por ambiente
    - Testar que staging usa audit mode
    - Testar que prod usa enforce mode
    - _Requisitos: 8.6, 8.7_

- [x] 9. Implementar módulo platform/external-secrets
  - [x] 9.1 Criar módulo com IRSA e ClusterSecretStore
    - Criar IAM role com trust policy OIDC
    - Criar IAM policy com permissões Secrets Manager e SSM
    - Instalar External Secrets Operator via Helm
    - Criar ClusterSecretStore para AWS backend
    - Criar arquivo de exemplo de ExternalSecret
    - _Requisitos: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [x]* 9.2 Escrever teste de propriedade para IRSA correto
    - **Propriedade 12: IRSA com Permissões Corretas** (parte 1)
    - **Valida: Requisitos 9.1**

  - [x]* 9.3 Escrever testes unitários para External Secrets
    - Testar que ClusterSecretStore é criado
    - Testar que variável aws_region existe
    - Testar que namespace é criado
    - Testar que arquivo de exemplo existe
    - _Requisitos: 9.2, 9.3, 9.4, 9.5_

- [x] 10. Implementar módulo platform/observability
  - [x] 10.1 Criar módulo com stack de observabilidade
    - Instalar kube-prometheus-stack via Helm
    - Instalar Loki via Helm
    - Instalar OpenTelemetry Collector via Helm
    - Configurar retenção baseada em environment (7/30 dias métricas, 3/15 dias logs)
    - Configurar persistent volumes
    - Criar outputs com endpoints
    - _Requisitos: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [x]* 10.2 Escrever testes unitários para componentes de observabilidade
    - Testar que helm_release para prometheus existe
    - Testar que helm_release para loki existe
    - Testar que helm_release para otel existe
    - Testar que outputs existem
    - _Requisitos: 10.1, 10.2, 10.3, 10.7_

  - [x]* 10.3 Escrever teste de propriedade para retenção por ambiente
    - **Propriedade 13: Retenção por Ambiente**
    - **Valida: Requisitos 10.4, 10.5**

- [x] 11. Implementar módulo platform/ingress
  - [x] 11.1 Criar módulo com suporte para ALB e nginx
    - Criar variables.tf com ingress_type selection
    - Implementar AWS Load Balancer Controller com IRSA
    - Implementar ingress-nginx como alternativa
    - Instalar cert-manager com ClusterIssuer Let's Encrypt
    - Instalar external-dns com IRSA para Route53
    - Criar arquivo de exemplo de Ingress
    - _Requisitos: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [x]* 11.2 Escrever teste unitário para seleção de ingress
    - Testar que variável ingress_type tem validation
    - _Requisitos: 11.1_

  - [x]* 11.3 Escrever teste de propriedade para IRSA de ingress
    - **Propriedade 12: IRSA com Permissões Corretas** (parte 2)
    - **Valida: Requisitos 11.2, 11.4**

  - [x]* 11.4 Escrever testes unitários para componentes de ingress
    - Testar que ClusterIssuer é criado
    - Testar que variável route53_zone_id existe
    - Testar que arquivo de exemplo existe
    - _Requisitos: 11.3, 11.5, 11.6_

- [x] 12. Implementar módulo platform/velero
  - [x] 12.1 Criar módulo com backup S3
    - Criar bucket S3 para backups
    - Criar IAM role com IRSA e permissões S3
    - Instalar Velero via Helm
    - Configurar schedule baseado em environment (diário staging, 6h prod)
    - Configurar retenção baseada em environment (7 dias staging, 30 dias prod)
    - Criar outputs com bucket name
    - _Requisitos: 12.1, 12.2, 12.3, 12.4, 12.5_

  - [x]* 12.2 Escrever teste unitário para bucket S3
    - Testar que aws_s3_bucket é criado
    - Testar que output bucket_name existe
    - _Requisitos: 12.1, 12.5_

  - [x]* 12.3 Escrever teste de propriedade para IRSA de Velero
    - **Propriedade 12: IRSA com Permissões Corretas** (parte 3)
    - **Valida: Requisitos 12.2**

  - [x]* 12.4 Escrever teste de propriedade para backup por ambiente
    - **Propriedade 14: Backup Schedule por Ambiente**
    - **Valida: Requisitos 12.3, 12.4**

- [x] 13. Checkpoint - Validar módulos de plataforma
  - Executar terraform validate em todos os módulos
  - Executar tflint e checkov
  - Garantir que todos os testes passam
  - Perguntar ao usuário se há dúvidas

- [x] 14. Integrar módulos de plataforma nas configurações de ambiente
  - [x] 14.1 Adicionar módulos de plataforma ao staging
    - Adicionar chamadas para argocd, policy-engine, external-secrets, observability, ingress, velero
    - Configurar valores específicos para staging (audit mode, retenções menores)
    - _Requisitos: 7.1-7.5, 8.1-8.7, 9.1-9.5, 10.1-10.7, 11.1-11.6, 12.1-12.5_

  - [x] 14.2 Adicionar módulos de plataforma ao prod
    - Adicionar chamadas para argocd, policy-engine, external-secrets, observability, ingress, velero
    - Configurar valores específicos para prod (enforce mode, retenções maiores)
    - _Requisitos: 7.1-7.5, 8.1-8.7, 9.1-9.5, 10.1-10.7, 11.1-11.6, 12.1-12.5_

- [x] 15. Implementar módulo de compliance e auditoria
  - [x] 15.1 Criar módulo compliance com CloudTrail, Config e GuardDuty
    - Criar aws_cloudtrail com logging para S3
    - Criar aws_config_configuration_recorder e delivery_channel
    - Criar aws_guardduty_detector
    - Criar bucket S3 para logs de auditoria com lifecycle policy
    - Aplicar bucket policy para prevenir deleção
    - _Requisitos: 18.1, 18.2, 18.3, 18.4, 18.5_

  - [x]* 15.2 Escrever testes unitários para compliance
    - Testar que CloudTrail é criado
    - Testar que Config é criado
    - Testar que GuardDuty é criado
    - _Requisitos: 18.1, 18.2, 18.3_

  - [x]* 15.3 Escrever teste de propriedade para bucket policies
    - **Propriedade 17: Bucket Policies de Proteção**
    - **Valida: Requisitos 18.5**

  - [x] 15.4 Integrar módulo compliance nos ambientes
    - Adicionar ao staging e prod
    - _Requisitos: 18.1-18.5_

- [x] 16. Implementar validação de tags obrigatórias
  - [x] 16.1 Adicionar default tags em provider AWS
    - Configurar default_tags com Environment, ManagedBy, Project, Owner, Purpose
    - _Requisitos: 17.1, 18.6_

  - [x]* 16.2 Escrever teste de propriedade para tags obrigatórias
    - **Propriedade 16: Tags Obrigatórias**
    - **Valida: Requisitos 17.1, 18.6**

- [x] 17. Implementar workflows GitHub Actions
  - [x] 17.1 Criar workflow de validação para PRs
    - Adicionar steps: terraform fmt -check
    - Adicionar steps: terraform validate
    - Adicionar steps: terraform plan
    - Adicionar steps: tflint
    - Adicionar steps: checkov com falha em issues críticos
    - Adicionar step para postar plan como comentário no PR
    - Configurar OIDC para autenticação AWS
    - _Requisitos: 14.1, 14.2, 14.3, 14.6, 14.7, 16.3, 16.4_

  - [x] 17.2 Criar workflow de apply para staging
    - Trigger em push para main
    - Executar terraform apply automaticamente
    - _Requisitos: 14.4_

  - [x] 17.3 Criar workflow de apply para prod
    - Trigger em push para main
    - Requerer aprovação manual (environment protection)
    - Executar terraform apply após aprovação
    - _Requisitos: 14.5_

  - [x]* 17.4 Escrever testes unitários para workflows
    - Testar que workflow contém terraform fmt
    - Testar que workflow contém terraform validate
    - Testar que workflow contém terraform plan
    - Testar que workflow usa OIDC
    - Testar que workflow posta comentário
    - Testar que apply staging é automático
    - Testar que apply prod requer aprovação
    - _Requisitos: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6, 14.7_

- [x] 18. Criar documentação completa
  - [x] 18.1 Criar README.md principal
    - Adicionar visão geral do template
    - Adicionar instruções de uso (pré-requisitos, setup, deployment)
    - Adicionar seção de arquitetura com diagrama
    - Adicionar seção de custos com estimativas
    - _Requisitos: 15.1, 15.6, 17.2_

  - [x] 18.2 Criar exemplos de terraform.tfvars
    - Criar exemplo para staging
    - Criar exemplo para prod
    - _Requisitos: 15.2_

  - [x] 18.3 Criar guia de troubleshooting
    - Documentar erros comuns e soluções
    - Adicionar comandos de debugging
    - _Requisitos: 15.5_

  - [x] 18.4 Criar documentação de otimização de custos
    - Documentar estratégias (Spot instances, Savings Plans)
    - Adicionar comparação de custos staging vs prod
    - _Requisitos: 17.5_

  - [x] 18.5 Gerar documentação automática com terraform-docs
    - Configurar .terraform-docs.yml
    - Gerar README.md para cada módulo
    - _Requisitos: 16.1_

  - [x]* 18.6 Escrever testes unitários para documentação
    - Testar que README.md existe
    - Testar que exemplos existem
    - Testar que troubleshooting.md existe
    - Testar que cost-optimization.md existe
    - Testar que .terraform-docs.yml existe
    - _Requisitos: 15.1, 15.2, 15.5, 16.1, 17.2_

  - [x]* 18.7 Escrever teste de propriedade para documentação de variáveis
    - **Propriedade 15: Documentação de Variáveis e Outputs**
    - **Valida: Requisitos 3.5, 15.3, 15.4**

- [x] 19. Configurar ferramentas de validação
  - [x] 19.1 Criar configuração tflint
    - Criar .tflint.hcl com regras AWS
    - _Requisitos: 16.2_

  - [x] 19.2 Configurar estrutura de testes Go
    - Criar go.mod com dependências (terratest, gopter, testify)
    - Criar estrutura de diretórios test/
    - _Requisitos: 16.5_

  - [x]* 19.3 Escrever testes unitários para configurações
    - Testar que .tflint.hcl existe
    - Testar que diretório test/ existe com arquivos Go
    - _Requisitos: 16.2, 16.5_

- [x] 20. Checkpoint final - Validação completa
  - Executar todos os testes unitários
  - Executar todos os testes de propriedade (mínimo 100 iterações cada)
  - Executar terraform validate em todos os ambientes
  - Executar tflint e checkov
  - Verificar que toda documentação está completa
  - Perguntar ao usuário se há dúvidas ou ajustes necessários

## Notas

- Tarefas marcadas com `*` são opcionais e podem ser puladas para MVP mais rápido
- Cada tarefa referencia requisitos específicos para rastreabilidade
- Checkpoints garantem validação incremental
- Testes de propriedade validam corretude universal
- Testes unitários validam exemplos específicos e casos extremos
- Todos os testes de propriedade devem executar mínimo 100 iterações
- Implementação usa Go para testes (Terratest + gopter para property-based testing)
