# Guia de Troubleshooting

Este documento lista problemas comuns e suas soluções ao usar o template Terraform EKS AWS.

## Problemas com Backend S3

### Erro: "Error acquiring the state lock"

**Causa:** Outro processo está executando terraform ou um lock ficou travado.

**Solução:**
```bash
# Verificar se há outro processo terraform rodando
ps aux | grep terraform

# Se não houver, forçar remoção do lock (CUIDADO!)
terraform force-unlock <LOCK_ID>
```

### Erro: "NoSuchBucket: The specified bucket does not exist"

**Causa:** Bucket S3 para state não foi criado.

**Solução:**
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

### Erro: "AccessDenied: Access Denied"

**Causa:** Credenciais AWS não têm permissões suficientes.

**Solução:**
```bash
# Verificar credenciais
aws sts get-caller-identity

# Verificar permissões necessárias:
# - s3:GetObject, s3:PutObject no bucket de state
# - s3:ListBucket no bucket de state
```

## Problemas com VPC

### Erro: "VpcLimitExceeded"

**Causa:** Limite de VPCs na região foi atingido (padrão: 5).

**Solução:**
```bash
# Listar VPCs existentes
aws ec2 describe-vpcs --region us-east-1

# Deletar VPCs não utilizadas ou solicitar aumento de quota
aws service-quotas request-service-quota-increase \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --desired-value 10
```

### Erro: "InvalidCidrBlock"

**Causa:** CIDR block inválido ou conflitante.

**Solução:**
- Verificar formato do CIDR (ex: 10.0.0.0/16)
- Garantir que não conflita com outras VPCs
- Usar CIDRs únicos por ambiente

## Problemas com EKS

### Erro: "ResourceInUseException: Cluster already exists"

**Causa:** Cluster com mesmo nome já existe.

**Solução:**
```bash
# Listar clusters existentes
aws eks list-clusters --region us-east-1

# Usar nome único ou deletar cluster existente
aws eks delete-cluster --name <cluster-name> --region us-east-1
```

### Erro: "UnsupportedAvailabilityZoneException"

**Causa:** AZ não suporta EKS.

**Solução:**
```bash
# Verificar AZs disponíveis para EKS
aws ec2 describe-availability-zones \
  --region us-east-1 \
  --filters Name=zone-type,Values=availability-zone

# Atualizar variável availability_zones com AZs válidas
```

### Erro: Timeout na criação do cluster

**Causa:** Criação do cluster pode levar 15-20 minutos.

**Solução:**
```bash
# Aumentar timeout no provider
# Em main.tf, adicionar:
provider "aws" {
  # ...
  max_retries = 10
}

# Verificar status do cluster
aws eks describe-cluster --name <cluster-name> --region us-east-1
```

### Erro: "InvalidParameterException: Kubernetes version X.XX is not supported"

**Causa:** Versão do Kubernetes não é suportada pela AWS.

**Solução:**
```bash
# Verificar versões suportadas
aws eks describe-addon-versions --region us-east-1 \
  --query 'addons[0].addonVersions[0].compatibilities[*].clusterVersion' \
  --output text | tr '\t' '\n' | sort -u

# Atualizar variável cluster_version
```

## Problemas com Node Groups

### Erro: "NodeCreationFailure"

**Causa:** Nodes não conseguem se registrar no cluster.

**Solução:**
```bash
# Verificar logs do node
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=<cluster-name>"

# Verificar security groups
# Verificar IAM role do node group
# Verificar se subnets têm acesso à internet (via NAT)
```

### Erro: "InsufficientInstanceCapacity"

**Causa:** AWS não tem capacidade para o instance type solicitado.

**Solução:**
- Tentar outra AZ
- Usar instance type diferente
- Adicionar múltiplos instance types no node group

### Erro: Nodes em estado "NotReady"

**Causa:** Problema de rede ou configuração.

**Solução:**
```bash
# Conectar ao cluster
aws eks update-kubeconfig --name <cluster-name> --region us-east-1

# Verificar nodes
kubectl get nodes
kubectl describe node <node-name>

# Verificar logs
kubectl logs -n kube-system -l k8s-app=aws-node
```

## Problemas com Helm

### Erro: "Kubernetes cluster unreachable"

**Causa:** Kubeconfig não configurado ou cluster inacessível.

**Solução:**
```bash
# Atualizar kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-east-1

# Testar conectividade
kubectl cluster-info
kubectl get nodes
```

