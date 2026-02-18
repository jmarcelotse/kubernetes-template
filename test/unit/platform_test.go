package unit

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// ============================================================================
// ArgoCD Tests
// ============================================================================

// TestArgoCDHelmReleaseExists valida que helm_release para ArgoCD existe
// Valida: Requisitos 7.1
func TestArgoCDHelmReleaseExists(t *testing.T) {
	t.Parallel()

	argocdMain := helpers.GetModulePath("platform/argocd") + "/main.tf"
	require.True(t, helpers.FileExists(argocdMain), "argocd/main.tf deve existir")

	hasHelmRelease, err := helpers.ContainsString(argocdMain, `resource "helm_release"`)
	require.NoError(t, err)
	assert.True(t, hasHelmRelease, "ArgoCD deve usar helm_release")

	hasArgoCD, err := helpers.ContainsString(argocdMain, "argo-cd")
	require.NoError(t, err)
	assert.True(t, hasArgoCD, "Helm chart deve ser argo-cd")
}

// TestArgoCDNamespaceCreated valida que namespace é criado
// Valida: Requisitos 7.2
func TestArgoCDNamespaceCreated(t *testing.T) {
	t.Parallel()

	argocdMain := helpers.GetModulePath("platform/argocd") + "/main.tf"
	require.True(t, helpers.FileExists(argocdMain), "argocd/main.tf deve existir")

	hasNamespace, err := helpers.ContainsString(argocdMain, `resource "kubernetes_namespace"`)
	require.NoError(t, err)
	assert.True(t, hasNamespace, "ArgoCD deve criar kubernetes_namespace")

	hasArgocdNS, err := helpers.ContainsString(argocdMain, `"argocd"`)
	require.NoError(t, err)
	assert.True(t, hasArgocdNS, "Namespace deve ser argocd")
}

// TestArgoCDTolerationsConfigured valida que tolerations estão configuradas
// Valida: Requisitos 7.3
func TestArgoCDTolerationsConfigured(t *testing.T) {
	t.Parallel()

	argocdMain := helpers.GetModulePath("platform/argocd") + "/main.tf"
	require.True(t, helpers.FileExists(argocdMain), "argocd/main.tf deve existir")

	hasTolerations, err := helpers.ContainsString(argocdMain, "tolerations")
	require.NoError(t, err)
	assert.True(t, hasTolerations, "ArgoCD deve ter tolerations configuradas")

	// Verifica que usa var.tolerations (configurável)
	hasVarTolerations, err := helpers.ContainsString(argocdMain, "var.tolerations")
	require.NoError(t, err)
	assert.True(t, hasVarTolerations, "ArgoCD deve usar var.tolerations")
}

// TestArgoCDOutputsExist valida que outputs existem
// Valida: Requisitos 7.4
func TestArgoCDOutputsExist(t *testing.T) {
	t.Parallel()

	argocdOutputs := helpers.GetModulePath("platform/argocd") + "/outputs.tf"
	require.True(t, helpers.FileExists(argocdOutputs), "argocd/outputs.tf deve existir")

	outputs, err := helpers.ExtractOutputs(argocdOutputs)
	require.NoError(t, err)

	expectedOutputs := []string{"namespace", "server_service_name", "initial_admin_password_secret"}
	for _, expected := range expectedOutputs {
		assert.Contains(t, outputs, expected, "ArgoCD deve ter output %s", expected)
	}
}

// ============================================================================
// Policy Engine Tests
// ============================================================================

