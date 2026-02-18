package unit

import (
	"path/filepath"
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
)

// TestREADMEExists valida que README.md existe
// Valida: Requisitos 15.1
func TestREADMEExists(t *testing.T) {
	t.Parallel()

	readmeFile := filepath.Join(helpers.GetProjectRoot(), "README.md")
	assert.True(t, helpers.FileExists(readmeFile), "README.md deve existir na raiz do projeto")
}

// TestTerraformVarsExamplesExist valida que exemplos de terraform.tfvars existem
// Valida: Requisitos 15.2
func TestTerraformVarsExamplesExist(t *testing.T) {
	t.Parallel()

	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			exampleFile := helpers.GetEnvironmentPath(env) + "/terraform.tfvars.example"
			assert.True(t, helpers.FileExists(exampleFile), "terraform.tfvars.example deve existir em %s", env)
		})
	}
}

// TestTroubleshootingExists valida que troubleshooting.md existe
// Valida: Requisitos 15.5
func TestTroubleshootingExists(t *testing.T) {
	t.Parallel()

	troubleshootingFile := filepath.Join(helpers.GetProjectRoot(), "docs/troubleshooting.md")
	assert.True(t, helpers.FileExists(troubleshootingFile), "docs/troubleshooting.md deve existir")
}

// TestCostOptimizationExists valida que cost-optimization.md existe
// Valida: Requisitos 17.2
func TestCostOptimizationExists(t *testing.T) {
	t.Parallel()

	costFile := filepath.Join(helpers.GetProjectRoot(), "docs/cost-optimization.md")
	assert.True(t, helpers.FileExists(costFile), "docs/cost-optimization.md deve existir")
}

// TestTerraformDocsConfigExists valida que .terraform-docs.yml existe
// Valida: Requisitos 16.1
func TestTerraformDocsConfigExists(t *testing.T) {
	t.Parallel()

	configFile := filepath.Join(helpers.GetProjectRoot(), ".terraform-docs.yml")
	assert.True(t, helpers.FileExists(configFile), ".terraform-docs.yml deve existir")
}

// TestTFLintConfigExists valida que .tflint.hcl existe
// Valida: Requisitos 16.2
func TestTFLintConfigExists(t *testing.T) {
	t.Parallel()

	configFile := filepath.Join(helpers.GetProjectRoot(), ".tflint.hcl")
	assert.True(t, helpers.FileExists(configFile), ".tflint.hcl deve existir")
}

// TestTestDirectoryExists valida que diretório test/ existe com arquivos Go
// Valida: Requisitos 16.5
func TestTestDirectoryExists(t *testing.T) {
	t.Parallel()

	testDir := filepath.Join(helpers.GetProjectRoot(), "test")
	assert.True(t, helpers.DirectoryExists(testDir), "Diretório test/ deve existir")

	goModFile := filepath.Join(testDir, "go.mod")
	assert.True(t, helpers.FileExists(goModFile), "test/go.mod deve existir")
}
