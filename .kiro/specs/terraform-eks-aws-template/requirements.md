# Documento de Requisitos

## Introdução

Este documento especifica os requisitos para um template Terraform de infraestrutura Kubernetes na AWS, focado em provisionamento de clusters EKS production-ready com plataforma padronizada. O template implementa arquitetura multi-ambiente com isolamento completo, seguindo as melhores práticas atuais de IaC, segurança e operabilidade.

## Glossário

- **Template_Terraform**: Sistema de infraestrutura como código que provisiona clusters Kubernetes EKS na AWS
- **Cluster_EKS**: Cluster Kubernetes gerenciado pela AWS (Elastic Kubernetes Service)
- **Stack_Terraform**: Instância independente de configuração Terraform com state remoto isolado
- **Backend_S3**: Sistema de armazenamento de state do Terraform usando S3 com locking nativo
- **Módulo_Clusters**: Módulo Terraform reutilizável para criação de clusters EKS completos
- **Módulo_Platform**: Conjunto de módulos Terraform para componentes da plataforma Kubernetes
- **IRSA**: IAM Roles for Service Accounts - mecanismo de autenticação AWS para pods Kubernetes
- **Node_Group**: Grupo de nós EC2 gerenciados que executam workloads no cluster EKS
- **VPC_Endpoint**: Endpoint privado para serviços AWS dentro da VPC
- **GitOps**: Metodologia de deployment usando Git como fonte da verdade
- **ArgoCD**: Ferramenta de continuous delivery declarativa para Kubernetes
- **Policy_Engine**: Sistema de validação e enforcement de políticas (Kyverno ou Gatekeeper)
- **External_Secrets_Operator**: Operador que sincroniza secrets de provedores externos para Kubernetes
- **Observability_Stack**: Conjunto de ferramentas para monitoramento e logging (Prometheus, Loki, OTEL)
- **Ingress_Controller**: Controlador que gerencia acesso externo aos serviços no cluster
- **Velero**: Ferramenta de backup e disaster recovery para Kubernetes
- **Ambiente**: Configuração isolada (staging ou prod) com recursos dedicados

## Requisitos

### Requisito 1: Arquitetura Multi-Ambiente

**User Story:** Como engenheiro de plataforma, eu quero ambientes completamente isolados, para que staging e produção não compartilhem recursos críticos e tenham configurações independentes.

#### Critérios de Aceitação

1. QUANDO um ambiente é provisionado, O Template_Terraform DEVERÁ criar um Stack_Terraform independente com state remoto isolado
2. QUANDO um ambiente é provisionado, O Template_Terraform DEVERÁ criar uma VPC dedicada com CIDR único
3. QUANDO um ambiente é provisionado, O Template_Terraform DEVERÁ criar um Cluster_EKS dedicado
4. PARA CADA Ambiente, O Template_Terraform DEVERÁ armazenar o state em um path S3 único no formato `<env>/terraform.tfstate`
5. QUANDO configurações de ambiente são modificadas, O Template_Terraform DEVERÁ permitir alterações sem afetar outros ambientes

### Requisito 2: Backend S3 com Locking Nativo

**User Story:** Como engenheiro de infraestrutura, eu quero usar o locking nativo do S3, para que o gerenciamento de state seja simplificado sem dependência do DynamoDB.

#### Critérios de Aceitação

1. QUANDO o backend é configurado, O Template_Terraform DEVERÁ usar S3 com a opção `use_lockfile = true`
2. QUANDO o backend é configurado, O Template_Terraform DEVERÁ habilitar versionamento no bucket S3
3. QUANDO o backend é configurado, O Template_Terraform DEVERÁ habilitar criptografia server-side no bucket S3
4. O Template_Terraform NÃO DEVERÁ usar tabelas DynamoDB para locking de state
5. QUANDO múltiplos usuários executam terraform simultaneamente, O Backend_S3 DEVERÁ prevenir modificações concorrentes usando lockfile

### Requisito 3: Estrutura Modular

**User Story:** Como desenvolvedor de infraestrutura, eu quero uma estrutura modular clara, para que componentes sejam reutilizáveis e a manutenção seja simplificada.

#### Critérios de Aceitação

1. O Template_Terraform DEVERÁ organizar código em `modules/clusters/eks/` para lógica de cluster EKS
2. O Template_Terraform DEVERÁ organizar código em `modules/platform/` para componentes da plataforma Kubernetes
3. O Template_Terraform DEVERÁ organizar configurações específicas em `live/aws/<env>/` por ambiente
4. QUANDO um módulo é atualizado, O Template_Terraform DEVERÁ permitir reutilização em múltiplos ambientes
5. CADA módulo DEVERÁ ter variáveis de entrada documentadas e outputs definidos

