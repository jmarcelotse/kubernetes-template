# Policy Engine Module

Este módulo instala e configura um policy engine (Kyverno ou Gatekeeper) no cluster Kubernetes para enforcement de políticas de segurança.

## Funcionalidades

- Suporte para Kyverno ou Gatekeeper (selecionável via variável)
- Modo de enforcement configurável (audit ou enforce)
- Políticas de segurança pré-configuradas:
  - Bloquear containers privilegiados
  - Exigir runAsNonRoot
  - Exigir resource requests e limits
  - Bloquear image tag `:latest`
  - Restringir Linux capabilities
- Execução em node group system com tolerations

## Uso

```hcl
module "policy_engine" {
  source = "../../modules/platform/policy-engine"

  engine            = "kyverno"  # ou "gatekeeper"
  enforcement_mode  = "audit"    # ou "enforce"
  
  policies = {
    block_privileged      = true
    require_non_root      = true
    require_resources     = true
    block_latest_tag      = true
    require_labels        = false
    restrict_capabilities = true
  }
}
```

## Diferenças entre Ambientes

### Staging
- `enforcement_mode = "audit"` - Políticas apenas auditam violações

### Production
- `enforcement_mode = "enforce"` - Políticas bloqueiam violações

## Políticas Implementadas

### 1. Disallow Privileged Containers
Bloqueia containers que executam em modo privilegiado.

**Severidade:** Alta

### 2. Require runAsNonRoot
Exige que containers executem como usuário não-root.

**Severidade:** Média

### 3. Require Resources
Exige que todos os containers tenham CPU e memory requests/limits definidos.

**Severidade:** Média

### 4. Disallow Latest Tag
Bloqueia uso da tag `:latest` em imagens de containers.

**Severidade:** Média

### 5. Restrict Capabilities
Exige que containers dropm ALL capabilities e apenas adicionem NET_BIND_SERVICE se necessário.

**Severidade:** Média

## Verificação

### Kyverno

```bash
# Verificar instalação
kubectl get pods -n policy-system

# Listar políticas
kubectl get clusterpolicy

# Ver relatórios de violações
kubectl get policyreport -A
```

### Gatekeeper

```bash
# Verificar instalação
kubectl get pods -n policy-system

# Listar constraint templates
kubectl get constrainttemplates

# Listar constraints
kubectl get constraints

# Ver violações
kubectl get constraints -o yaml
```

## Troubleshooting

### Políticas não estão sendo aplicadas

1. Verificar se o policy engine está rodando:
```bash
kubectl get pods -n policy-system
```

2. Verificar logs:
```bash
# Kyverno
kubectl logs -n policy-system -l app.kubernetes.io/name=kyverno

# Gatekeeper
kubectl logs -n policy-system -l app=gatekeeper
```

### Workloads legítimos sendo bloqueados

Se workloads legítimos estão sendo bloqueados em modo enforce:

1. Temporariamente mudar para modo audit
2. Revisar relatórios de violações
3. Ajustar workloads para compliance
4. Retornar para modo enforce

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| engine | Policy engine (kyverno ou gatekeeper) | string | "kyverno" | no |
| enforcement_mode | Modo de enforcement (audit ou enforce) | string | "audit" | no |
| policies | Políticas a habilitar | object | ver variables.tf | no |
| namespace | Namespace para policy engine | string | "policy-system" | no |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Namespace onde policy engine foi instalado |
| engine | Policy engine instalado |
| enforcement_mode | Modo de enforcement configurado |
| enabled_policies | Políticas habilitadas |