// TestPolicyEngineVariableValidation valida que variável engine tem validation
// Valida: Requisitos 8.1
func TestPolicyEngineVariableValidation(t *testing.T) {
	t.Parallel()

	policyVars := helpers.GetModulePath("platform/policy-engine") + "/variables.tf"
	require.True(t, helpers.FileExists(policyVars), "policy-engine/variables.tf deve existir")

	hasValidation, err := helpers.ExtractVariableValidation(policyVars, "engine")
	require.NoError(t, err)
	assert.True(t, hasValidation, "Variável engine deve ter validation block")

	hasKyverno, err := helpers.ContainsString(policyVars, "kyverno")
	require.NoError(t, err)
	assert.True(t, hasKyverno, "Validation deve aceitar kyverno")

	hasGatekeeper, err := helpers.ContainsString(policyVars, "gatekeeper")
	require.NoError(t, err)
	assert.True(t, hasGatekeeper, "Validation deve aceitar gatekeeper")
}

// TestStagingUsesAuditMode valida que staging usa audit mode
// Valida: Requisitos 8.6
func TestStagingUsesAuditMode(t *testing.T) {
	t.Parallel()

	stagingMain := helpers.GetEnvironmentPath("staging") + "/main.tf"
	require.True(t, helpers.FileExists(stagingMain), "staging/main.tf deve existir")

	hasAuditMode, err := helpers.ContainsRegex(stagingMain, `enforcement_mode\s*=\s*"audit"`)
	require.NoError(t, err)
	assert.True(t, hasAuditMode, "Staging deve usar enforcement_mode = audit")
}

// TestProdUsesEnforceMode valida que prod usa enforce mode
// Valida: Requisitos 8.7
func TestProdUsesEnforceMode(t *testing.T) {
	t.Parallel()

	prodMain := helpers.GetEnvironmentPath("prod") + "/main.tf"
	require.True(t, helpers.FileExists(prodMain), "prod/main.tf deve existir")

	hasEnforceMode, err := helpers.ContainsRegex(prodMain, `enforcement_mode\s*=\s*"enforce"`)
	require.NoError(t, err)
	assert.True(t, hasEnforceMode, "Prod deve usar enforcement_mode = enforce")
}

// ============================================================================
// External Secrets Tests
// ============================================================================

// TestExternalSecretsClusterSecretStoreCreated valida que ClusterSecretStore é criado
// Valida: Requisitos 9.2
func TestExternalSecretsClusterSecretStoreCreated(t *testing.T) {
	t.Parallel()

	externalSecretsMain := helpers.GetModulePath("platform/external-secrets") + "/main.tf"
	require.True(t, helpers.FileExists(externalSecretsMain), "external-secrets/main.tf deve existir")

	hasClusterSecretStore, err := helpers.ContainsString(externalSecretsMain, "ClusterSecretStore")
	require.NoError(t, err)
	assert.True(t, hasClusterSecretStore, "External Secrets deve criar ClusterSecretStore")
}

// TestExternalSecretsAWSRegionVariable valida que variável aws_region existe
// Valida: Requisitos 9.3
func TestExternalSecretsAWSRegionVariable(t *testing.T) {
	t.Parallel()

	externalSecretsVars := helpers.GetModulePath("platform/external-secrets") + "/variables.tf"
	require.True(t, helpers.FileExists(externalSecretsVars), "external-secrets/variables.tf deve existir")

	hasAWSRegion, err := helpers.ContainsString(externalSecretsVars, `variable "aws_region"`)
	require.NoError(t, err)
	assert.True(t, hasAWSRegion, "External Secrets deve ter variável aws_region")
}

// TestExternalSecretsNamespaceCreated valida que namespace é criado
// Valida: Requisitos 9.4
func TestExternalSecretsNamespaceCreated(t *testing.T) {
	t.Parallel()

	externalSecretsMain := helpers.GetModulePath("platform/external-secrets") + "/main.tf"
	require.True(t, helpers.FileExists(externalSecretsMain), "external-secrets/main.tf deve existir")

	hasNamespace, err := helpers.ContainsString(externalSecretsMain, `resource "kubernetes_namespace"`)
	require.NoError(t, err)
	assert.True(t, hasNamespace, "External Secrets deve criar namespace")
}