### Erro: "release: not found"

**Causa:** Release Helm não existe ou foi deletado fora do Terraform.

**Solução:**
```bash
# Listar releases
helm list -A

# Importar release existente ou recriar
terraform import module.argocd.helm_release.argocd argocd/argocd
```

### Erro: Timeout na instalação do Helm chart

**Causa:** Chart demora muito para ficar ready.

**Solução:**
```bash
# Aumentar timeout no recurso helm_release
resource "helm_release" "example" {
  # ...
  timeout = 600  # 10 minutos
  wait    = true
}

# Verificar pods
kubectl get pods -n <namespace>
kubectl describe pod <pod-name> -n <namespace>
```

## Problemas com IRSA

### Erro: "AccessDenied" em pods usando IRSA

**Causa:** Service account não tem anotação correta ou role não tem permissões.

**Solução:**
```bash
# Verificar service account
kubectl get sa <service-account> -n <namespace> -o yaml

# Deve ter anotação:
# eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/ROLE_NAME

# Verificar trust policy da role
aws iam get-role --role-name <role-name>

# Verificar policies anexadas
aws iam list-attached-role-policies --role-name <role-name>
```

## Problemas com Terraform

### Erro: "Error: Invalid for_each argument"

**Causa:** Variável usada em for_each não é conhecida em plan time.

**Solução:**
- Usar valores estáticos ou variáveis simples
- Evitar depends_on desnecessários
- Usar data sources quando apropriado

### Erro: "Error: Cycle"

**Causa:** Dependência circular entre recursos.

**Solução:**
- Revisar depends_on
- Quebrar dependências circulares
- Usar data sources para quebrar ciclos

### Erro: State drift detectado

**Causa:** Recursos foram modificados fora do Terraform.

**Solução:**
```bash
# Ver diferenças
terraform plan

# Atualizar state para refletir realidade
terraform refresh

# Ou importar mudanças
terraform import <resource> <id>
```

## Problemas de Performance

### Terraform plan/apply muito lento

**Causa:** Muitos recursos ou providers lentos.

**Solução:**
- Usar `-parallelism=N` para aumentar paralelismo
- Dividir em múltiplos workspaces
- Usar `-target` para aplicar recursos específicos (desenvolvimento)

### Cluster lento ou instável

**Causa:** Recursos insuficientes ou configuração inadequada.

**Solução:**
```bash
# Verificar uso de recursos
kubectl top nodes
kubectl top pods -A

# Verificar eventos
kubectl get events -A --sort-by='.lastTimestamp'

# Escalar node groups se necessário
# Ajustar resource requests/limits dos pods
```

## Debugging Avançado

### Habilitar logs detalhados do Terraform

```bash
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform-debug.log
terraform apply
```

### Verificar state do Terraform

```bash
# Listar recursos
terraform state list

# Ver detalhes de um recurso
terraform state show <resource>

# Remover recurso do state (CUIDADO!)
terraform state rm <resource>
```

### Verificar configuração do cluster

```bash
# Detalhes do cluster
aws eks describe-cluster --name <cluster-name> --region us-east-1

# Verificar addons
aws eks list-addons --cluster-name <cluster-name> --region us-east-1

# Verificar node groups
aws eks list-nodegroups --cluster-name <cluster-name> --region us-east-1
```

## Recuperação de Desastres

### State corrompido

```bash
# Restaurar de backup (versionamento S3)
aws s3api list-object-versions \
  --bucket terraform-state-eks-template \
  --prefix staging/terraform.tfstate

# Copiar versão anterior
aws s3api get-object \
  --bucket terraform-state-eks-template \
  --key staging/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.backup
```

### Cluster inacessível

```bash
# Verificar security groups
# Verificar endpoint configuration
# Verificar VPC e subnets

# Recriar kubeconfig
aws eks update-kubeconfig --name <cluster-name> --region us-east-1
```

## Recursos Úteis

- [Terraform AWS Provider Issues](https://github.com/hashicorp/terraform-provider-aws/issues)
- [EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug/)
- [AWS Service Health Dashboard](https://status.aws.amazon.com/)

## Suporte

Se o problema persistir:
1. Verificar logs detalhados
2. Consultar documentação oficial
3. Buscar issues similares no GitHub
4. Abrir issue com logs e contexto completo
5. Contatar time de plataforma
