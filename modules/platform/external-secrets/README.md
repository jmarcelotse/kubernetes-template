# External Secrets Operator Module

Este módulo instala e configura o External Secrets Operator no cluster Kubernetes para sincronização automática de secrets do AWS Secrets Manager e SSM Parameter Store.

## Funcionalidades

- Instalação do External Secrets Operator via Helm
- IRSA (IAM Roles for Service Accounts) configurado automaticamente
- ClusterSecretStore para AWS Secrets Manager
- ClusterSecretStore para AWS SSM Parameter Store
- Permissões IAM configuradas para acesso a secrets
- Execução em node group system com tolerations

## Uso

```hcl
module "external_secrets" {
  source = "../../modules/platform/external-secrets"

  cluster_name       = "my-cluster"
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_issuer_url    = module.eks.cluster_oidc_issuer_url
  aws_region         = "us-east-1"
  
  # Opcional: restringir acesso a secrets específicos
  secrets_manager_arns = [
    "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/*"
  ]
  
  ssm_parameter_arns = [
    "arn:aws:ssm:us-east-1:123456789012:parameter/prod/*"
  ]
}
```

## Criando Secrets no AWS

### AWS Secrets Manager

```bash
# Criar secret com JSON
aws secretsmanager create-secret \
  --name prod/database/credentials \
  --secret-string '{"username":"admin","password":"secret123"}'

# Criar secret com string simples
aws secretsmanager create-secret \
  --name prod/app/api-key \
  --secret-string "my-api-key-value"
```

### AWS SSM Parameter Store

```bash
# Criar parâmetro SecureString
aws ssm put-parameter \
  --name /prod/app/api-key \
  --value "my-api-key-value" \
  --type SecureString

# Criar parâmetro String
aws ssm put-parameter \
  --name /prod/app/config \
  --value "some-config-value" \
  --type String
```

## Usando ExternalSecret

Veja exemplos completos em `examples/external-secret-example.yaml`.

### Exemplo Básico

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: my-app-secret
  namespace: default
spec:
  refreshInterval: 1h
  
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  
  target:
    name: my-app-secret
    creationPolicy: Owner
  
  data:
    - secretKey: password
      remoteRef:
        key: prod/database/credentials
        property: password
```

Isso criará um Secret do Kubernetes:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-app-secret
  namespace: default
type: Opaque
data:
  password: <base64-encoded-value>
```

## Verificação

```bash
# Verificar instalação
kubectl get pods -n external-secrets

# Verificar ClusterSecretStores
kubectl get clustersecretstore

# Verificar status de um ExternalSecret
kubectl get externalsecret -n default
kubectl describe externalsecret my-app-secret -n default

# Verificar se o Secret foi criado
kubectl get secret my-app-secret -n default
```

## Troubleshooting

### ExternalSecret não sincroniza

1. Verificar status do ExternalSecret:
```bash
kubectl describe externalsecret <name> -n <namespace>
```

2. Verificar logs do operator:
```bash
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
```

3. Verificar se o secret existe no AWS:
```bash
aws secretsmanager describe-secret --secret-id <secret-name>
```

4. Verificar permissões IAM:
```bash
# Ver role ARN
kubectl get sa external-secrets -n external-secrets -o yaml | grep role-arn

# Testar permissões
aws sts assume-role-with-web-identity \
  --role-arn <role-arn> \
  --role-session-name test \
  --web-identity-token <token>
```

### Erro de permissão

Se você ver erros como "AccessDeniedException", verifique:

1. A IAM role tem as permissões corretas
2. Os ARNs em `secrets_manager_arns` e `ssm_parameter_arns` estão corretos
3. O trust policy da role permite o service account correto

### Secret não atualiza

O External Secrets Operator sincroniza secrets baseado no `refreshInterval`. Para forçar atualização:

```bash
kubectl annotate externalsecret <name> \
  force-sync=$(date +%s) \
  -n <namespace>
```

## Segurança

### Princípio do Menor Privilégio

Por padrão, o módulo permite acesso a todos os secrets (`*`). Em produção, restrinja o acesso:

```hcl
secrets_manager_arns = [
  "arn:aws:secretsmanager:us-east-1:123456789012:secret:prod/app/*"
]

ssm_parameter_arns = [
  "arn:aws:ssm:us-east-1:123456789012:parameter/prod/app/*"
]
```

### Rotação de Secrets

O External Secrets Operator detecta automaticamente mudanças nos secrets do AWS e atualiza os Secrets do Kubernetes baseado no `refreshInterval`.

Para secrets críticos, use um `refreshInterval` menor:

```yaml
spec:
  refreshInterval: 5m  # Verificar a cada 5 minutos
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| cluster_name | Nome do cluster EKS | string | - | yes |
| oidc_provider_arn | ARN do OIDC provider | string | - | yes |
| oidc_issuer_url | URL do OIDC issuer | string | - | yes |
| aws_region | Região AWS | string | - | yes |
| secrets_manager_arns | ARNs de secrets permitidos | list(string) | ["*"] | no |
| ssm_parameter_arns | ARNs de parâmetros permitidos | list(string) | ["*"] | no |
| namespace | Namespace para operator | string | "external-secrets" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace onde operator foi instalado |
| service_account_role_arn | ARN da IAM role |
| cluster_secret_store_name | Nome do ClusterSecretStore (Secrets Manager) |
| cluster_secret_store_ssm_name | Nome do ClusterSecretStore (Parameter Store) |