### Requisito 4: Rede VPC Production-Ready

**User Story:** Como arquiteto de segurança, eu quero uma VPC configurada com melhores práticas, para que o cluster opere de forma segura e resiliente.

#### Critérios de Aceitação

1. QUANDO uma VPC é criada, O Módulo_Clusters DEVERÁ provisionar subnets privadas em no mínimo 2 zonas de disponibilidade
2. QUANDO uma VPC é criada, O Módulo_Clusters DEVERÁ provisionar subnets públicas para NAT Gateways
3. QUANDO NAT Gateway é habilitado, O Módulo_Clusters DEVERÁ criar NAT Gateway em cada zona de disponibilidade pública
4. QUANDO VPC Endpoints são habilitados, O Módulo_Clusters DEVERÁ criar endpoints para ECR (api e dkr), STS, CloudWatch Logs e SSM
5. O Módulo_Clusters DEVERÁ configurar route tables para direcionar tráfego privado através de NAT Gateways
6. O Módulo_Clusters DEVERÁ aplicar tags apropriadas para descoberta automática pelo Kubernetes

### Requisito 5: Cluster EKS Seguro

**User Story:** Como engenheiro de segurança, eu quero um cluster EKS com controles de segurança habilitados, para que dados e workloads estejam protegidos.

#### Critérios de Aceitação

1. QUANDO um cluster é criado, O Módulo_Clusters DEVERÁ habilitar logs do control plane (api, audit, authenticator, controllerManager, scheduler)
2. QUANDO um cluster é criado, O Módulo_Clusters DEVERÁ habilitar criptografia de secrets usando chave KMS dedicada
3. QUANDO um cluster é criado, O Módulo_Clusters DEVERÁ configurar IRSA (IAM Roles for Service Accounts) com OIDC provider
4. QUANDO um cluster é criado, O Módulo_Clusters DEVERÁ configurar security groups restritivos para control plane
5. QUANDO um cluster é criado, O Módulo_Clusters DEVERÁ usar versão Kubernetes suportada e configurável
6. O Módulo_Clusters DEVERÁ configurar acesso ao control plane apenas via endpoints privados ou com restrições de CIDR

### Requisito 6: Node Groups Otimizados

**User Story:** Como engenheiro de plataforma, eu quero node groups separados e configuráveis, para que workloads de sistema e aplicação sejam isolados e escaláveis.

#### Critérios de Aceitação

1. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ criar um node group "system" com taints `CriticalAddonsOnly=true:NoSchedule`
2. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ criar um node group "apps" sem taints para workloads gerais
3. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ configurar autoscaling com valores mínimo, máximo e desejado
4. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ usar instance types configuráveis por variável
5. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ aplicar labels apropriadas para seleção de pods
6. QUANDO node groups são criados, O Módulo_Clusters DEVERÁ configurar disk size e type apropriados
7. PARA node group "system", O Módulo_Clusters DEVERÁ configurar tamanho fixo ou autoscaling conservador

### Requisito 7: Bootstrap GitOps com ArgoCD

**User Story:** Como engenheiro DevOps, eu quero ArgoCD instalado via Terraform, para que o restante da plataforma seja gerenciado via GitOps.

#### Critérios de Aceitação

1. QUANDO ArgoCD é instalado, O Módulo_Platform DEVERÁ usar Helm provider do Terraform
2. QUANDO ArgoCD é instalado, O Módulo_Platform DEVERÁ criar namespace dedicado
3. QUANDO ArgoCD é instalado, O Módulo_Platform DEVERÁ configurar tolerations para executar no node group "system"
4. QUANDO ArgoCD é instalado, O Módulo_Platform DEVERÁ expor outputs com endpoint e credenciais iniciais
5. QUANDO ArgoCD é instalado, O Módulo_Platform DEVERÁ permitir configuração de valores customizados via variáveis

### Requisito 8: Policy Engine para Segurança

**User Story:** Como engenheiro de segurança, eu quero políticas de segurança automatizadas, para que workloads inseguros sejam bloqueados ou auditados.

#### Critérios de Aceitação

1. QUANDO policy engine é instalado, O Módulo_Platform DEVERÁ suportar Kyverno ou Gatekeeper via variável de seleção
2. QUANDO políticas são aplicadas, O Módulo_Platform DEVERÁ bloquear containers privilegiados
3. QUANDO políticas são aplicadas, O Módulo_Platform DEVERÁ exigir runAsNonRoot para containers
4. QUANDO políticas são aplicadas, O Módulo_Platform DEVERÁ exigir resource requests e limits
5. QUANDO políticas são aplicadas, O Módulo_Platform DEVERÁ bloquear uso de image tag `latest`
6. PARA Ambiente staging, O Módulo_Platform DEVERÁ configurar políticas em modo audit
7. PARA Ambiente prod, O Módulo_Platform DEVERÁ configurar políticas em modo enforce

