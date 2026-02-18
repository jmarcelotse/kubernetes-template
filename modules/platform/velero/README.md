# Velero Module

Este módulo instala e configura o Velero para backup e disaster recovery do cluster Kubernetes.

## Funcionalidades

- Instalação do Velero via Helm
- Bucket S3 dedicado para backups
- IRSA configurado para acesso ao S3
- Backups agendados automaticamente
- Retenção configurável por ambiente
- Suporte para snapshots de volumes EBS
- Versionamento e criptografia do bucket S3
- Proteção contra deleção acidental

## Uso

```hcl
module "velero" {
  source = "../../modules/platform/velero"

  cluster_name            = "my-cluster"
  oidc_provider_arn       = module.eks.oidc_provider_arn
  oidc_issuer_url         = module.eks.cluster_oidc_issuer_url
  aws_region              = "us-east-1"
  
  backup_bucket_name      = "my-cluster-velero-backups"
  backup_schedule         = "0 2 * * *"  # Diário às 2h
  backup_retention_days   = 7
  
  enable_volume_snapshots = true
}
```

## Diferenças entre Ambientes

### Staging
- `backup_schedule = "0 2 * * *"` - Diário às 2h
- `backup_retention_days = 7` - 7 dias de retenção
- Custos menores

### Production
- `backup_schedule = "0 */6 * * *"` - A cada 6 horas
- `backup_retention_days = 30` - 30 dias de retenção
- Maior proteção

## Backups Automáticos

O módulo configura um schedule padrão que faz backup de:
- Todos os namespaces (exceto kube-system, kube-public, kube-node-lease)
- Todos os recursos do Kubernetes
- Snapshots de volumes EBS (se habilitado)

## Comandos Velero

### Listar Backups

```bash
velero backup get
```

### Criar Backup Manual

```bash
# Backup de todo o cluster
velero backup create manual-backup-$(date +%Y%m%d-%H%M%S)

# Backup de namespace específico
velero backup create app-backup --include-namespaces default

# Backup com label selector
velero backup create app-backup --selector app=my-app

# Backup excluindo recursos
velero backup create backup --exclude-resources pods,events
```

### Ver Detalhes de um Backup

```bash
velero backup describe <backup-name>
velero backup logs <backup-name>
```

### Restaurar Backup

```bash
# Restaurar backup completo
velero restore create --from-backup <backup-name>

# Restaurar apenas namespace específico
velero restore create --from-backup <backup-name> \
  --include-namespaces default

# Restaurar em namespace diferente
velero restore create --from-backup <backup-name> \
  --namespace-mappings old-ns:new-ns

# Restaurar apenas recursos específicos
velero restore create --from-backup <backup-name> \
  --include-resources deployments,services
```

### Ver Status de Restore

```bash
velero restore get
velero restore describe <restore-name>
velero restore logs <restore-name>
```

### Deletar Backup

```bash
velero backup delete <backup-name>
```

## Schedules

### Listar Schedules

```bash
velero schedule get
```

### Criar Schedule Customizado

```bash
# Backup diário às 3h
velero schedule create daily-backup \
  --schedule="0 3 * * *" \
  --ttl 168h

# Backup semanal aos domingos
velero schedule create weekly-backup \
  --schedule="0 0 * * 0" \
  --ttl 720h

# Backup de namespace específico
velero schedule create app-backup \
  --schedule="0 */6 * * *" \
  --include-namespaces production \
  --ttl 168h
```

### Pausar/Resumir Schedule

```bash
velero schedule pause <schedule-name>
velero schedule unpause <schedule-name>
```

## Disaster Recovery

### Cenário 1: Recuperar Namespace Deletado

```bash
# 1. Listar backups disponíveis
velero backup get

# 2. Restaurar namespace
velero restore create --from-backup <backup-name> \
  --include-namespaces <namespace>

# 3. Verificar restore
velero restore describe <restore-name>
kubectl get all -n <namespace>
```

### Cenário 2: Migrar para Novo Cluster

```bash
# No cluster antigo:
# 1. Criar backup final
velero backup create migration-backup --wait

# No cluster novo:
# 1. Instalar Velero apontando para o mesmo bucket S3
# 2. Aguardar sincronização dos backups
velero backup get

# 3. Restaurar
velero restore create --from-backup migration-backup
```

### Cenário 3: Recuperar Aplicação Específica

```bash
# Restaurar apenas deployments e services de uma app
velero restore create app-restore \
  --from-backup <backup-name> \
  --include-resources deployments,services,configmaps,secrets \
  --selector app=my-app
```

## Verificação

### Verificar Instalação

```bash
# Verificar pods
kubectl get pods -n velero

# Verificar backup location
velero backup-location get

# Verificar snapshot location (se habilitado)
velero snapshot-location get
```

### Testar Backup

```bash
# Criar backup de teste
velero backup create test-backup --include-namespaces default

# Aguardar conclusão
velero backup describe test-backup

# Verificar no S3
aws s3 ls s3://<bucket-name>/backups/
```

