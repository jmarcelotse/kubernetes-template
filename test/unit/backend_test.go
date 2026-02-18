package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestBackendConfigHasLockfile valida que backend.tf contém use_lockfile = true
// Valida: Requisitos 2.1
func TestBackendConfigHasLockfile(t *testing.T) {
	t.Parallel()

	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			backendFile := helpers.GetEnvironmentPath(env) + "/backend.tf"
			require.True(t, helpers.FileExists(backendFile), "backend.tf deve existir em %s", env)

			hasLockfile, err := helpers.ContainsString(backendFile, "use_lockfile")
			require.NoError(t, err)
			assert.True(t, hasLockfile, "backend.tf deve conter use_lockfile em %s", env)

			hasTrue, err := helpers.ContainsRegex(backendFile, `use_lockfile\s*=\s*true`)
			require.NoError(t, err)
			assert.True(t, hasTrue, "use_lockfile deve ser true em %s", env)
		})
	}
}

// TestBackendConfigHasEncrypt valida que backend.tf contém encrypt = true
// Valida: Requisitos 2.3
func TestBackendConfigHasEncrypt(t *testing.T) {
	t.Parallel()

	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			backendFile := helpers.GetEnvironmentPath(env) + "/backend.tf"
			require.True(t, helpers.FileExists(backendFile), "backend.tf deve existir em %s", env)

			hasEncrypt, err := helpers.ContainsString(backendFile, "encrypt")
			require.NoError(t, err)
			assert.True(t, hasEncrypt, "backend.tf deve conter encrypt em %s", env)

			hasTrue, err := helpers.ContainsRegex(backendFile, `encrypt\s*=\s*true`)
			require.NoError(t, err)
			assert.True(t, hasTrue, "encrypt deve ser true em %s", env)
		})
	}
}

// TestBackendConfigNoDynamoDB valida que backend.tf NÃO contém dynamodb_table
// Valida: Requisitos 2.4
func TestBackendConfigNoDynamoDB(t *testing.T) {
	t.Parallel()

	environments := []string{"staging", "prod"}

	for _, env := range environments {
		t.Run(env, func(t *testing.T) {
			backendFile := helpers.GetEnvironmentPath(env) + "/backend.tf"
			require.True(t, helpers.FileExists(backendFile), "backend.tf deve existir em %s", env)

			hasDynamoDB, err := helpers.ContainsString(backendFile, "dynamodb_table")
			require.NoError(t, err)
			assert.False(t, hasDynamoDB, "backend.tf NÃO deve conter dynamodb_table em %s (usar S3 native locking)", env)
		})
	}
}
