package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestSystemNodeGroupHasTaint valida que node group "system" tem taint CriticalAddonsOnly
// Valida: Requisitos 6.1
func TestSystemNodeGroupHasTaint(t *testing.T) {
	t.Parallel()

	// Verifica que node_groups.tf tem suporte a taints
	nodeGroupsFile := helpers.GetModulePath("clusters/eks") + "/node_groups.tf"
	require.True(t, helpers.FileExists(nodeGroupsFile), "node_groups.tf deve existir")

	hasDynamicTaint, err := helpers.ContainsString(nodeGroupsFile, `dynamic "taint"`)
	require.NoError(t, err)
	assert.True(t, hasDynamicTaint, "node_groups.tf deve ter dynamic taint block")

	// Verifica que staging define o taint CriticalAddonsOnly
	stagingVarsFile := helpers.GetEnvironmentPath("staging") + "/variables.tf"
	require.True(t, helpers.FileExists(stagingVarsFile), "staging/variables.tf deve existir")

	hasTaint, err := helpers.ContainsString(stagingVarsFile, "CriticalAddonsOnly")
	require.NoError(t, err)
	assert.True(t, hasTaint, "staging deve definir taint CriticalAddonsOnly")

	// Verifica padrão completo do taint
	hasTaintKey, err := helpers.ContainsRegex(stagingVarsFile, `key\s*=\s*"CriticalAddonsOnly"`)
	require.NoError(t, err)
	assert.True(t, hasTaintKey, "Taint deve ter key = CriticalAddonsOnly")

	hasValue, err := helpers.ContainsRegex(stagingVarsFile, `value\s*=\s*"true"`)
	require.NoError(t, err)
	assert.True(t, hasValue, "Taint deve ter value = true")

	hasEffect, err := helpers.ContainsRegex(stagingVarsFile, `effect\s*=\s*"NoSchedule"`)
	require.NoError(t, err)
	assert.True(t, hasEffect, "Taint deve ter effect = NoSchedule")
}

// TestAppsNodeGroupNoTaints valida que node group "apps" não tem taints
// Valida: Requisitos 6.2
func TestAppsNodeGroupNoTaints(t *testing.T) {
	t.Parallel()

	// Verifica nos arquivos de exemplo que apps não tem taints
	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			exampleFile := helpers.GetEnvironmentPath(env) + "/terraform.tfvars.example"
			require.True(t, helpers.FileExists(exampleFile), "terraform.tfvars.example deve existir em %s", env)

			// Verifica que apps tem taints = []
			hasEmptyTaints, err := helpers.ContainsString(exampleFile, "taints = []")
			require.NoError(t, err)
			assert.True(t, hasEmptyTaints, "Node group apps deve ter taints = [] em %s", env)
		})
	}
}

// TestNodeGroupsHaveRequiredFields valida que node groups têm campos obrigatórios
// Valida: Requisitos 6.3, 6.4, 6.5, 6.6
func TestNodeGroupsHaveRequiredFields(t *testing.T) {
	t.Parallel()

	variablesFile := helpers.GetModulePath("clusters/eks") + "/variables.tf"
	require.True(t, helpers.FileExists(variablesFile), "variables.tf deve existir")

	requiredFields := []string{
		"instance_types",
		"min_size",
		"max_size",
		"desired_size",
		"disk_size",
		"labels",
		"taints",
	}

	for _, field := range requiredFields {
		t.Run(field, func(t *testing.T) {
			hasField, err := helpers.ContainsString(variablesFile, field)
			require.NoError(t, err)
			assert.True(t, hasField, "variables.tf deve definir campo %s para node_groups", field)
		})
	}
}
