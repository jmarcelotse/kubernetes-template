# Guia de Uso - Terraform EKS AWS Template

Este guia fornece instruções passo a passo para usar o template Terraform EKS AWS.

## 📋 Índice

1. [Pré-requisitos](#pré-requisitos)
2. [Configuração Inicial](#configuração-inicial)
3. [Deploy do Primeiro Cluster](#deploy-do-primeiro-cluster)
4. [Configuração dos Módulos de Plataforma](#configuração-dos-módulos-de-plataforma)
5. [Acesso ao Cluster](#acesso-ao-cluster)
6. [Deploy de Aplicações](#deploy-de-aplicações)
7. [Manutenção e Atualizações](#manutenção-e-atualizações)
8. [Troubleshooting](#troubleshooting)

---

## Pré-requisitos

### Ferramentas Necessárias

1. **Terraform** >= 1.5.0
   ```bash
   # Verificar versão
   terraform version
   
   # Instalar (Linux)
   wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
   unzip terraform_1.5.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

2. **AWS CLI** >= 2.0
   ```bash
   # Verificar versão
   aws --version
   
   # Instalar (Linux)
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

3. **kubectl** >= 1.24
   ```bash
   # Verificar versão
   kubectl version --client
   
   # Instalar (Linux)
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

4. **helm** >= 3.0 (opcional, mas recomendado)
   ```bash
   # Verificar versão
   helm version
   
   # Instalar (Linux)
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

### Permissões AWS Necessárias

Sua conta AWS precisa das seguintes permissões:

- **EC2**: Criar VPCs, subnets, security groups, NAT gateways
- **EKS**: Criar e gerenciar clusters EKS
- **IAM**: Criar roles e policies
- **S3**: Criar e gerenciar buckets (para state e backups)
- **KMS**: Criar e gerenciar chaves de criptografia
- **CloudWatch**: Criar log groups
- **CloudTrail**: Configurar trilhas de auditoria
- **Config**: Configurar AWS Config
- **GuardDuty**: Habilitar GuardDuty

**Recomendação**: Use uma role com `AdministratorAccess` para o primeiro deploy, depois restrinja conforme necessário.

### Configurar Credenciais AWS

```bash
# Configurar credenciais
aws configure

# Ou usar variáveis de ambiente
export AWS_ACCESS_KEY_ID="sua-access-key"
export AWS_SECRET_ACCESS_KEY="sua-secret-key"
export AWS_DEFAULT_REGION="us-east-1"

# Verificar credenciais
aws sts get-caller-identity
```

---

## Configuração Inicial

### 1. Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/terraform-eks-aws-template.git
cd terraform-eks-aws-template
```

### 2. Criar Bucket S3 para State

O Terraform precisa de um bucket S3 para armazenar o state. Crie um bucket **antes** do primeiro apply:

```bash
# Definir variáveis
BUCKET_NAME="terraform-state-eks-$(date +%s)"
REGION="us-east-1"

# Criar bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

# Habilitar versionamento
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Habilitar criptografia
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Bloquear acesso público
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Bucket criado: $BUCKET_NAME"
```

**Importante**: Anote o nome do bucket, você precisará dele na configuração.

### 3. Configurar Backend

Edite o arquivo `backend.tf` no ambiente desejado:

```bash
cd live/aws/staging
```

Edite `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "SEU-BUCKET-AQUI"  # Nome do bucket criado acima
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
```

---

## Deploy do Primeiro Cluster

### 1. Configurar Variáveis

Copie o arquivo de exemplo e edite com seus valores:

```bash
cd live/aws/staging
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars`:

```hcl
# Configurações Básicas
aws_region   = "us-east-1"
cluster_name = "eks-staging"
environment  = "staging"

# VPC
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Node Groups
node_groups = {
  system = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    disk_size      = 50
    labels = {
      role = "system"
    }
    taints = [
      {
        key    = "CriticalAddonsOnly"
        value  = "true"
        effect = "NoSchedule"
      }
    ]
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

# Cluster Access
cluster_endpoint_public_access  = true
cluster_endpoint_private_access = true

# Tags
tags = {
  Environment = "staging"
  ManagedBy   = "Terraform"
  Project     = "EKS-Template"
  Owner       = "Platform-Team"
  Purpose     = "Kubernetes-Cluster"
}
```

### 2. Inicializar Terraform

```bash
terraform init
```

Você deve ver:

```
Terraform has been successfully initialized!
```

### 3. Validar Configuração

```bash
# Validar sintaxe
terraform validate

# Formatar código
terraform fmt -recursive

# Ver plano de execução
terraform plan
```

### 4. Aplicar Configuração

```bash
terraform apply
```

Digite `yes` quando solicitado.

**Tempo estimado**: 15-20 minutos para o cluster completo.

### 5. Verificar Recursos Criados

```bash
# Listar recursos criados
terraform state list

# Ver outputs
terraform output
```

---

## Configuração dos Módulos de Plataforma

### ArgoCD

O ArgoCD é instalado automaticamente. Para acessar:

```bash
# Obter senha do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Acessar: https://localhost:8080
# Usuário: admin
# Senha: (obtida acima)
```

### Observabilidade (Prometheus/Grafana)

```bash
# Port forward Grafana
kubectl port-forward svc/kube-prometheus-stack-grafana -n observability 3000:80

# Acessar: http://localhost:3000
# Usuário: admin
# Senha: prom-operator (padrão)
```

### External Secrets

Criar um secret no AWS Secrets Manager:

```bash
# Criar secret
aws secretsmanager create-secret \
  --name staging/app/database \
  --secret-string '{"username":"admin","password":"senha123"}'

# Criar ExternalSecret no Kubernetes
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: default
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: staging/app/database
      property: username
  - secretKey: password
    remoteRef:
      key: staging/app/database
      property: password
EOF
```

### Ingress

Exemplo de Ingress com ALB:

```bash
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789012:certificate/xxx
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
EOF
```

---

## Acesso ao Cluster

### Configurar kubectl

```bash
# Atualizar kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name eks-staging

# Verificar acesso
kubectl get nodes
kubectl get pods -A
```

### Criar Usuários IAM para Acesso

Edite o ConfigMap `aws-auth`:

```bash
kubectl edit configmap aws-auth -n kube-system
```

Adicione usuários:

```yaml
mapUsers: |
  - userarn: arn:aws:iam::123456789012:user/developer
    username: developer
    groups:
      - system:masters
```

---

## Deploy de Aplicações

### Método 1: kubectl direto

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

### Método 2: ArgoCD (Recomendado)

1. Criar repositório Git com manifests
2. Criar Application no ArgoCD:

```bash
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/seu-usuario/app-manifests
    targetRevision: HEAD
    path: k8s
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Método 3: Helm

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/nginx
```

---

## Manutenção e Atualizações

### Atualizar Versão do Kubernetes

1. Edite `terraform.tfvars`:
   ```hcl
   cluster_version = "1.29"
   ```

2. Aplique:
   ```bash
   terraform apply
   ```

### Atualizar Node Groups

1. Edite configurações em `terraform.tfvars`
2. Aplique:
   ```bash
   terraform apply
   ```

O Terraform fará rolling update dos nodes.

### Backup e Restore com Velero

```bash
# Criar backup
velero backup create my-backup

# Listar backups
velero backup get

# Restaurar backup
velero restore create --from-backup my-backup
```

### Escalar Node Groups

```bash
# Via Terraform (permanente)
# Edite terraform.tfvars e aplique

# Via kubectl (temporário)
kubectl scale deployment my-app --replicas=5
```

---

## Troubleshooting

### Cluster não cria

```bash
# Verificar logs do Terraform
terraform apply -debug

# Verificar eventos do EKS
aws eks describe-cluster --name eks-staging
```

### Pods não iniciam

```bash
# Ver eventos
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>

# Verificar node groups
kubectl get nodes
kubectl describe node <node-name>
```

### Problemas de rede

```bash
# Testar conectividade
kubectl run test --image=busybox --rm -it -- sh
# Dentro do pod:
nslookup kubernetes.default
ping 8.8.8.8
```

### State lock

```bash
# Se o state ficar travado
terraform force-unlock <LOCK_ID>
```

Para mais problemas, consulte [troubleshooting.md](troubleshooting.md).

---

## Próximos Passos

1. ✅ Deploy do cluster staging
2. ✅ Configurar acesso de usuários
3. ✅ Deploy de aplicação de teste
4. ⏭️ Configurar monitoramento e alertas
5. ⏭️ Configurar backup automático
6. ⏭️ Deploy do cluster production
7. ⏭️ Configurar CI/CD completo

---

## Recursos Adicionais

- [Arquitetura](architecture.md)
- [Otimização de Custos](cost-optimization.md)
- [Diferenças entre Ambientes](environment-differences.md)
- [Troubleshooting](troubleshooting.md)
- [Documentação AWS EKS](https://docs.aws.amazon.com/eks/)
- [Documentação Terraform](https://www.terraform.io/docs)

---

## Suporte

Para dúvidas ou problemas:
- Abra uma issue no GitHub
- Consulte a documentação
- Entre em contato com o time de plataforma
