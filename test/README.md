# Terraform Tests

Este diretório contém testes automatizados para o template Terraform EKS AWS.

## Estrutura

```
test/
├── go.mod                       # Dependências Go
├── README.md                    # Este arquivo
├── helpers/                     # Funções auxiliares
│   ├── terraform.go            # Helpers para parsing Terraform
│   └── generators.go           # Geradores para property-based testing
├── unit/                        # Testes unitários
│   ├── backend_test.go         # Testes de configuração de backend
│   ├── node_groups_test.go     # Testes de node groups
│   ├── environment_test.go     # Testes de diferenças entre ambientes
│   ├── platform_test.go        # Testes de módulos de plataforma
│   ├── compliance_test.go      # Testes de compliance
│   ├── workflows_test.go       # Testes de GitHub Actions
│   ├── documentation_test.go   # Testes de documentação
│   └── eks_test.go             # Testes de EKS/OIDC
└── property/                    # Testes baseados em propriedades
    ├── vpc_test.go             # Propriedades 2-5: VPC e networking
    ├── eks_test.go             # Propriedades 6-8: Cluster EKS
    ├── node_groups_test.go     # Propriedades 1, 9-10: Node groups e isolamento
    ├── platform_test.go        # Propriedades 11-14: Plataforma
    └── documentation_test.go   # Propriedades 15-17: Documentação e compliance
```

## Executando Testes

### Todos os testes

```bash
cd test
go test -v ./...
```

### Testes unitários

```bash
cd test
go test -v ./unit/...
```

### Testes de propriedade

```bash
cd test
go test -v ./property/... -count 100
```

### Teste específico

```bash
cd test
go test -v -run TestBackendConfigHasLockfile
```

## Testes Implementados

### Testes Unitários (30+ testes)

1. **Backend** (3 testes)
   - Validação de use_lockfile = true
   - Validação de encrypt = true
   - Validação de ausência de dynamodb_table

2. **Node Groups** (3 testes)
   - System node group com taint CriticalAddonsOnly
   - Apps node group sem taints
   - Campos obrigatórios dos node groups

3. **Ambientes** (5 testes)
   - Instance types diferentes por ambiente
   - Autoscaling diferente por ambiente
   - Single NAT gateway em staging
   - Multi-AZ NAT em prod
   - Exemplos de terraform.tfvars existem

4. **Plataforma** (12 testes)
   - ArgoCD: helm_release, namespace, tolerations, outputs
   - Policy Engine: validation, enforcement modes
   - External Secrets: componentes e exemplos
   - Observability: componentes e outputs
   - Ingress: validation e componentes
   - Velero: bucket S3 e outputs

5. **Compliance** (3 testes)
   - CloudTrail criado
   - AWS Config criado
   - GuardDuty criado

6. **Workflows** (7 testes)
   - Terraform fmt
   - Terraform validate
   - Terraform plan
   - OIDC para AWS
   - Comentário no PR
   - Apply staging automático
   - Apply prod com aprovação

7. **Documentação** (7 testes)
   - README.md existe
   - Exemplos de tfvars
   - Troubleshooting.md existe
   - Cost-optimization.md existe
   - .terraform-docs.yml existe
   - .tflint.hcl existe
   - Diretório test/ existe

8. **EKS** (1 teste)
   - OIDC provider criado

### Testes de Propriedade (17 propriedades)

1. **Propriedade 1**: Isolamento de Ambientes
2. **Propriedade 2**: Subnets Multi-AZ
3. **Propriedade 3**: NAT Gateway por AZ
4. **Propriedade 4**: VPC Endpoints Completos
5. **Propriedade 5**: Tags Kubernetes em Subnets
6. **Propriedade 6**: Logs do Control Plane Completos
7. **Propriedade 7**: Criptografia de Secrets com KMS
8. **Propriedade 8**: Versão Kubernetes Válida
9. **Propriedade 9**: Node Groups Completos
10. **Propriedade 10**: Autoscaling Conservador para System Nodes
11. **Propriedade 11**: Políticas de Segurança Habilitadas
12. **Propriedade 12**: IRSA com Permissões Corretas
13. **Propriedade 13**: Retenção por Ambiente
14. **Propriedade 14**: Backup Schedule por Ambiente
15. **Propriedade 15**: Documentação de Variáveis e Outputs
16. **Propriedade 16**: Tags Obrigatórias
17. **Propriedade 17**: Bucket Policies de Proteção

## Dependências

- **Terratest**: Framework para testes de infraestrutura
- **Testify**: Assertions e mocks
- **Gopter**: Property-based testing
- **HCL**: Parsing de arquivos Terraform

## Instalando Dependências

```bash
cd test
go mod download
```

## Escrevendo Testes

### Teste Unitário

```go
package unit

import (
    "testing"
    "github.com/example/terraform-eks-aws-template/test/helpers"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
    t.Parallel()
    
    // Arrange
    file := helpers.GetModulePath("clusters/eks") + "/main.tf"
    require.True(t, helpers.FileExists(file))
    
    // Act
    hasResource, err := helpers.ContainsString(file, "resource")
    
    // Assert
    require.NoError(t, err)
    assert.True(t, hasResource)
}
```

### Teste de Propriedade

```go
package property

import (
    "testing"
    "github.com/leanovate/gopter"
    "github.com/leanovate/gopter/prop"
)

func TestPropertyExample(t *testing.T) {
    t.Parallel()
    
    // Feature: terraform-eks-aws-template, Property X: Description
    properties := gopter.NewProperties(nil)
    
    properties.Property("description", prop.ForAll(
        func(input string) bool {
            // Test property
            return true
        },
        gen.AnyString(),
    ))
    
    properties.TestingRun(t, gopter.ConsoleReporter(false))
}
```

## CI/CD

Os testes são executados automaticamente no GitHub Actions em cada pull request.

## Notas

- Testes de propriedade devem executar no mínimo 100 iterações
- Testes que criam recursos AWS reais devem ser marcados com `// +build integration`
- Use mocks sempre que possível para testes unitários
- Todos os testes são executados em paralelo com `t.Parallel()`

## Cobertura

- **Testes Unitários**: 30+ testes cobrindo exemplos específicos e casos extremos
- **Testes de Propriedade**: 17 propriedades validando corretude universal
- **Total**: ~50 testes automatizados validando todos os requisitos da spec