### Requisito 9: Gerenciamento de Secrets Externo

**User Story:** Como desenvolvedor, eu quero secrets sincronizados automaticamente de AWS Secrets Manager, para que aplicações acessem credenciais sem hardcoding.

#### Critérios de Aceitação

1. QUANDO External Secrets Operator é instalado, O Módulo_Platform DEVERÁ criar IRSA role com permissões para AWS Secrets Manager e SSM Parameter Store
2. QUANDO External Secrets Operator é instalado, O Módulo_Platform DEVERÁ configurar ClusterSecretStore para AWS backend
3. QUANDO External Secrets Operator é instalado, O Módulo_Platform DEVERÁ permitir configuração de região AWS via variável
4. QUANDO External Secrets Operator é instalado, O Módulo_Platform DEVERÁ criar namespace dedicado
5. O Módulo_Platform DEVERÁ documentar exemplo de ExternalSecret para uso por aplicações

### Requisito 10: Stack de Observabilidade

**User Story:** Como SRE, eu quero observabilidade completa do cluster, para que possa monitorar métricas, logs e traces de forma centralizada.

#### Critérios de Aceitação

1. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ instalar kube-prometheus-stack com Prometheus, Grafana e Alertmanager
2. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ instalar Loki para agregação de logs
3. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ instalar OpenTelemetry Collector para traces
4. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ configurar retenção de métricas diferente por ambiente (7 dias staging, 30 dias prod)
5. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ configurar retenção de logs diferente por ambiente (3 dias staging, 15 dias prod)
6. QUANDO observability stack é instalado, O Módulo_Platform DEVERÁ configurar persistent volumes para armazenamento
7. O Módulo_Platform DEVERÁ expor outputs com endpoints de Grafana e Prometheus

### Requisito 11: Ingress e Gerenciamento de DNS/TLS

**User Story:** Como desenvolvedor, eu quero ingress configurado com DNS e TLS automáticos, para que aplicações sejam expostas de forma segura.

#### Critérios de Aceitação

1. QUANDO ingress é configurado, O Módulo_Platform DEVERÁ suportar AWS Load Balancer Controller ou ingress-nginx via variável de seleção
2. QUANDO AWS Load Balancer Controller é usado, O Módulo_Platform DEVERÁ criar IRSA role com permissões apropriadas
3. QUANDO cert-manager é instalado, O Módulo_Platform DEVERÁ configurar ClusterIssuer para Let's Encrypt
4. QUANDO external-dns é instalado, O Módulo_Platform DEVERÁ criar IRSA role com permissões para Route53
5. QUANDO external-dns é instalado, O Módulo_Platform DEVERÁ configurar zona Route53 via variável
6. O Módulo_Platform DEVERÁ documentar exemplo de Ingress com anotações apropriadas

### Requisito 12: Backup e Disaster Recovery

**User Story:** Como SRE, eu quero backups automatizados do cluster, para que possa recuperar recursos em caso de desastre.

#### Critérios de Aceitação

1. QUANDO Velero é instalado, O Módulo_Platform DEVERÁ criar bucket S3 dedicado para backups
2. QUANDO Velero é instalado, O Módulo_Platform DEVERÁ criar IRSA role com permissões para S3
3. QUANDO Velero é instalado, O Módulo_Platform DEVERÁ configurar schedule de backup diferente por ambiente (diário staging, a cada 6 horas prod)
4. QUANDO Velero é instalado, O Módulo_Platform DEVERÁ configurar retenção de backups diferente por ambiente (7 dias staging, 30 dias prod)
5. O Módulo_Platform DEVERÁ expor outputs com nome do bucket de backup

### Requisito 13: Diferenciação de Ambientes

**User Story:** Como engenheiro de plataforma, eu quero configurações otimizadas por ambiente, para que staging seja econômico e produção seja resiliente.

#### Critérios de Aceitação