// TestExternalSecretsExampleExists valida que arquivo de exemplo existe
// Valida: Requisitos 9.5
func TestExternalSecretsExampleExists(t *testing.T) {
	t.Parallel()

	examplesDir := helpers.GetModulePath("platform/external-secrets") + "/examples"
	assert.True(t, helpers.DirectoryExists(examplesDir), "Diretório examples deve existir")

	// Verifica se há pelo menos um arquivo de exemplo
	hasExample := helpers.FileExists(examplesDir+"/external-secret-example.yaml") ||
		helpers.FileExists(examplesDir+"/example.yaml")
	assert.True(t, hasExample, "Deve existir arquivo de exemplo de ExternalSecret")
}

// ============================================================================
// Observability Tests
// ============================================================================

// TestObservabilityPrometheusExists valida que helm_release para prometheus existe
// Valida: Requisitos 10.1
func TestObservabilityPrometheusExists(t *testing.T) {
	t.Parallel()

	observabilityMain := helpers.GetModulePath("platform/observability") + "/main.tf"
	require.True(t, helpers.FileExists(observabilityMain), "observability/main.tf deve existir")

	hasPrometheus, err := helpers.ContainsString(observabilityMain, "kube-prometheus-stack")
	require.NoError(t, err)
	assert.True(t, hasPrometheus, "Observability deve instalar kube-prometheus-stack")
}

// TestObservabilityLokiExists valida que helm_release para loki existe
// Valida: Requisitos 10.2
func TestObservabilityLokiExists(t *testing.T) {
	t.Parallel()

	observabilityMain := helpers.GetModulePath("platform/observability") + "/main.tf"
	require.True(t, helpers.FileExists(observabilityMain), "observability/main.tf deve existir")

	hasLoki, err := helpers.ContainsString(observabilityMain, "loki")
	require.NoError(t, err)
	assert.True(t, hasLoki, "Observability deve instalar loki")
}

// TestObservabilityOTELExists valida que helm_release para otel existe
// Valida: Requisitos 10.3
func TestObservabilityOTELExists(t *testing.T) {
	t.Parallel()

	observabilityMain := helpers.GetModulePath("platform/observability") + "/main.tf"
	require.True(t, helpers.FileExists(observabilityMain), "observability/main.tf deve existir")

	hasOTEL, err := helpers.ContainsString(observabilityMain, "opentelemetry")
	require.NoError(t, err)
	assert.True(t, hasOTEL, "Observability deve instalar opentelemetry-collector")
}

// TestObservabilityOutputsExist valida que outputs existem
// Valida: Requisitos 10.7
func TestObservabilityOutputsExist(t *testing.T) {
	t.Parallel()

	observabilityOutputs := helpers.GetModulePath("platform/observability") + "/outputs.tf"
	require.True(t, helpers.FileExists(observabilityOutputs), "observability/outputs.tf deve existir")

	outputs, err := helpers.ExtractOutputs(observabilityOutputs)
	require.NoError(t, err)

	// Deve ter pelo menos grafana_endpoint e prometheus_endpoint
	hasGrafana := false
	hasPrometheus := false
	for _, output := range outputs {
		if output == "grafana_endpoint" || output == "grafana_url" {
			hasGrafana = true
		}
		if output == "prometheus_endpoint" || output == "prometheus_url" {
			hasPrometheus = true
		}
	}

	assert.True(t, hasGrafana, "Observability deve ter output para Grafana")
	assert.True(t, hasPrometheus, "Observability deve ter output para Prometheus")
}

// ============================================================================
// Ingress Tests
// ============================================================================

// TestIngressTypeVariableValidation valida que variável ingress_type tem validation
// Valida: Requisitos 11.1
func TestIngressTypeVariableValidation(t *testing.T) {
	t.Parallel()

	ingressVars := helpers.GetModulePath("platform/ingress") + "/variables.tf"
	require.True(t, helpers.FileExists(ingressVars), "ingress/variables.tf deve existir")

	hasValidation, err := helpers.ExtractVariableValidation(ingressVars, "ingress_type")
	require.NoError(t, err)
	assert.True(t, hasValidation, "Variável ingress_type deve ter validation block")
}

