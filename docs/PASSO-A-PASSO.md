# Passo a Passo - Configurar Kubernetes (EKS) na AWS

Guia visual e simplificado para configurar um cluster Kubernetes na AWS usando este template.

## 📋 Visão Geral do Processo

```
┌─────────────────────────────────────────────────────────────┐
│  1. Preparar Ambiente (AWS, Terraform, kubectl)             │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  2. Criar Bucket S3 para State do Terraform                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  3. Configurar Variáveis (terraform.tfvars)                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  4. Executar Terraform (init, plan, apply)                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  5. Configurar kubectl e Acessar o Cluster                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  6. Verificar Componentes da Plataforma                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  7. Deploy da Primeira Aplicação                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Passo 1: Preparar Ambiente

### 1.1 Instalar Ferramentas

**Terraform** (gerenciador de infraestrutura):
```bash
# Linux
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verificar
terraform version
# Deve mostrar: Terraform v1.5.0
```

**AWS CLI** (linha de comando da AWS):
```bash
# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verificar
aws --version
# Deve mostrar: aws-cli/2.x.x
```

**kubectl** (linha de comando do Kubernetes):
```bash
# Linux
curl -LO "https://dl.k8s.io/release/v1.28.0/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar
kubectl version --client
# Deve mostrar: Client Version: v1.28.0
```

### 1.2 Configurar Credenciais AWS

```bash
# Configurar credenciais
aws configure

# Será solicitado:
# AWS Access Key ID: [sua-access-key]
# AWS Secret Access Key: [sua-secret-key]
# Default region name: us-east-1
# Default output format: json

# Verificar se está funcionando
aws sts get-caller-identity
# Deve mostrar seu UserId, Account e Arn
```

### 1.3 Clonar o Repositório

```bash
git clone https://github.com/seu-usuario/terraform-eks-aws-template.git
cd terraform-eks-aws-template
```

✅ **Checkpoint**: Você deve ter Terraform, AWS CLI e kubectl instalados e funcionando.

---

## Passo 2: Criar Bucket S3 para State

O Terraform precisa de um lugar para guardar o "estado" da infraestrutura. Usamos um bucket S3 para isso.

```bash
# Definir nome único para o bucket
BUCKET_NAME="terraform-state-eks-$(date +%s)"
echo "Nome do bucket: $BUCKET_NAME"
# ANOTE ESTE NOME! Você vai precisar dele.

# Criar o bucket
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region us-east-1

# Habilitar versionamento (para histórico)
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

# Habilitar criptografia (segurança)
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Bloquear acesso público (segurança)
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "✅ Bucket criado com sucesso: $BUCKET_NAME"
```

✅ **Checkpoint**: Bucket S3 criado e configurado.

---

## Passo 3: Configurar Variáveis

### 3.1 Escolher Ambiente

Vamos começar com **staging** (ambiente de testes):

```bash
cd live/aws/staging
```

### 3.2 Configurar Backend

Edite o arquivo `backend.tf` e coloque o nome do seu bucket:

```bash
# Abrir editor
nano backend.tf
# ou
vim backend.tf
```

Altere a linha do bucket:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-eks-1234567890"  # ← COLOQUE SEU BUCKET AQUI
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    use_lockfile   = true
  }
}
```

### 3.3 Configurar Variáveis do Cluster

Copie o arquivo de exemplo:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars`:

```bash
nano terraform.tfvars
```

**Configuração Mínima** (você pode usar esses valores):

```hcl
# Região AWS
aws_region   = "us-east-1"

# Nome do cluster (escolha um nome único)
cluster_name = "meu-eks-staging"

# Ambiente
environment  = "staging"

