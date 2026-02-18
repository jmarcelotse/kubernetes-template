# Referência Rápida - Comandos Úteis

Guia de referência rápida com os comandos mais usados.

## 🚀 Terraform

### Comandos Básicos

```bash
# Inicializar
terraform init

# Validar
terraform validate

# Formatar
terraform fmt -recursive

# Planejar
terraform plan

# Aplicar
terraform apply

# Destruir
terraform destroy

# Ver state
terraform state list
terraform state show <resource>

# Ver outputs
terraform output
terraform output -json
```

### Comandos Avançados

```bash
# Importar recurso existente
terraform import aws_eks_cluster.main eks-staging

# Remover recurso do state (sem destruir)
terraform state rm aws_eks_cluster.main

# Mover recurso no state
terraform state mv aws_eks_cluster.old aws_eks_cluster.new

# Desbloquear state
terraform force-unlock <LOCK_ID>

# Refresh state
terraform refresh

# Taint resource (forçar recriação)
terraform taint aws_eks_node_group.apps

# Untaint resource
terraform untaint aws_eks_node_group.apps
```

## ☸️ Kubernetes (kubectl)

### Comandos Básicos

```bash
# Configurar kubeconfig
aws eks update-kubeconfig --region us-east-1 --name eks-staging

# Ver contextos
kubectl config get-contexts
kubectl config use-context <context>

# Ver recursos
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
kubectl get deployments -A

# Descrever recurso
kubectl describe node <node-name>
kubectl describe pod <pod-name>

# Ver logs
kubectl logs <pod-name>
kubectl logs <pod-name> -f  # follow
kubectl logs <pod-name> --previous  # logs do container anterior

# Executar comando em pod
kubectl exec -it <pod-name> -- sh
kubectl exec <pod-name> -- ls /app

# Port forward
kubectl port-forward svc/<service-name> 8080:80
kubectl port-forward pod/<pod-name> 8080:80
```

### Comandos Avançados

```bash
# Ver eventos
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -w  # watch

# Top (uso de recursos)
kubectl top nodes
kubectl top pods -A

# Escalar deployment
kubectl scale deployment <name> --replicas=5

# Editar recurso
kubectl edit deployment <name>

# Aplicar manifests
kubectl apply -f manifest.yaml
kubectl apply -f directory/

# Deletar recursos
kubectl delete pod <pod-name>
kubectl delete -f manifest.yaml

# Ver YAML de recurso
kubectl get pod <pod-name> -o yaml
kubectl get deployment <name> -o json

# Copiar arquivos
kubectl cp <pod-name>:/path/to/file ./local-file
kubectl cp ./local-file <pod-name>:/path/to/file

# Rollout
kubectl rollout status deployment/<name>
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout restart deployment/<name>
```

## 🔍 Debug e Troubleshooting

### Verificar Cluster

```bash
# Status do cluster
aws eks describe-cluster --name eks-staging

# Ver node groups
aws eks list-nodegroups --cluster-name eks-staging
aws eks describe-nodegroup --cluster-name eks-staging --nodegroup-name system

# Ver addons
aws eks list-addons --cluster-name eks-staging

# Ver logs do control plane
aws logs tail /aws/eks/eks-staging/cluster --follow
```

### Debug de Pods

```bash
# Ver por que pod não está rodando
kubectl describe pod <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>

# Ver logs de todos os containers
kubectl logs <pod-name> --all-containers=true

# Ver logs de container específico
kubectl logs <pod-name> -c <container-name>

# Executar pod de debug
kubectl run debug --image=busybox --rm -it -- sh

# Debug de rede
kubectl run netshoot --image=nicolaka/netshoot --rm -it -- bash
# Dentro do pod:
nslookup kubernetes.default
curl http://service-name.namespace.svc.cluster.local
ping 8.8.8.8
```

### Debug de Nodes

```bash
# Ver nodes com problemas
kubectl get nodes | grep NotReady

# Ver uso de recursos
kubectl describe node <node-name> | grep -A 5 "Allocated resources"

# Ver taints e labels
kubectl describe node <node-name> | grep -A 10 "Taints"
kubectl describe node <node-name> | grep -A 10 "Labels"

# Cordon/Uncordon (impedir novos pods)
kubectl cordon <node-name>
kubectl uncordon <node-name>

# Drain (remover pods do node)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
```

## 🔐 AWS CLI

### EKS

```bash
# Listar clusters
aws eks list-clusters

# Descrever cluster
aws eks describe-cluster --name eks-staging

# Atualizar kubeconfig
aws eks update-kubeconfig --name eks-staging --region us-east-1

# Listar node groups
aws eks list-nodegroups --cluster-name eks-staging

# Descrever node group
aws eks describe-nodegroup \
  --cluster-name eks-staging \
  --nodegroup-name system
```

### S3 (State)

```bash
# Listar buckets
aws s3 ls

# Ver conteúdo do bucket
aws s3 ls s3://terraform-state-eks-template/

# Baixar state
aws s3 cp s3://terraform-state-eks-template/staging/terraform.tfstate ./

# Ver versionamento
aws s3api list-object-versions \
  --bucket terraform-state-eks-template \
  --prefix staging/terraform.tfstate
```

### IAM

```bash
# Listar roles
aws iam list-roles | grep eks

# Ver role
aws iam get-role --role-name eks-cluster-role

# Listar policies de uma role
aws iam list-attached-role-policies --role-name eks-cluster-role
```

### CloudWatch Logs

```bash
# Listar log groups
aws logs describe-log-groups | grep eks

# Ver logs
aws logs tail /aws/eks/eks-staging/cluster --follow

# Filtrar logs
aws logs filter-log-events \
  --log-group-name /aws/eks/eks-staging/cluster \
  --filter-pattern "error"
```

