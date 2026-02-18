package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestOIDCProviderCreated valida que aws_iam_openid_connect_provider é criado
// Valida: Requisitos 5.3
func TestOIDCProviderCreated(t *testing.T) {
	t.Parallel()

	irsaFile := helpers.GetModulePath("clusters/eks") + "/irsa.tf"
	require.True(t, helpers.FileExists(irsaFile), "irsa.tf deve existir")

	count, err := helpers.ExtractResourceCount(irsaFile, "aws_iam_openid_connect_provider")
	require.NoError(t, err)
	assert.Greater(t, count, 0, "IRSA deve criar aws_iam_openid_connect_provider")
}
