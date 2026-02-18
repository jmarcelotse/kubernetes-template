# Setup - Configuração do Ambiente de Testes

Este documento explica como configurar o ambiente para executar os testes.

## Pré-requisitos

### 1. Instalar Go

Os testes requerem Go 1.21 ou superior.

**Linux/WSL:**
```bash
# Baixar e instalar Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz

# Adicionar ao PATH
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Verificar instalação
go version
```

**macOS:**
```bash
# Usando Homebrew
brew install go

# Verificar instalação
go version
```

**Windows:**
1. Baixar instalador de https://go.dev/dl/
2. Executar o instalador
3. Verificar: `go version`

### 2. Configurar GOPATH (opcional)

```bash
# Adicionar ao ~/.bashrc ou ~/.zshrc
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
```

## Instalação das Dependências

```bash
# Navegar para o diretório de testes
cd test

# Baixar dependências
go mod download

# Verificar que tudo está OK
go mod verify
```

## Verificar Instalação

```bash
# Compilar os testes (não executa)
cd test
go test -c ./unit/
go test -c ./property/

# Se compilar sem erros, está tudo OK
```

## Executar os Testes

### Primeira Execução

```bash
cd test

# Executar todos os testes
go test -v ./...
```

### Execuções Subsequentes

```bash
# Testes unitários (rápido, ~2-3 segundos)
go test -v ./unit/...

# Testes de propriedade (mais lento, ~5-10 segundos)
go test -v ./property/... -count 100

# Teste específico
go test -v -run TestBackendConfigHasLockfile ./unit/
```

## Estrutura de Comandos

### Flags Úteis

- `-v`: Verbose (mostra todos os testes)
- `-run <pattern>`: Executa apenas testes que correspondem ao padrão
- `-count N`: Executa cada teste N vezes (útil para PBT)
- `-parallel N`: Número de testes paralelos (padrão: GOMAXPROCS)
- `-timeout 30s`: Timeout para os testes
- `-cover`: Mostra cobertura de código
- `-race`: Detecta race conditions

### Exemplos

```bash
# Executar com cobertura
go test -v -cover ./...

# Executar com race detector
go test -v -race ./...

# Executar apenas testes de backend
go test -v -run Backend ./unit/

# Executar propriedades com 10 iterações (desenvolvimento)
go test -v ./property/... -count 10

# Executar com timeout de 1 minuto
go test -v -timeout 1m ./...
```

## Troubleshooting

### Erro: "go: command not found"

**Solução:** Instalar Go conforme instruções acima

### Erro: "package not found"

**Solução:**
```bash
cd test
go mod download
go mod tidy
```

### Erro: "cannot find module"

**Solução:**
```bash
cd test
go mod init github.com/example/terraform-eks-aws-template/test
go mod tidy
```

### Testes muito lentos

**Causa:** Testes de propriedade executam 100 iterações por padrão

**Solução para desenvolvimento:**
```bash
# Reduzir para 10 iterações
go test -v ./property/... -count 10
```

**Para CI/CD, manter 100 iterações:**
```bash
go test -v ./property/... -count 100
```

## Integração com IDE

### VS Code

1. Instalar extensão "Go" (golang.go)
2. Abrir pasta `test/`
3. Testes aparecerão com botões "run test" e "debug test"

### GoLand/IntelliJ

1. Abrir projeto
2. GoLand detecta automaticamente os testes
3. Clicar com botão direito em arquivo de teste > "Run"

### Vim/Neovim

```vim
" Executar teste sob cursor
:GoTest

" Executar todos os testes do arquivo
:GoTestFunc

" Executar todos os testes
:GoTestAll
```

## CI/CD

### GitHub Actions

Os testes já estão configurados para executar no GitHub Actions.

Exemplo de workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      
      - name: Download dependencies
        run: |
          cd test
          go mod download
      
      - name: Run unit tests
        run: |
          cd test
          go test -v ./unit/...
      
      - name: Run property tests
        run: |
          cd test
          go test -v ./property/... -count 100
```

## Próximos Passos

1. **Instalar Go** se ainda não tiver
2. **Executar `go mod download`** no diretório test/
3. **Executar `go test -v ./...`** para rodar todos os testes
4. **Verificar que todos passam** ✅

## Recursos Adicionais

- [Go Documentation](https://go.dev/doc/)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Gopter Documentation](https://github.com/leanovate/gopter)
- [Testify Documentation](https://github.com/stretchr/testify)

## Suporte

Se encontrar problemas:
1. Consulte `TROUBLESHOOTING.md`
2. Verifique que Go está instalado: `go version`
3. Verifique que dependências foram baixadas: `go mod verify`
4. Execute com `-v` para ver output detalhado