// TestIngressClusterIssuerCreated valida que ClusterIssuer é criado
// Valida: Requisitos 11.3
func TestIngressClusterIssuerCreated(t *testing.T) {
	t.Parallel()

	ingressMain := helpers.GetModulePath("platform/ingress") + "/cert_manager.tf"
	require.True(t, helpers.FileExists(ingressMain), "ingress/cert_manager.tf deve existir")

	hasClusterIssuer, err := helpers.ContainsString(ingressMain, "ClusterIssuer")
	require.NoError(t, err)
	assert.True(t, hasClusterIssuer, "Ingress deve criar ClusterIssuer")

	hasLetsEncrypt, err := helpers.ContainsString(ingressMain, "letsencrypt")
	require.NoError(t, err)
	assert.True(t, hasLetsEncrypt, "ClusterIssuer deve usar Let's Encrypt")
}

// TestIngressRoute53ZoneVariable valida que variável route53_zone_id existe
// Valida: Requisitos 11.5
func TestIngressRoute53ZoneVariable(t *testing.T) {
	t.Parallel()

	ingressVars := helpers.GetModulePath("platform/ingress") + "/variables.tf"
	require.True(t, helpers.FileExists(ingressVars), "ingress/variables.tf deve existir")

	hasRoute53, err := helpers.ContainsString(ingressVars, `variable "route53_zone_id"`)
	require.NoError(t, err)
	assert.True(t, hasRoute53, "Ingress deve ter variável route53_zone_id")
}

// TestIngressExampleExists valida que arquivo de exemplo existe
// Valida: Requisitos 11.6
func TestIngressExampleExists(t *testing.T) {
	t.Parallel()

	examplesDir := helpers.GetModulePath("platform/ingress") + "/examples"
	assert.True(t, helpers.DirectoryExists(examplesDir), "Diretório examples deve existir")

	// Verifica se há exemplos de ingress
	hasALBExample := helpers.FileExists(examplesDir + "/ingress-alb-example.yaml")
	hasNginxExample := helpers.FileExists(examplesDir + "/ingress-nginx-example.yaml")

	assert.True(t, hasALBExample || hasNginxExample, "Deve existir arquivo de exemplo de Ingress")
}

// ============================================================================
// Velero Tests
// ============================================================================

// TestVeleroS3BucketCreated valida que aws_s3_bucket é criado
// Valida: Requisitos 12.1
func TestVeleroS3BucketCreated(t *testing.T) {
	t.Parallel()

	veleroMain := helpers.GetModulePath("platform/velero") + "/main.tf"
	require.True(t, helpers.FileExists(veleroMain), "velero/main.tf deve existir")

	count, err := helpers.ExtractResourceCount(veleroMain, "aws_s3_bucket")
	require.NoError(t, err)
	assert.Greater(t, count, 0, "Velero deve criar aws_s3_bucket")
}

// TestVeleroBucketNameOutput valida que output bucket_name existe
// Valida: Requisitos 12.5
func TestVeleroBucketNameOutput(t *testing.T) {
	t.Parallel()

	veleroOutputs := helpers.GetModulePath("platform/velero") + "/outputs.tf"
	require.True(t, helpers.FileExists(veleroOutputs), "velero/outputs.tf deve existir")

	outputs, err := helpers.ExtractOutputs(veleroOutputs)
	require.NoError(t, err)

	hasBucketName := false
	for _, output := range outputs {
		if output == "backup_bucket_name" || output == "bucket_name" {
			hasBucketName = true
			break
		}
	}

	assert.True(t, hasBucketName, "Velero deve ter output bucket_name")
}
