# Troubleshooting - Testes

Este documento lista problemas comuns ao executar os testes e suas soluções.

## Problemas Comuns

### 1. Erro: "package not found"

**Sintoma:**
```
package github.com/example/terraform-eks-aws-template/test/helpers: cannot find package
```

**Solução:**
```bash
cd test
go mod download
go mod tidy
```

### 2. Erro: "file not found" nos testes

**Sintoma:**
```
Test failed: backend.tf deve existir em staging
```

**Causa:** Os testes assumem que você está executando do diretório `test/`

**Solução:**
```bash
# Sempre execute os testes do diretório test/
cd test
go test -v ./...
```

### 3. Testes de propriedade muito lentos

**Sintoma:** Testes de propriedade demoram muito tempo

**Causa:** Por padrão, testes de propriedade executam 100 iterações

**Solução:**
```bash
# Reduzir iterações para desenvolvimento (não recomendado para CI)
cd test
go test -v ./property/... -count 10

# Para CI, manter 100 iterações
go test -v ./property/... -count 100
```

### 4. Erro: "regex pattern invalid"

**Sintoma:**
```
error parsing regexp: invalid escape sequence
```

**Causa:** Caracteres especiais não escapados em regex

**Solução:** Verifique que caracteres especiais estão escapados:
```go
// Errado
pattern := "variable "name" {"

// Correto
pattern := `variable\s+"name"\s+\{`
```

### 5. Falha em TestPropertyIRSACorrect

**Sintoma:** Teste de IRSA falha para algum módulo

**Causa:** Módulo não implementa IRSA ou usa estrutura diferente

**Solução:** Verifique que o módulo tem:
- `aws_iam_role` resource
- Referência a `oidc_provider`
- Condition `StringEquals`
- Referência a `serviceaccount`

### 6. Falha em testes de environment

**Sintoma:** Testes de diferenças entre staging e prod falham

**Causa:** Valores nos arquivos de exemplo não correspondem ao esperado

**Solução:** Verifique os arquivos:
- `live/aws/staging/terraform.tfvars.example`
- `live/aws/prod/terraform.tfvars.example`

Valores esperados:
- Staging: `single_nat_gateway = true`, `max_size = 10`
- Prod: `single_nat_gateway = false`, `max_size = 50`

### 7. Erro: "too many open files"

**Sintoma:**
```
too many open files
```

**Causa:** Muitos testes executando em paralelo

**Solução:**
```bash
# Aumentar limite de arquivos abertos (Linux/Mac)
ulimit -n 4096

# Ou executar testes sequencialmente
go test -v -p 1 ./...
```

### 8. Testes passam localmente mas falham no CI

**Sintoma:** Testes passam na máquina local mas falham no GitHub Actions

**Causa:** Diferenças de ambiente ou paths

**Solução:**
- Verifique que paths são relativos, não absolutos
- Use `helpers.GetProjectRoot()` para paths dinâmicos
- Verifique que arquivos estão commitados no git

### 9. Erro: "module not found"

**Sintoma:**
```
module github.com/example/terraform-eks-aws-template/test: cannot find module
```

**Solução:**
```bash
cd test
go mod init github.com/example/terraform-eks-aws-template/test
go mod tidy
```

### 10. Falha em TestPropertyMandatoryTags

**Sintoma:** Teste de tags obrigatórias falha

**Causa:** Tags não configuradas em `default_tags` do provider AWS

**Solução:** Verifique que `live/aws/staging/main.tf` e `live/aws/prod/main.tf` têm:
```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"  # ou "prod"
      ManagedBy   = "Terraform"
      Project     = "eks-template"
      Owner       = "platform-team"
      Purpose     = "kubernetes-cluster"
    }
  }
}
```

## Debugging

### Executar teste específico com verbose

```bash
cd test
go test -v -run TestBackendConfigHasLockfile ./unit/
```

### Ver output completo de propriedades

```bash
cd test
go test -v ./property/vpc_test.go -count 1
```

### Verificar que arquivos existem

```bash
# Verificar estrutura do projeto
ls -la ../modules/clusters/eks/
ls -la ../live/aws/staging/
ls -la ../live/aws/prod/
```

### Executar com race detector

```bash
cd test
go test -race -v ./...
```

## Boas Práticas

1. **Sempre execute do diretório test/**
   ```bash
   cd test && go test -v ./...
   ```

2. **Use t.Parallel() em todos os testes**
   ```go
   func TestExample(t *testing.T) {
       t.Parallel()
       // ...
   }
   ```

3. **Use helpers para paths**
   ```go
   // Bom
   file := helpers.GetModulePath("clusters/eks") + "/main.tf"
   
   // Ruim
   file := "../modules/clusters/eks/main.tf"
   ```

4. **Sempre verifique erros**
   ```go
   hasValue, err := helpers.ContainsString(file, "value")
   require.NoError(t, err)
   assert.True(t, hasValue)
   ```

5. **Use require para pré-condições, assert para validações**
   ```go
   require.True(t, helpers.FileExists(file), "Arquivo deve existir")
   assert.True(t, hasValue, "Deve conter valor")
   ```

## Suporte

Se você encontrar um problema não listado aqui:

1. Verifique os logs completos do teste
2. Execute com `-v` para verbose
3. Verifique que a estrutura do projeto está correta
4. Consulte a documentação do Terratest e Gopter
