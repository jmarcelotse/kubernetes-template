package unit

import (
	"path/filepath"
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestWorkflowContainsTerraformFmt valida que workflow contém terraform fmt
// Valida: Requisitos 14.1
func TestWorkflowContainsTerraformFmt(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-plan.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-plan.yml deve existir")

	hasFmt, err := helpers.ContainsString(workflowFile, "terraform fmt")
	require.NoError(t, err)
	assert.True(t, hasFmt, "Workflow deve conter terraform fmt")

	hasFmtCheck, err := helpers.ContainsString(workflowFile, "fmt -check")
	require.NoError(t, err)
	assert.True(t, hasFmtCheck, "Workflow deve usar fmt -check")
}

// TestWorkflowContainsTerraformValidate valida que workflow contém terraform validate
// Valida: Requisitos 14.2
func TestWorkflowContainsTerraformValidate(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-plan.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-plan.yml deve existir")

	hasValidate, err := helpers.ContainsString(workflowFile, "terraform validate")
	require.NoError(t, err)
	assert.True(t, hasValidate, "Workflow deve conter terraform validate")
}

// TestWorkflowContainsTerraformPlan valida que workflow contém terraform plan
// Valida: Requisitos 14.3
func TestWorkflowContainsTerraformPlan(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-plan.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-plan.yml deve existir")

	hasPlan, err := helpers.ContainsString(workflowFile, "terraform plan")
	require.NoError(t, err)
	assert.True(t, hasPlan, "Workflow deve conter terraform plan")
}

// TestWorkflowUsesOIDC valida que workflow usa OIDC para AWS
// Valida: Requisitos 14.6
func TestWorkflowUsesOIDC(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-plan.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-plan.yml deve existir")

	hasOIDC, err := helpers.ContainsString(workflowFile, "aws-actions/configure-aws-credentials")
	require.NoError(t, err)
	assert.True(t, hasOIDC, "Workflow deve usar aws-actions/configure-aws-credentials")

	hasRoleToAssume, err := helpers.ContainsString(workflowFile, "role-to-assume")
	require.NoError(t, err)
	assert.True(t, hasRoleToAssume, "Workflow deve usar role-to-assume para OIDC")
}

// TestWorkflowPostsComment valida que workflow posta comentário no PR
// Valida: Requisitos 14.7
func TestWorkflowPostsComment(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-plan.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-plan.yml deve existir")

	// Verifica se há step para postar comentário
	hasComment, err := helpers.ContainsRegex(workflowFile, `(comment|PR|pull.*request)`)
	require.NoError(t, err)
	assert.True(t, hasComment, "Workflow deve ter step para postar comentário no PR")
}

// TestApplyStagingIsAutomatic valida que apply staging é automático
// Valida: Requisitos 14.4
func TestApplyStagingIsAutomatic(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-apply-staging.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-apply-staging.yml deve existir")

	// Verifica trigger em push para main
	hasPushTrigger, err := helpers.ContainsRegex(workflowFile, `on:\s*\n\s*push:`)
	require.NoError(t, err)
	assert.True(t, hasPushTrigger, "Apply staging deve ter trigger em push")

	hasMainBranch, err := helpers.ContainsString(workflowFile, "main")
	require.NoError(t, err)
	assert.True(t, hasMainBranch, "Apply staging deve executar em push para main")

	// Não deve ter environment protection (que requer aprovação)
	hasEnvironment, err := helpers.ContainsString(workflowFile, "environment:")
	require.NoError(t, err)
	assert.False(t, hasEnvironment, "Apply staging não deve ter environment protection (deve ser automático)")
}

// TestApplyProdRequiresApproval valida que apply prod requer aprovação
// Valida: Requisitos 14.5
func TestApplyProdRequiresApproval(t *testing.T) {
	t.Parallel()

	workflowFile := filepath.Join(helpers.GetProjectRoot(), ".github/workflows/terraform-apply-prod.yml")
	require.True(t, helpers.FileExists(workflowFile), "terraform-apply-prod.yml deve existir")

	// Verifica que usa environment protection
	hasEnvironment, err := helpers.ContainsString(workflowFile, "environment:")
	require.NoError(t, err)
	assert.True(t, hasEnvironment, "Apply prod deve ter environment protection")

	hasProduction, err := helpers.ContainsString(workflowFile, "name: production")
	require.NoError(t, err)
	assert.True(t, hasProduction, "Apply prod deve usar environment: production")
}
