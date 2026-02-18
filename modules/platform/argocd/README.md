# Módulo ArgoCD

Este módulo instala o ArgoCD no cluster EKS via Helm, habilitando GitOps como metodologia de deployment para o restante da plataforma Kubernetes.

## Descrição

O ArgoCD é uma ferramenta de continuous delivery declarativa para Kubernetes que segue o paradigma GitOps. Este módulo:

- Cria um namespace dedicado para o ArgoCD
- Instala o ArgoCD via Helm chart oficial
- Configura tolerations para executar no node group "system"
- Suporta modo de alta disponibilidade (HA) opcional
- Expõe outputs com informações de acesso e credenciais

## Uso

### Exemplo Básico

```hcl
module "argocd" {
  source = "../../modules/platform/argocd"

  cluster_name = "my-eks-cluster"
  namespace    = "argocd"
  
  # Configurar para executar no node group system
  node_selector = {
    role = "system"
  }
  
  tolerations = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}
```

### Exemplo com Alta Disponibilidade

```hcl
module "argocd" {
  source = "../../modules/platform/argocd"

  cluster_name = "my-eks-cluster"
  namespace    = "argocd"
  
  # Habilitar HA
  enable_ha = true
  replicas = {
    server                = 3
    repo_server           = 3
    application_controller = 1
  }
  
  node_selector = {
    role = "system"
  }
  
  tolerations = [{
    key      = "CriticalAddonsOnly"
    operator = "Equal"
    value    = "true"
    effect   = "NoSchedule"
  }]
}
```

### Exemplo com Valores Customizados

```hcl
module "argocd" {
  source = "../../modules/platform/argocd"

  cluster_name = "my-eks-cluster"
  namespace    = "argocd"
  
  # Valores customizados adicionais
  values = {
    server = {
      ingress = {
        enabled = true
        ingressClassName = "nginx"
        hosts = ["argocd.example.com"]
        tls = [{
          secretName = "argocd-tls"
          hosts      = ["argocd.example.com"]
        }]
      }
    }
    
    configs = {
      cm = {
        "admin.enabled" = "true"
        "timeout.reconciliation" = "180s"
      }
    }
  }
}
```

## Requisitos

| Nome | Versão |
|------|--------|
| terraform | >= 1.5.0 |
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Providers

| Nome | Versão |
|------|--------|
| kubernetes | ~> 2.23 |
| helm | ~> 2.11 |

## Recursos Criados

- `kubernetes_namespace.argocd` - Namespace dedicado para o ArgoCD
- `helm_release.argocd` - Instalação do ArgoCD via Helm

## Inputs

| Nome | Descrição | Tipo | Padrão | Obrigatório |
|------|-----------|------|--------|:-----------:|
| cluster_name | Nome do cluster EKS | `string` | n/a | sim |
| namespace | Namespace para instalar ArgoCD | `string` | `"argocd"` | não |
| chart_version | Versão do Helm chart do ArgoCD | `string` | `"5.51.0"` | não |
| chart_repository | URL do repositório Helm | `string` | `"https://argoproj.github.io/argo-helm"` | não |
| node_selector | Node selector para pods do ArgoCD | `map(string)` | `{ "role" = "system" }` | não |
| tolerations | Tolerations para pods do ArgoCD | `list(object)` | Ver variables.tf | não |
| values | Valores customizados para o Helm chart | `any` | `{}` | não |
| enable_ha | Habilitar modo de alta disponibilidade | `bool` | `false` | não |
| replicas | Número de réplicas quando HA está habilitado | `object` | Ver variables.tf | não |
| resources | Requisitos de recursos para componentes | `object` | Ver variables.tf | não |
| tags | Tags para aplicar aos recursos | `map(string)` | `{}` | não |

## Outputs

| Nome | Descrição |
|------|-----------|
| namespace | Namespace onde ArgoCD foi instalado |
| server_service_name | Nome do service do ArgoCD server |
| initial_admin_password_secret | Nome do secret com senha inicial do admin |
| admin_username | Nome de usuário padrão do admin |
| access_instructions | Instruções para acessar o ArgoCD |
| components | Informações sobre componentes instalados |
| chart_version | Versão do chart instalada |
| high_availability_enabled | Indica se HA está habilitado |

## Acessando o ArgoCD

Após a instalação, você pode acessar o ArgoCD de várias formas:

### 1. Port Forward (Desenvolvimento)

```bash
# Obter a senha inicial
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Acessar em https://localhost:8080
# Username: admin
# Password: (obtida acima)
```

### 2. Via Ingress (Produção)

Configure um ingress usando a variável `values`:

```hcl
values = {
  server = {
    ingress = {
      enabled = true
      ingressClassName = "nginx"
      hosts = ["argocd.example.com"]
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod"
      }
      tls = [{
        secretName = "argocd-tls"
        hosts      = ["argocd.example.com"]
      }]
    }
  }
}
```

### 3. Via CLI

```bash
# Instalar ArgoCD CLI
brew install argocd  # macOS
# ou
curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# Login
argocd login localhost:8080 --username admin --password <senha>

# Alterar senha
argocd account update-password
```

## Próximos Passos

Após instalar o ArgoCD, você pode:

1. **Alterar a senha do admin** (recomendado):
   ```bash
   argocd account update-password
   ```

2. **Configurar repositórios Git**:
   ```bash
   argocd repo add https://github.com/your-org/your-repo.git --username <user> --password <token>
   ```

3. **Criar aplicações**:
   ```bash
   argocd app create my-app \
     --repo https://github.com/your-org/your-repo.git \
     --path manifests \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace default
   ```

4. **Configurar SSO** (opcional):
   - Habilitar Dex via valores customizados
   - Configurar provedores OAuth (GitHub, Google, etc.)

5. **Configurar notificações** (opcional):
   - Slack, Microsoft Teams, email, etc.
   - Via ArgoCD Notifications Controller (já habilitado)

## Segurança

### Recomendações

1. **Altere a senha padrão** imediatamente após a instalação
2. **Delete o secret** `argocd-initial-admin-secret` após obter a senha
3. **Configure RBAC** para controlar acesso de usuários
4. **Habilite SSO** para ambientes produtivos
5. **Use TLS** para acesso externo (via ingress com cert-manager)
6. **Restrinja acesso** ao namespace argocd via NetworkPolicies

### RBAC

O ArgoCD possui sistema de RBAC integrado. Exemplo de configuração:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:org-admin, applications, *, */*, allow
    p, role:org-admin, clusters, get, *, allow
    p, role:org-admin, repositories, get, *, allow
    g, your-github-org:team-name, role:org-admin
```

## Troubleshooting

### Pods não iniciam

Verifique se os nodes têm as tolerations corretas:

```bash
kubectl get nodes -o json | jq '.items[].spec.taints'
```

### Senha inicial não funciona

O secret pode ter sido deletado. Recrie a senha:

```bash
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -bnBC 10 "" <new-password> | tr -d ':\n')'"}}'
```

### Aplicações não sincronizam

Verifique os logs do application controller:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Problemas de conectividade com repositórios

Verifique se o cluster tem acesso à internet (via NAT Gateway) e se as credenciais estão corretas:

```bash
argocd repo list
```

## Referências

- [Documentação oficial do ArgoCD](https://argo-cd.readthedocs.io/)
- [Helm chart do ArgoCD](https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd)
- [Best Practices do ArgoCD](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)

## Licença

Este módulo é parte do template terraform-eks-aws-template e segue a mesma licença do projeto principal.
