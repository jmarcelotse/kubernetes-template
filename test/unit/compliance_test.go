package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCloudTrailCreated valida que CloudTrail é criado
// Valida: Requisitos 18.1
func TestCloudTrailCreated(t *testing.T) {
	t.Parallel()

	complianceMain := helpers.GetModulePath("compliance") + "/main.tf"
	require.True(t, helpers.FileExists(complianceMain), "compliance/main.tf deve existir")

	count, err := helpers.ExtractResourceCount(complianceMain, "aws_cloudtrail")
	require.NoError(t, err)
	assert.Greater(t, count, 0, "Compliance deve criar aws_cloudtrail")
}

// TestAWSConfigCreated valida que AWS Config é criado
// Valida: Requisitos 18.2
func TestAWSConfigCreated(t *testing.T) {
	t.Parallel()

	complianceMain := helpers.GetModulePath("compliance") + "/main.tf"
	require.True(t, helpers.FileExists(complianceMain), "compliance/main.tf deve existir")

	recorderCount, err := helpers.ExtractResourceCount(complianceMain, "aws_config_configuration_recorder")
	require.NoError(t, err)
	assert.Greater(t, recorderCount, 0, "Compliance deve criar aws_config_configuration_recorder")

	channelCount, err := helpers.ExtractResourceCount(complianceMain, "aws_config_delivery_channel")
	require.NoError(t, err)
	assert.Greater(t, channelCount, 0, "Compliance deve criar aws_config_delivery_channel")
}

// TestGuardDutyCreated valida que GuardDuty é criado
// Valida: Requisitos 18.3
func TestGuardDutyCreated(t *testing.T) {
	t.Parallel()

	complianceMain := helpers.GetModulePath("compliance") + "/main.tf"
	require.True(t, helpers.FileExists(complianceMain), "compliance/main.tf deve existir")

	count, err := helpers.ExtractResourceCount(complianceMain, "aws_guardduty_detector")
	require.NoError(t, err)
	assert.Greater(t, count, 0, "Compliance deve criar aws_guardduty_detector")
}