1. PARA Ambiente staging, O Template_Terraform DEVERÁ usar instance types menores para node groups
2. PARA Ambiente prod, O Template_Terraform DEVERÁ usar instance types maiores e mais réplicas
3. PARA Ambiente staging, O Template_Terraform DEVERÁ configurar autoscaling mais conservador
4. PARA Ambiente prod, O Template_Terraform DEVERÁ configurar autoscaling mais agressivo
5. PARA Ambiente staging, O Template_Terraform DEVERÁ configurar janelas de manutenção mais flexíveis
6. PARA Ambiente prod, O Template_Terraform DEVERÁ configurar janelas de manutenção restritas
7. CADA Ambiente DEVERÁ ter arquivo de variáveis dedicado (terraform.tfvars) com valores apropriados

### Requisito 14: CI/CD com GitHub Actions

**User Story:** Como engenheiro DevOps, eu quero pipelines automatizados para Terraform, para que mudanças sejam validadas e aplicadas de forma controlada.

#### Critérios de Aceitação

1. QUANDO um pull request é criado, O Template_Terraform DEVERÁ executar `terraform fmt -check` via GitHub Actions
2. QUANDO um pull request é criado, O Template_Terraform DEVERÁ executar `terraform validate` via GitHub Actions
3. QUANDO um pull request é criado, O Template_Terraform DEVERÁ executar `terraform plan` para todos os ambientes afetados
4. QUANDO um pull request é mergeado para main, O Template_Terraform DEVERÁ executar `terraform apply` automaticamente para staging
5. QUANDO um pull request é mergeado para main, O Template_Terraform DEVERÁ requerer aprovação manual antes de `terraform apply` em prod
6. O Template_Terraform DEVERÁ usar OIDC para autenticação com AWS (sem access keys estáticas)
7. O Template_Terraform DEVERÁ armazenar outputs do plan como comentário no pull request

### Requisito 15: Documentação e Exemplos

**User Story:** Como novo usuário do template, eu quero documentação clara, para que possa provisionar clusters sem conhecimento prévio detalhado.

#### Critérios de Aceitação

1. O Template_Terraform DEVERÁ incluir README.md com instruções de uso
2. O Template_Terraform DEVERÁ incluir exemplos de arquivos terraform.tfvars para cada ambiente
3. O Template_Terraform DEVERÁ documentar todas as variáveis de entrada com descrições e valores padrão
4. O Template_Terraform DEVERÁ documentar todos os outputs com descrições
5. O Template_Terraform DEVERÁ incluir guia de troubleshooting para problemas comuns
6. O Template_Terraform DEVERÁ incluir diagrama de arquitetura da infraestrutura provisionada

### Requisito 16: Validação e Testes

**User Story:** Como engenheiro de qualidade, eu quero validação automatizada do código Terraform, para que erros sejam detectados antes do deployment.

#### Critérios de Aceitação

1. O Template_Terraform DEVERÁ incluir configuração para terraform-docs para gerar documentação automaticamente
2. O Template_Terraform DEVERÁ incluir configuração para tflint com regras AWS
3. O Template_Terraform DEVERÁ incluir configuração para checkov ou tfsec para análise de segurança
4. QUANDO validação de segurança detecta issues críticos, O Template_Terraform DEVERÁ falhar o pipeline CI
5. O Template_Terraform DEVERÁ incluir testes de integração básicos usando Terratest ou similar

### Requisito 17: Gerenciamento de Custos

**User Story:** Como gerente de infraestrutura, eu quero visibilidade de custos, para que possa otimizar gastos com AWS.

#### Critérios de Aceitação

1. O Template_Terraform DEVERÁ aplicar tags de custo em todos os recursos (Environment, ManagedBy, Project)
2. O Template_Terraform DEVERÁ documentar estimativa de custos mensais por ambiente
3. PARA Ambiente staging, O Template_Terraform DEVERÁ usar configurações econômicas (single NAT Gateway, instance types menores)
4. O Template_Terraform DEVERÁ permitir desabilitar NAT Gateway via variável para ambientes de desenvolvimento
5. O Template_Terraform DEVERÁ documentar estratégias de otimização de custos (Spot instances, Savings Plans)

### Requisito 18: Compliance e Auditoria

**User Story:** Como auditor de segurança, eu quero rastreabilidade de mudanças, para que possa auditar configurações de infraestrutura.

#### Critérios de Aceitação

1. O Template_Terraform DEVERÁ habilitar CloudTrail para auditoria de chamadas API AWS
2. O Template_Terraform DEVERÁ habilitar Config Rules para compliance contínuo
3. O Template_Terraform DEVERÁ habilitar GuardDuty para detecção de ameaças
4. O Template_Terraform DEVERÁ armazenar logs de auditoria em bucket S3 com retenção configurável
5. O Template_Terraform DEVERÁ aplicar bucket policies para prevenir deleção acidental de logs
6. TODOS os recursos DEVERÃO ter tags de ownership e purpose para rastreabilidade
