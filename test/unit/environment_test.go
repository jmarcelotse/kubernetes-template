package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestInstanceTypesDifferByEnvironment valida que staging e prod usam instance types diferentes
// Valida: Requisitos 13.1, 13.2
func TestInstanceTypesDifferByEnvironment(t *testing.T) {
	t.Parallel()

	stagingExample := helpers.GetEnvironmentPath("staging") + "/terraform.tfvars.example"
	prodExample := helpers.GetEnvironmentPath("prod") + "/terraform.tfvars.example"

	require.True(t, helpers.FileExists(stagingExample), "staging terraform.tfvars.example deve existir")
	require.True(t, helpers.FileExists(prodExample), "prod terraform.tfvars.example deve existir")

	// Staging deve usar t3.medium ou t3.large
	hasStagingTypes, err := helpers.ContainsRegex(stagingExample, `t3\.(medium|large)`)
	require.NoError(t, err)
	assert.True(t, hasStagingTypes, "Staging deve usar instance types t3.medium ou t3.large")

	// Prod deve usar m5.xlarge ou m5.2xlarge
	hasProdTypes, err := helpers.ContainsRegex(prodExample, `m5\.(xlarge|2xlarge)`)
	require.NoError(t, err)
	assert.True(t, hasProdTypes, "Prod deve usar instance types m5.xlarge ou m5.2xlarge")
}

// TestAutoscalingDiffersByEnvironment valida que staging e prod têm autoscaling diferente
// Valida: Requisitos 13.3, 13.4
func TestAutoscalingDiffersByEnvironment(t *testing.T) {
	t.Parallel()

	stagingExample := helpers.GetEnvironmentPath("staging") + "/terraform.tfvars.example"
	prodExample := helpers.GetEnvironmentPath("prod") + "/terraform.tfvars.example"

	require.True(t, helpers.FileExists(stagingExample), "staging terraform.tfvars.example deve existir")
	require.True(t, helpers.FileExists(prodExample), "prod terraform.tfvars.example deve existir")

	// Staging apps max_size deve ser ~10
	hasStagingMax, err := helpers.ContainsRegex(stagingExample, `max_size\s*=\s*10`)
	require.NoError(t, err)
	assert.True(t, hasStagingMax, "Staging apps deve ter max_size = 10")

	// Prod apps max_size deve ser ~50
	hasProdMax, err := helpers.ContainsRegex(prodExample, `max_size\s*=\s*50`)
	require.NoError(t, err)
	assert.True(t, hasProdMax, "Prod apps deve ter max_size = 50")
}

// TestStagingUsesSingleNATGateway valida que staging usa single NAT gateway
// Valida: Requisitos 17.3
func TestStagingUsesSingleNATGateway(t *testing.T) {
	t.Parallel()

	stagingExample := helpers.GetEnvironmentPath("staging") + "/terraform.tfvars.example"
	require.True(t, helpers.FileExists(stagingExample), "staging terraform.tfvars.example deve existir")

	hasSingleNAT, err := helpers.ContainsRegex(stagingExample, `single_nat_gateway\s*=\s*true`)
	require.NoError(t, err)
	assert.True(t, hasSingleNAT, "Staging deve ter single_nat_gateway = true para economia de custos")
}

// TestProdUsesMultiAZNATGateway valida que prod usa multi-AZ NAT gateways
// Valida: Requisitos 13.4
func TestProdUsesMultiAZNATGateway(t *testing.T) {
	t.Parallel()

	prodExample := helpers.GetEnvironmentPath("prod") + "/terraform.tfvars.example"
	require.True(t, helpers.FileExists(prodExample), "prod terraform.tfvars.example deve existir")

	hasMultiAZNAT, err := helpers.ContainsRegex(prodExample, `single_nat_gateway\s*=\s*false`)
	require.NoError(t, err)
	assert.True(t, hasMultiAZNAT, "Prod deve ter single_nat_gateway = false para alta disponibilidade")
}

// TestEnvironmentTerraformVarsExamplesExist valida que exemplos de terraform.tfvars existem
// Valida: Requisitos 13.7
func TestEnvironmentTerraformVarsExamplesExist(t *testing.T) {
	t.Parallel()

	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			exampleFile := helpers.GetEnvironmentPath(env) + "/terraform.tfvars.example"
			assert.True(t, helpers.FileExists(exampleFile), "terraform.tfvars.example deve existir em %s", env)
		})
	}
}
