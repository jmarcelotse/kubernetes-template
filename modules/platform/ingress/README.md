# Ingress Module

Este módulo instala e configura ingress controller (AWS Load Balancer Controller ou NGINX), cert-manager para TLS automático e external-dns para gerenciamento de DNS.

## Funcionalidades

- **Ingress Controller**: AWS ALB ou NGINX (selecionável)
- **cert-manager**: Gerenciamento automático de certificados TLS com Let's Encrypt
- **external-dns**: Criação automática de registros DNS no Route53
- IRSA configurado para AWS Load Balancer Controller e external-dns
- Suporte para múltiplos domínios e paths
- TLS/SSL automático

## Uso

```hcl
module "ingress" {
  source = "../../modules/platform/ingress"

  ingress_type       = "alb"  # ou "nginx"
  cluster_name       = "my-cluster"
  oidc_provider_arn  = module.eks.oidc_provider_arn
  oidc_issuer_url    = module.eks.cluster_oidc_issuer_url
  vpc_id             = module.eks.vpc_id
  aws_region         = "us-east-1"
  
  route53_zone_id    = "Z1234567890ABC"
  domain_name        = "example.com"
  cert_manager_email = "admin@example.com"
  
  letsencrypt_environment = "production"  # ou "staging"
}
```

## AWS Load Balancer Controller vs NGINX

### AWS Load Balancer Controller (ALB)

**Vantagens:**
- Integração nativa com AWS
- ALB gerenciado pela AWS (sem manutenção de pods)
- Suporte para WAF, Shield, Cognito
- Target type IP ou instance
- Melhor para workloads AWS-native

**Desvantagens:**
- Apenas AWS
- Menos features de proxy avançadas
- Custo de ALB por hora

### NGINX Ingress Controller

**Vantagens:**
- Portável (funciona em qualquer cloud)
- Features avançadas (rewrite, auth, rate limiting)
- Melhor performance para muitas regras
- Um único NLB para todos os ingresses

**Desvantagens:**
- Precisa gerenciar pods do NGINX
- Menos integração com serviços AWS

## Criando um Ingress

### Pré-requisitos

1. Service do Kubernetes expondo sua aplicação
2. Domínio configurado no Route53

### Exemplo Básico (ALB)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  ingressClassName: alb
  tls:
    - hosts:
        - app.example.com
      secretName: my-app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

### Exemplo Básico (NGINX)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
  namespace: default
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-production
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - app.example.com
      secretName: my-app-tls
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app
                port:
                  number: 80
```

## Como Funciona

### 1. Criar Ingress

Você cria um recurso Ingress com:
- Host (domínio)
- Path
- Backend service
- Anotação `cert-manager.io/cluster-issuer`

### 2. cert-manager Cria Certificado

cert-manager detecta a anotação e:
1. Cria um Certificate resource
2. Solicita certificado ao Let's Encrypt
3. Completa desafio HTTP-01
4. Armazena certificado em Secret

### 3. external-dns Cria DNS

external-dns detecta o Ingress e:
1. Extrai o hostname
2. Obtém o endereço do Load Balancer
3. Cria registro A no Route53

### 4. Tráfego Flui

```
Cliente → DNS (Route53) → Load Balancer → Ingress Controller → Service → Pods
```

## Verificação

### Verificar Ingress

```bash
# Listar ingresses
kubectl get ingress -A

# Detalhes de um ingress
kubectl describe ingress my-app -n default

# Ver endereço do load balancer
kubectl get ingress my-app -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Verificar Certificado TLS

```bash
# Listar certificates
kubectl get certificate -A

# Status de um certificate
kubectl describe certificate my-app-tls -n default

# Ver secret do certificado
kubectl get secret my-app-tls -n default
```

### Verificar DNS

```bash
# Verificar registro no Route53
aws route53 list-resource-record-sets \
  --hosted-zone-id Z1234567890ABC \
  --query "ResourceRecordSets[?Name=='app.example.com.']"

# Testar resolução DNS
nslookup app.example.com
dig app.example.com
```

### Testar Acesso

```bash
# HTTP
curl http://app.example.com

# HTTPS
curl https://app.example.com

# Ver certificado
curl -vI https://app.example.com 2>&1 | grep -A 10 "Server certificate"
```

