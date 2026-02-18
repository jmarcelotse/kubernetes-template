#!/bin/bash

# Script para executar testes do template Terraform EKS AWS
# Uso: ./run_tests.sh [unit|property|all]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir mensagens coloridas
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verifica se Go está instalado
if ! command -v go &> /dev/null; then
    print_error "Go não está instalado. Por favor, instale Go 1.21 ou superior."
    exit 1
fi

# Verifica versão do Go
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
print_info "Versão do Go: $GO_VERSION"

# Instala dependências
print_info "Instalando dependências..."
go mod download
go mod tidy

# Determina qual tipo de teste executar
TEST_TYPE=${1:-all}

case $TEST_TYPE in
    unit)
        print_info "Executando testes unitários..."
        go test -v ./unit/...
        ;;
    property)
        print_info "Executando testes de propriedade (100 iterações)..."
        go test -v ./property/... -count 100
        ;;
    property-fast)
        print_info "Executando testes de propriedade (10 iterações - modo rápido)..."
        go test -v ./property/... -count 10
        ;;
    all)
        print_info "Executando todos os testes..."
        print_info "1/2 - Testes unitários..."
        go test -v ./unit/...
        print_info "2/2 - Testes de propriedade..."
        go test -v ./property/... -count 100
        ;;
    coverage)
        print_info "Executando testes com cobertura..."
        go test -v -coverprofile=coverage.out ./...
        go tool cover -html=coverage.out -o coverage.html
        print_info "Relatório de cobertura gerado em coverage.html"
        ;;
    *)
        print_error "Tipo de teste inválido: $TEST_TYPE"
        echo "Uso: $0 [unit|property|property-fast|all|coverage]"
        exit 1
        ;;
esac

print_info "Testes concluídos com sucesso!"