## 🎯 ArgoCD

```bash
# Login
argocd login localhost:8080

# Listar apps
argocd app list

# Ver detalhes de app
argocd app get <app-name>

# Sync app
argocd app sync <app-name>

# Ver diff
argocd app diff <app-name>

# Ver histórico
argocd app history <app-name>

# Rollback
argocd app rollback <app-name> <revision>

# Deletar app
argocd app delete <app-name>
```

## 📊 Prometheus/Grafana

```bash
# Port forward Prometheus
kubectl port-forward -n observability svc/kube-prometheus-stack-prometheus 9090:9090

# Port forward Grafana
kubectl port-forward -n observability svc/kube-prometheus-stack-grafana 3000:80

# Port forward Alertmanager
kubectl port-forward -n observability svc/kube-prometheus-stack-alertmanager 9093:9093
```

## 🔄 Velero (Backup)

```bash
# Criar backup
velero backup create my-backup

# Criar backup de namespace específico
velero backup create my-backup --include-namespaces default

# Listar backups
velero backup get

# Descrever backup
velero backup describe my-backup

# Ver logs do backup
velero backup logs my-backup

# Restaurar backup
velero restore create --from-backup my-backup

# Restaurar em namespace diferente
velero restore create --from-backup my-backup \
  --namespace-mappings old-ns:new-ns

# Listar restores
velero restore get

# Deletar backup
velero backup delete my-backup

# Criar schedule
velero schedule create daily-backup --schedule="0 2 * * *"

# Listar schedules
velero schedule get
```

## 🧪 Testes

```bash
# Executar todos os testes
cd test
go test -v ./...

# Apenas testes unitários
go test -v ./unit/...

# Apenas testes de propriedade
go test -v ./property/...

# Teste específico
go test -v -run TestBackendConfigHasLockfile

# Com cobertura
go test -v -cover ./...

# Com race detector
go test -v -race ./...
```

## 🔧 Validação e Linting

```bash
# Terraform
terraform fmt -check -recursive
terraform validate
tflint --recursive
checkov -d . --framework terraform

# Kubernetes manifests
kubectl apply --dry-run=client -f manifest.yaml
kubectl apply --dry-run=server -f manifest.yaml

# Helm
helm lint ./chart
helm template ./chart --debug
```

## 📦 Helm

```bash
# Adicionar repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Buscar charts
helm search repo nginx

# Instalar chart
helm install my-release bitnami/nginx

# Listar releases
helm list -A

# Ver valores
helm get values my-release

# Upgrade
helm upgrade my-release bitnami/nginx

# Rollback
helm rollback my-release 1

# Desinstalar
helm uninstall my-release

# Ver histórico
helm history my-release
```

## 🔐 Secrets

### Kubernetes Secrets

```bash
# Criar secret
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password=senha123

# Criar secret de arquivo
kubectl create secret generic my-secret \
  --from-file=./credentials.json

# Ver secrets
kubectl get secrets
kubectl describe secret my-secret

# Ver conteúdo (base64 decoded)
kubectl get secret my-secret -o jsonpath='{.data.username}' | base64 -d
```

### AWS Secrets Manager

```bash
# Criar secret
aws secretsmanager create-secret \
  --name staging/app/database \
  --secret-string '{"username":"admin","password":"senha123"}'

# Listar secrets
aws secretsmanager list-secrets

# Ver secret
aws secretsmanager get-secret-value --secret-id staging/app/database

# Atualizar secret
aws secretsmanager update-secret \
  --secret-id staging/app/database \
  --secret-string '{"username":"admin","password":"nova-senha"}'

# Deletar secret
aws secretsmanager delete-secret \
  --secret-id staging/app/database \
  --force-delete-without-recovery
```

## 🌐 Networking

```bash
# Ver services
kubectl get svc -A

# Ver ingresses
kubectl get ingress -A

# Ver network policies
kubectl get networkpolicies -A

# Testar conectividade
kubectl run test --image=busybox --rm -it -- sh
# Dentro do pod:
nslookup kubernetes.default
wget -O- http://service-name.namespace.svc.cluster.local
```

## 📈 Monitoramento

```bash
# Ver métricas de nodes
kubectl top nodes

# Ver métricas de pods
kubectl top pods -A

# Ver uso de recursos por namespace
kubectl top pods -n <namespace>

# Ver eventos recentes
kubectl get events --sort-by='.lastTimestamp' | tail -20

# Watch events
kubectl get events -w
```

## 🔄 CI/CD

```bash
# Trigger workflow manualmente (GitHub CLI)
gh workflow run terraform-plan.yml

# Ver runs
gh run list

# Ver logs de run
gh run view <run-id> --log

# Cancelar run
gh run cancel <run-id>
```

---

## 💡 Dicas

### Aliases Úteis

Adicione ao seu `~/.bashrc` ou `~/.zshrc`:

```bash
# Terraform
alias tf='terraform'
alias tfi='terraform init'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'
alias tfv='terraform validate'
alias tff='terraform fmt -recursive'

# Kubectl
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kx='kubectl exec -it'
alias kpf='kubectl port-forward'

# Contextos
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# Pods
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods -A'
alias kdp='kubectl describe pod'
alias klp='kubectl logs -f'

# Deployments
alias kgd='kubectl get deployments'
alias kdd='kubectl describe deployment'
alias ksd='kubectl scale deployment'

# Nodes
alias kgn='kubectl get nodes'
alias kdn='kubectl describe node'
alias ktn='kubectl top nodes'
```

### Variáveis de Ambiente Úteis

```bash
# AWS
export AWS_REGION=us-east-1
export AWS_PROFILE=staging

# Kubernetes
export KUBECONFIG=~/.kube/config

# Terraform
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
```

---

**Última atualização**: 13 de Fevereiro de 2026