## Troubleshooting

### Ingress não cria Load Balancer

**ALB:**
```bash
# Verificar logs do controller
kubectl logs -n ingress -l app.kubernetes.io/name=aws-load-balancer-controller

# Verificar eventos
kubectl get events -n default --sort-by='.lastTimestamp'
```

**NGINX:**
```bash
# Verificar pods
kubectl get pods -n ingress -l app.kubernetes.io/name=ingress-nginx

# Verificar logs
kubectl logs -n ingress -l app.kubernetes.io/name=ingress-nginx
```

### Certificado TLS não é criado

```bash
# Verificar certificate
kubectl describe certificate my-app-tls -n default

# Verificar certificaterequest
kubectl get certificaterequest -n default
kubectl describe certificaterequest <name> -n default

# Verificar challenge (desafio HTTP-01)
kubectl get challenge -n default
kubectl describe challenge <name> -n default

# Verificar logs do cert-manager
kubectl logs -n cert-manager -l app=cert-manager
```

Problemas comuns:
- Ingress não está acessível (firewall, security group)
- Domínio não aponta para load balancer
- Rate limit do Let's Encrypt (use staging para testes)

### DNS não é criado

```bash
# Verificar logs do external-dns
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Verificar permissões IAM
aws sts get-caller-identity

# Verificar zona Route53
aws route53 get-hosted-zone --id Z1234567890ABC
```

Problemas comuns:
- Permissões IAM insuficientes
- Zona Route53 incorreta
- Domain filter não corresponde

### Erro 502/503/504

```bash
# Verificar se service existe
kubectl get svc my-app -n default

# Verificar se pods estão rodando
kubectl get pods -n default -l app=my-app

# Verificar health check
kubectl describe ingress my-app -n default | grep -A 5 "health"

# Testar service diretamente
kubectl port-forward svc/my-app 8080:80 -n default
curl http://localhost:8080
```

## Let's Encrypt Rate Limits

Let's Encrypt tem rate limits:
- 50 certificados por domínio registrado por semana
- 5 certificados duplicados por semana

**Para desenvolvimento/testes:**
```hcl
letsencrypt_environment = "staging"
```

**Para produção:**
```hcl
letsencrypt_environment = "production"
```

## Segurança

### ALB Security Groups

O AWS Load Balancer Controller cria security groups automaticamente. Para customizar:

```yaml
annotations:
  alb.ingress.kubernetes.io/security-groups: sg-xxx,sg-yyy
```

### NGINX Rate Limiting

```yaml
annotations:
  nginx.ingress.kubernetes.io/limit-rps: "100"
  nginx.ingress.kubernetes.io/limit-connections: "10"
```

### IP Whitelist

```yaml
annotations:
  nginx.ingress.kubernetes.io/whitelist-source-range: "10.0.0.0/8,192.168.0.0/16"
```

### Autenticação Básica

```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

## Custos

### ALB
- ~$0.0225 por hora por ALB (~$16/mês)
- $0.008 por LCU-hora
- Cada Ingress cria um ALB separado (pode ser caro)

### NGINX
- Um único NLB (~$16/mês)
- Custo de pods do NGINX (CPU/memory)
- Mais econômico para muitos ingresses

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| ingress_type | Tipo de ingress (alb ou nginx) | string | "alb" | no |
| cluster_name | Nome do cluster EKS | string | - | yes |
| oidc_provider_arn | ARN do OIDC provider | string | - | yes |
| oidc_issuer_url | URL do OIDC issuer | string | - | yes |
| vpc_id | ID da VPC | string | - | yes |
| aws_region | Região AWS | string | - | yes |
| route53_zone_id | ID da zona Route53 | string | - | yes |
| domain_name | Nome de domínio base | string | - | yes |
| cert_manager_email | Email para Let's Encrypt | string | - | yes |
| letsencrypt_environment | Ambiente LE (staging/production) | string | "production" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace_ingress | Namespace do ingress controller |
| namespace_cert_manager | Namespace do cert-manager |
| namespace_external_dns | Namespace do external-dns |
| ingress_type | Tipo de ingress instalado |
| ingress_class | IngressClass a usar |
| cluster_issuer_name | Nome do ClusterIssuer |