### Testar Restore

```bash
# Criar namespace de teste
kubectl create namespace test-restore

# Criar recursos
kubectl create deployment nginx --image=nginx -n test-restore

# Fazer backup
velero backup create test-backup --include-namespaces test-restore --wait

# Deletar namespace
kubectl delete namespace test-restore

# Restaurar
velero restore create --from-backup test-backup --wait

# Verificar
kubectl get all -n test-restore
```

## Troubleshooting

### Backup Falha

```bash
# Ver logs do backup
velero backup logs <backup-name>

# Ver eventos
kubectl get events -n velero --sort-by='.lastTimestamp'

# Ver logs do Velero
kubectl logs -n velero -l app.kubernetes.io/name=velero
```

Problemas comuns:
- Permissões IAM insuficientes
- Bucket S3 inacessível
- Recursos muito grandes (timeout)

### Restore Falha

```bash
# Ver logs do restore
velero restore logs <restore-name>

# Ver warnings
velero restore describe <restore-name> | grep -A 10 "Warnings"
```

Problemas comuns:
- Recursos já existem no cluster
- Incompatibilidade de versão do Kubernetes
- PVs não podem ser restaurados (usar snapshots)

### Backup Não Aparece

```bash
# Verificar backup location
velero backup-location get

# Testar conectividade com S3
aws s3 ls s3://<bucket-name>/

# Verificar permissões IAM
kubectl describe sa velero -n velero
```

## Exclusões

### Excluir Recursos de Backups

Alguns recursos não devem ser incluídos em backups:

```bash
# Via annotation no recurso
kubectl annotate pod my-pod velero.io/exclude-from-backup=true

# Via label
kubectl label pod my-pod velero.io/exclude-from-backup=true
```

### Excluir Namespaces

Configure no módulo:

```hcl
exclude_namespaces = [
  "kube-system",
  "kube-public",
  "kube-node-lease",
  "velero"
]
```

## Snapshots de Volumes

### Habilitar Snapshots

```hcl
enable_volume_snapshots = true
```

### Como Funciona

1. Velero identifica PVCs no backup
2. Cria snapshot EBS do volume
3. Armazena referência no backup
4. No restore, cria novo volume do snapshot

### Limitações

- Apenas volumes EBS
- Snapshot na mesma região
- Custo adicional de snapshots EBS

### Alternativa: Restic

Para backup de dados sem snapshots:

```bash
# Anotar pod para usar restic
kubectl annotate pod my-pod backup.velero.io/backup-volumes=data-volume
```

## Custos

### S3 Storage
- ~$0.023 por GB/mês (Standard)
- Varia com tamanho dos backups

### EBS Snapshots
- ~$0.05 por GB/mês
- Apenas se `enable_volume_snapshots = true`

### Estimativa

Cluster pequeno (10 GB de dados):
- Staging (7 dias): ~$2/mês
- Production (30 dias): ~$7/mês

Cluster médio (100 GB de dados):
- Staging (7 dias): ~$16/mês
- Production (30 dias): ~$70/mês

## Segurança

### Bucket S3
- Versionamento habilitado
- Criptografia AES256
- Acesso público bloqueado
- Bucket policy previne deleção

### IAM
- Princípio do menor privilégio
- IRSA (sem access keys)
- Permissões apenas para bucket específico

### Backups
- Armazenados criptografados
- Retenção automática
- Lifecycle policy

## Monitoramento

### Métricas Prometheus

Velero expõe métricas:
- `velero_backup_total`
- `velero_backup_success_total`
- `velero_backup_failure_total`
- `velero_backup_duration_seconds`

### Alertas Recomendados

```yaml
# Backup falhou
- alert: VeleroBackupFailed
  expr: velero_backup_failure_total > 0
  for: 5m
  annotations:
    summary: "Velero backup failed"

# Nenhum backup nas últimas 24h
- alert: VeleroNoRecentBackup
  expr: time() - velero_backup_last_successful_timestamp > 86400
  annotations:
    summary: "No successful backup in 24h"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Nome do cluster EKS | string | - | yes |
| oidc_provider_arn | ARN do OIDC provider | string | - | yes |
| oidc_issuer_url | URL do OIDC issuer | string | - | yes |
| aws_region | Região AWS | string | - | yes |
| backup_bucket_name | Nome do bucket S3 | string | - | yes |
| backup_schedule | Schedule cron | string | - | yes |
| backup_retention_days | Dias de retenção | number | - | yes |
| enable_volume_snapshots | Habilitar snapshots EBS | bool | true | no |
| backup_namespaces | Namespaces para backup | list(string) | [] | no |
| exclude_namespaces | Namespaces para excluir | list(string) | [...] | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace do Velero |
| backup_bucket_name | Nome do bucket S3 |
| backup_bucket_arn | ARN do bucket S3 |
| service_account_role_arn | ARN da IAM role |
| backup_schedule | Schedule configurado |
| backup_retention_days | Dias de retenção |
