package helpers

import (
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/hashicorp/hcl/v2/hclparse"
)

// TerraformConfig representa uma configuração Terraform parseada
type TerraformConfig struct {
	Blocks []*Block
}

// Block representa um bloco HCL
type Block struct {
	Type   string
	Labels []string
	Body   map[string]interface{}
}

// ParseTerraformFile faz parse de um arquivo Terraform
func ParseTerraformFile(path string) (*TerraformConfig, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler arquivo %s: %w", path, err)
	}

	parser := hclparse.NewParser()
	_, diags := parser.ParseHCL(content, path)
	if diags.HasErrors() {
		return nil, fmt.Errorf("erro ao parsear HCL: %s", diags.Error())
	}

	config := &TerraformConfig{
		Blocks: make([]*Block, 0),
	}

	// Parse básico - para testes, usamos regex simples
	// Em produção, usaria hcl.DecodeBody completo
	return config, nil
}

// ContainsString verifica se um arquivo contém uma string
func ContainsString(filePath, searchString string) (bool, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}
	return strings.Contains(string(content), searchString), nil
}

// ContainsRegex verifica se um arquivo contém um padrão regex
func ContainsRegex(filePath, pattern string) (bool, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}
	matched, err := regexp.Match(pattern, content)
	return matched, err
}

// FileExists verifica se um arquivo existe
func FileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

// DirectoryExists verifica se um diretório existe
func DirectoryExists(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.IsDir()
}

// CountOccurrences conta quantas vezes uma string aparece em um arquivo
func CountOccurrences(filePath, searchString string) (int, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return 0, err
	}
	return strings.Count(string(content), searchString), nil
}

// GetProjectRoot retorna o diretório raiz do projeto
func GetProjectRoot() string {
	// Encontra o diretório raiz procurando por go.mod ou .git
	dir, _ := os.Getwd()
	
	// Se estamos em test/unit ou test/property, sobe dois níveis
	if filepath.Base(dir) == "unit" || filepath.Base(dir) == "property" {
		return filepath.Join(dir, "..", "..")
	}
	
	// Se estamos em test/, sobe um nível
	if filepath.Base(dir) == "test" {
		return filepath.Join(dir, "..")
	}
	
	// Caso contrário, assume que já estamos na raiz
	return dir
}

// GetModulePath retorna o caminho para um módulo
func GetModulePath(moduleName string) string {
	return filepath.Join(GetProjectRoot(), "modules", moduleName)
}

// GetEnvironmentPath retorna o caminho para um ambiente
func GetEnvironmentPath(env string) string {
	return filepath.Join(GetProjectRoot(), "live", "aws", env)
}

// ExtractVariableValidation extrai validações de variáveis de um arquivo
func ExtractVariableValidation(filePath, varName string) (bool, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	// Procura por variable "varName" { ... validation { ... } }
	pattern := fmt.Sprintf(`variable\s+"%s"\s+\{[^}]*validation\s+\{`, varName)
	matched, err := regexp.Match(pattern, content)
	return matched, err
}

// ExtractResourceCount conta recursos de um tipo específico
func ExtractResourceCount(filePath, resourceType string) (int, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return 0, err
	}

	// Conta ocorrências de resource "type" "name"
	pattern := fmt.Sprintf(`resource\s+"%s"\s+"[^"]+"\s+\{`, resourceType)
	re := regexp.MustCompile(pattern)
	matches := re.FindAllString(string(content), -1)
	return len(matches), nil
}

// ExtractOutputs extrai nomes de outputs de um arquivo
func ExtractOutputs(filePath string) ([]string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	// Extrai output "name" { ... }
	pattern := `output\s+"([^"]+)"\s+\{`
	re := regexp.MustCompile(pattern)
	matches := re.FindAllStringSubmatch(string(content), -1)

	outputs := make([]string, 0, len(matches))
	for _, match := range matches {
		if len(match) > 1 {
			outputs = append(outputs, match[1])
		}
	}
	return outputs, nil
}

// HasDescription verifica se uma variável ou output tem description
func HasDescription(filePath, blockType, name string) (bool, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return false, err
	}

	// Procura por variable/output "name" { ... description = "..." ... }
	pattern := fmt.Sprintf(`%s\s+"%s"\s+\{[^}]*description\s+=\s+"[^"]+"`, blockType, name)
	matched, err := regexp.Match(pattern, content)
	return matched, err
}

// ReadFileContent lê o conteúdo de um arquivo e retorna como string
func ReadFileContent(filePath string) (string, error) {
	content, err := os.ReadFile(filePath)
	if err != nil {
		return "", err
	}
	return string(content), nil
}
