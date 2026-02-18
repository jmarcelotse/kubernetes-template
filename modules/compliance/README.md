# Compliance and Audit Module

Este módulo implementa recursos de compliance e auditoria para o ambiente AWS, incluindo CloudTrail, AWS Config e GuardDuty.

## Funcionalidades

- **CloudTrail**: Auditoria de chamadas API AWS
- **AWS Config**: Monitoramento de configurações e compliance
- **GuardDuty**: Detecção de ameaças
- Bucket S3 dedicado para logs de auditoria
- Proteção contra deleção acidental de logs
- Retenção configurável de logs

## Uso

```hcl
module "compliance" {
  source = "../../modules/compliance"

  environment               = "staging"  # ou "prod"
  aws_region                = "us-east-1"
  audit_log_retention_days  = 90

  enable_cloudtrail  = true
  enable_config      = true
  enable_guardduty   = true
}
```

## Componentes

### CloudTrail

Registra todas as chamadas API feitas na conta AWS:
- Eventos de gerenciamento (criação, modificação, deleção de recursos)
- Eventos de dados (acesso a objetos S3)
- Multi-região habilitado
- Validação de integridade de logs

### AWS Config

Monitora configurações de recursos AWS:
- Registra mudanças de configuração
- Avalia compliance com regras
- Histórico de configurações
- Notificações de mudanças

### GuardDuty

Detecção de ameaças e atividades maliciosas:
- Análise de logs do CloudTrail
- Análise de logs de VPC Flow
- Análise de logs de DNS
- Detecção de comportamento anômalo

## Bucket de Logs

O módulo cria um bucket S3 dedicado para armazenar logs:
- Versionamento habilitado
- Criptografia AES256
- Acesso público bloqueado
- Lifecycle policy para retenção
- Proteção contra deleção

## Verificação

### CloudTrail

```bash
# Listar trails
aws cloudtrail list-trails

# Ver status
aws cloudtrail get-trail-status --name cloudtrail-staging

# Ver eventos recentes
aws cloudtrail lookup-events --max-results 10
```

### AWS Config

```bash
# Ver status do recorder
aws configservice describe-configuration-recorder-status

# Listar recursos monitorados
aws configservice list-discovered-resources --resource-type AWS::EC2::Instance

# Ver histórico de um recurso
aws configservice get-resource-config-history \
  --resource-type AWS::EC2::Instance \
  --resource-id i-1234567890abcdef0
```

### GuardDuty

```bash
# Listar detectores
aws guardduty list-detectors

# Ver findings
aws guardduty list-findings --detector-id <detector-id>

# Ver detalhes de um finding
aws guardduty get-findings \
  --detector-id <detector-id> \
  --finding-ids <finding-id>
```

## Custos

### CloudTrail
- Primeira cópia de eventos de gerenciamento: Grátis
- Eventos de dados: $0.10 por 100.000 eventos
- Armazenamento S3: ~$0.023 por GB/mês

### AWS Config
- $0.003 por item de configuração registrado
- $0.001 por avaliação de regra
- Estimativa: ~$2-10/mês dependendo do número de recursos

### GuardDuty
- Análise de CloudTrail: $4.50 por milhão de eventos
- Análise de VPC Flow Logs: $1.00 por GB
- Análise de DNS Logs: $0.40 por milhão de queries
- Estimativa: ~$5-20/mês para cluster pequeno

## Segurança

### Proteção de Logs

O bucket de logs tem proteção contra deleção:
- Bucket policy nega DeleteBucket e DeleteObject
- Versionamento habilitado
- Lifecycle policy gerencia retenção automaticamente

### Acesso aos Logs

Apenas serviços AWS autorizados podem escrever:
- CloudTrail
- AWS Config

Acesso de leitura deve ser controlado via IAM.

## Compliance

Este módulo ajuda com compliance para:
- **PCI DSS**: Auditoria de acesso e mudanças
- **HIPAA**: Logs de auditoria e monitoramento
- **SOC 2**: Controles de segurança e auditoria
- **ISO 27001**: Gestão de logs e detecção de incidentes

## Alertas Recomendados

### CloudTrail

```yaml
# Alerta se CloudTrail for desabilitado
- alert: CloudTrailDisabled
  expr: aws_cloudtrail_status == 0
  annotations:
    summary: "CloudTrail foi desabilitado"
```

### GuardDuty

```yaml
# Alerta em findings de alta severidade
- alert: GuardDutyHighSeverityFinding
  expr: aws_guardduty_finding_severity >= 7
  annotations:
    summary: "GuardDuty detectou ameaça de alta severidade"
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| environment | Ambiente (staging ou prod) | string | - | yes |
| aws_region | Região AWS | string | - | yes |
| audit_log_retention_days | Dias de retenção de logs | number | 90 | no |
| enable_cloudtrail | Habilitar CloudTrail | bool | true | no |
| enable_config | Habilitar AWS Config | bool | true | no |
| enable_guardduty | Habilitar GuardDuty | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| audit_logs_bucket_name | Nome do bucket de logs |
| audit_logs_bucket_arn | ARN do bucket de logs |
| cloudtrail_id | ID do CloudTrail |
| cloudtrail_arn | ARN do CloudTrail |
| config_recorder_id | ID do Config Recorder |
| guardduty_detector_id | ID do GuardDuty Detector |