# Rede VPC
vpc_cidr = "10.0.0.0/16"
azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Configuração dos Nodes (servidores do Kubernetes)
node_groups = {
  # Nodes para componentes do sistema
  system = {
    instance_types = ["t3.medium"]    # Tipo de máquina
    min_size       = 2                # Mínimo de nodes
    max_size       = 4                # Máximo de nodes
    desired_size   = 2                # Quantidade inicial
    disk_size      = 50               # Tamanho do disco (GB)
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
  
  # Nodes para suas aplicações
  apps = {
    instance_types = ["t3.large"]     # Tipo de máquina
    min_size       = 2                # Mínimo de nodes
    max_size       = 10               # Máximo de nodes
    desired_size   = 3                # Quantidade inicial
    disk_size      = 100              # Tamanho do disco (GB)
    labels = {
      role = "apps"
    }
    taints = []                       # Sem restrições
  }
}

# Acesso ao cluster
cluster_endpoint_public_access  = true   # Acesso pela internet
cluster_endpoint_private_access = true   # Acesso pela VPC

# Tags (etiquetas para organização)
tags = {
  Environment = "staging"
  ManagedBy   = "Terraform"
  Project     = "Meu-Projeto"
  Owner       = "Seu-Nome"
}
```

✅ **Checkpoint**: Arquivos `backend.tf` e `terraform.tfvars` configurados.

---

## Passo 4: Executar Terraform

### 4.1 Inicializar Terraform

```bash
terraform init
```

Você deve ver:
```
Initializing the backend...
Successfully configured the backend "s3"!
...
Terraform has been successfully initialized!
```

### 4.2 Validar Configuração

```bash
# Verificar se não há erros de sintaxe
terraform validate

# Deve mostrar:
# Success! The configuration is valid.
```

### 4.3 Ver o Plano de Execução

```bash
terraform plan
```

Isso mostra **o que será criado** sem criar nada ainda. Você verá algo como:

```
Plan: 87 to add, 0 to change, 0 to destroy.
```

### 4.4 Criar a Infraestrutura

```bash
terraform apply
```

O Terraform vai mostrar novamente o plano e perguntar:

```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```

Digite `yes` e pressione Enter.

**⏱️ Tempo estimado: 15-20 minutos**

Você verá o progresso:
```
aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s
aws_subnet.private[0]: Creating...
...
aws_eks_cluster.main: Still creating... [10m0s elapsed]
...
Apply complete! Resources: 87 added, 0 changed, 0 destroyed.
```

✅ **Checkpoint**: Cluster EKS criado na AWS!

---

## Passo 5: Configurar kubectl e Acessar o Cluster

### 5.1 Configurar kubectl

```bash
# Atualizar configuração do kubectl
aws eks update-kubeconfig \
  --region us-east-1 \
  --name meu-eks-staging

# Deve mostrar:
# Added new context arn:aws:eks:us-east-1:...:cluster/meu-eks-staging to ~/.kube/config
```

### 5.2 Verificar Acesso

```bash
# Ver os nodes (servidores) do cluster
kubectl get nodes

# Deve mostrar algo como:
# NAME                         STATUS   ROLES    AGE   VERSION
# ip-10-0-1-123.ec2.internal   Ready    <none>   5m    v1.28.0
# ip-10-0-2-456.ec2.internal   Ready    <none>   5m    v1.28.0
# ip-10-0-3-789.ec2.internal   Ready    <none>   5m    v1.28.0
```

### 5.3 Ver Todos os Pods

```bash
kubectl get pods -A

# Você verá pods do sistema rodando:
# NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
# kube-system   aws-node-xxxxx             1/1     Running   0          5m
# kube-system   coredns-xxxxx              1/1     Running   0          10m
# kube-system   kube-proxy-xxxxx           1/1     Running   0          5m
```

✅ **Checkpoint**: kubectl configurado e cluster acessível!

---

## Passo 6: Verificar Componentes da Plataforma

O template instala automaticamente vários componentes. Vamos verificar:

### 6.1 ArgoCD (GitOps)

```bash
# Ver pods do ArgoCD
kubectl get pods -n argocd

# Obter senha do admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""

# Acessar interface web (em outro terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Abrir no navegador: https://localhost:8080
# Usuário: admin
# Senha: (a que você obteve acima)
```

### 6.2 Prometheus/Grafana (Monitoramento)

```bash
# Ver pods de observabilidade
kubectl get pods -n observability

# Acessar Grafana (em outro terminal)
kubectl port-forward svc/kube-prometheus-stack-grafana -n observability 3000:80

# Abrir no navegador: http://localhost:3000
# Usuário: admin
# Senha: prom-operator
```

### 6.3 Verificar Todos os Namespaces

```bash
kubectl get namespaces

# Você deve ver:
# NAME              STATUS   AGE
# argocd            Active   15m
# cert-manager      Active   15m
# external-secrets  Active   15m
# ingress-nginx     Active   15m
# kube-system       Active   20m
# observability     Active   15m
# policy-engine     Active   15m
# velero            Active   15m
```

✅ **Checkpoint**: Todos os componentes da plataforma instalados e funcionando!

---

## Passo 7: Deploy da Primeira Aplicação

### 7.1 Criar um Deployment Simples

```bash
# Criar um deployment do nginx
kubectl create deployment nginx --image=nginx

# Ver o deployment
kubectl get deployments

# Ver os pods
kubectl get pods
```

### 7.2 Expor a Aplicação

```bash
# Criar um service do tipo LoadBalancer
kubectl expose deployment nginx --port=80 --type=LoadBalancer

# Ver o service
kubectl get svc nginx

# Aguardar o LoadBalancer ser criado (pode levar 2-3 minutos)
kubectl get svc nginx -w
```

Quando o EXTERNAL-IP aparecer (não for `<pending>`), você pode acessar:

```bash
# Obter o endereço
EXTERNAL_IP=$(kubectl get svc nginx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Acesse: http://$EXTERNAL_IP"

# Ou testar direto
curl http://$EXTERNAL_IP
```

### 7.3 Limpar o Teste

```bash
# Deletar o service e deployment
kubectl delete svc nginx
kubectl delete deployment nginx
```

✅ **Checkpoint**: Primeira aplicação deployada com sucesso!

---

## 🎉 Parabéns!

Você configurou com sucesso um cluster Kubernetes (EKS) na AWS com:

- ✅ VPC isolada com múltiplas zonas de disponibilidade
- ✅ Cluster EKS com criptografia e logs
- ✅ Node groups otimizados (system e apps)
- ✅ ArgoCD para GitOps
- ✅ Prometheus e Grafana para monitoramento
- ✅ External Secrets para gerenciamento de secrets
- ✅ Ingress Controller para expor aplicações
- ✅ Velero para backup
- ✅ Policy Engine para segurança
- ✅ Compliance (CloudTrail, Config, GuardDuty)

---

## 📊 Resumo dos Recursos Criados

| Recurso | Quantidade | Descrição |
|---------|------------|-----------|
| VPC | 1 | Rede isolada |
| Subnets | 6 | 3 públicas + 3 privadas |
| NAT Gateway | 1 | Para acesso à internet |
| EKS Cluster | 1 | Control plane do Kubernetes |
| Node Groups | 2 | System (2 nodes) + Apps (3 nodes) |
| Load Balancers | ~3 | Para ingress e services |
| S3 Buckets | 2 | State + Backups |
| IAM Roles | ~10 | Para IRSA e nodes |
| Security Groups | ~5 | Firewall rules |

---

## 💰 Custos Estimados

**Staging (configuração acima):**
- EKS Control Plane: ~$73/mês
- EC2 Nodes (5x t3.medium/large): ~$150/mês
- NAT Gateway: ~$32/mês
- Load Balancers: ~$20/mês
- **Total: ~$275/mês**

*Valores aproximados para us-east-1*

---

## 🔄 Próximos Passos

1. **Configurar CI/CD**
   - Integrar com GitHub Actions
   - Automatizar deploys

2. **Configurar Domínio**
   - Registrar domínio no Route53
   - Configurar certificado SSL

3. **Deploy de Aplicações Reais**
   - Usar ArgoCD para GitOps
   - Configurar Ingress para acesso

4. **Configurar Alertas**
   - Prometheus Alertmanager
   - Integração com Slack/PagerDuty

5. **Criar Ambiente de Produção**
   - Repetir processo para `live/aws/prod`
   - Usar configurações mais robustas

---

## 📚 Documentação Adicional

- [Guia Completo](getting-started.md) - Mais detalhes e opções avançadas
- [Referência Rápida](quick-reference.md) - Comandos úteis
- [Troubleshooting](troubleshooting.md) - Resolver problemas
- [Arquitetura](architecture.md) - Entender a arquitetura

---

## 🆘 Precisa de Ajuda?

### Problemas Comuns

**Erro: "Error: error configuring S3 Backend"**
- Verifique se o bucket existe: `aws s3 ls s3://seu-bucket`
- Verifique se o nome está correto no `backend.tf`

**Erro: "Error creating EKS Cluster"**
- Verifique suas permissões IAM
- Verifique se a região está correta

**Pods não iniciam**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**Não consigo acessar o cluster**
```bash
aws eks update-kubeconfig --region us-east-1 --name meu-eks-staging
kubectl get nodes
```

### Suporte

- Consulte [troubleshooting.md](troubleshooting.md)
- Abra uma issue no GitHub
- Entre em contato com o time de plataforma

---

**Última atualização**: 13 de Fevereiro de 2026
