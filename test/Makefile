.PHONY: help test test-unit test-property test-all install clean

help: ## Mostra esta mensagem de ajuda
	@echo "Comandos disponíveis:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: ## Instala dependências Go
	@echo "Instalando dependências..."
	go mod download
	go mod tidy

test: ## Executa todos os testes
	@echo "Executando todos os testes..."
	go test -v ./...

test-unit: ## Executa apenas testes unitários
	@echo "Executando testes unitários..."
	go test -v ./unit/...

test-property: ## Executa testes de propriedade (100 iterações)
	@echo "Executando testes de propriedade..."
	go test -v ./property/... -count 100

test-property-fast: ## Executa testes de propriedade (10 iterações - rápido)
	@echo "Executando testes de propriedade (modo rápido)..."
	go test -v ./property/... -count 10

test-coverage: ## Executa testes com cobertura
	@echo "Executando testes com cobertura..."
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html
	@echo "Relatório de cobertura gerado em coverage.html"

test-specific: ## Executa teste específico (use TEST=TestName)
	@echo "Executando teste $(TEST)..."
	go test -v -run $(TEST) ./...

test-all: install test-unit test-property ## Instala dependências e executa todos os testes

clean: ## Remove arquivos temporários
	@echo "Limpando arquivos temporários..."
	rm -f coverage.out coverage.html
	go clean -testcache

fmt: ## Formata código Go
	@echo "Formatando código..."
	go fmt ./...

lint: ## Executa linter Go
	@echo "Executando linter..."
	golangci-lint run ./...

ci: install test-unit test-property ## Executa pipeline de CI completo
	@echo "Pipeline de CI concluído com sucesso!"
