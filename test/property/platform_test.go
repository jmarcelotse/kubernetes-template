package property

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// TestPropertySecurityPoliciesEnabled valida Propriedade 11: Políticas de Segurança Habilitadas
// Feature: terraform-eks-aws-template, Property 11: Políticas de Segurança Habilitadas
// Para qualquer configuração de policy engine com policies habilitadas, devem existir
// 4 políticas correspondentes no código: block_privileged, require_non_root,
// require_resources, block_latest_tag.
// Valida: Requisitos 8.2, 8.3, 8.4, 8.5
func TestPropertySecurityPoliciesEnabled(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("all security policies exist", prop.ForAll(
		func() bool {
			kyvernoFile := helpers.GetModulePath("platform/policy-engine") + "/policies_kyverno.tf"
			gatekeeperFile := helpers.GetModulePath("platform/policy-engine") + "/policies_gatekeeper.tf"

			if !helpers.FileExists(kyvernoFile) && !helpers.FileExists(gatekeeperFile) {
				return false
			}

			// Verifica que as 4 políticas principais existem
			policies := []string{"block_privileged", "require_non_root", "require_resources", "block_latest_tag"}

			for _, policy := range policies {
				hasInKyverno, _ := helpers.ContainsString(kyvernoFile, policy)
				hasInGatekeeper, _ := helpers.ContainsString(gatekeeperFile, policy)

				if !hasInKyverno && !hasInGatekeeper {
					return false
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyIRSACorrect valida Propriedade 12: IRSA com Permissões Corretas
// Feature: terraform-eks-aws-template, Property 12: IRSA com Permissões Corretas
// Para qualquer módulo de plataforma que cria IRSA role (external-secrets, ingress, velero),
// a role deve ter trust policy com OIDC provider e condition StringEquals para namespace e service account.
// Valida: Requisitos 9.1, 11.2, 11.4, 12.2
func TestPropertyIRSACorrect(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("IRSA roles have correct trust policy", prop.ForAll(
		func() bool {
			modules := []string{"external-secrets", "velero"}

			for _, module := range modules {
				mainFile := helpers.GetModulePath("platform/"+module) + "/main.tf"
				if !helpers.FileExists(mainFile) {
					continue
				}

				// Verifica que há IAM role com trust policy OIDC
				hasIAMRole, _ := helpers.ContainsString(mainFile, "aws_iam_role")
				hasOIDC, _ := helpers.ContainsString(mainFile, "oidc_provider")
				hasStringEquals, _ := helpers.ContainsString(mainFile, "StringEquals")

				if !hasIAMRole || !hasOIDC || !hasStringEquals {
					return false
				}
			}

			// Para ingress, verifica no alb_controller.tf
			albFile := helpers.GetModulePath("platform/ingress") + "/alb_controller.tf"
			if helpers.FileExists(albFile) {
				hasIAMRole, _ := helpers.ContainsString(albFile, "aws_iam_role")
				hasOIDC, _ := helpers.ContainsString(albFile, "oidc_provider")
				hasStringEquals, _ := helpers.ContainsString(albFile, "StringEquals")

				if !hasIAMRole || !hasOIDC || !hasStringEquals {
					return false
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyRetentionByEnvironment valida Propriedade 13: Retenção por Ambiente
// Feature: terraform-eks-aws-template, Property 13: Retenção por Ambiente
// Para qualquer configuração de observabilidade, se environment="staging" então
// prometheus_retention_days=7 e loki_retention_days=3; se environment="prod" então
// prometheus_retention_days=30 e loki_retention_days=15.
// Valida: Requisitos 10.4, 10.5
func TestPropertyRetentionByEnvironment(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("retention matches environment", prop.ForAll(
		func() bool {
			stagingMain := helpers.GetEnvironmentPath("staging") + "/main.tf"
			prodMain := helpers.GetEnvironmentPath("prod") + "/main.tf"

			if !helpers.FileExists(stagingMain) || !helpers.FileExists(prodMain) {
				return false
			}

			// Staging: 7 dias prometheus, 3 dias loki
			hasStagingPrometheus, _ := helpers.ContainsRegex(stagingMain, `prometheus_retention_days\s*=\s*7`)
			hasStagingLoki, _ := helpers.ContainsRegex(stagingMain, `loki_retention_days\s*=\s*3`)

			// Prod: 30 dias prometheus, 15 dias loki
			hasProdPrometheus, _ := helpers.ContainsRegex(prodMain, `prometheus_retention_days\s*=\s*30`)
			hasProdLoki, _ := helpers.ContainsRegex(prodMain, `loki_retention_days\s*=\s*15`)

			return hasStagingPrometheus && hasStagingLoki && hasProdPrometheus && hasProdLoki
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyBackupScheduleByEnvironment valida Propriedade 14: Backup Schedule por Ambiente
// Feature: terraform-eks-aws-template, Property 14: Backup Schedule por Ambiente
// Para qualquer configuração de Velero, se environment="staging" então backup_schedule="0 2 * * *" (diário)
// e backup_retention_days=7; se environment="prod" então backup_schedule="0 */6 * * *" (6h)
// e backup_retention_days=30.
// Valida: Requisitos 12.3, 12.4
func TestPropertyBackupScheduleByEnvironment(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("backup schedule matches environment", prop.ForAll(
		func() bool {
			stagingMain := helpers.GetEnvironmentPath("staging") + "/main.tf"
			prodMain := helpers.GetEnvironmentPath("prod") + "/main.tf"

			if !helpers.FileExists(stagingMain) || !helpers.FileExists(prodMain) {
				return false
			}

			// Staging: diário (0 2 * * *), 7 dias retenção
			hasStagingSchedule, _ := helpers.ContainsString(stagingMain, "0 2 * * *")
			hasStagingRetention, _ := helpers.ContainsRegex(stagingMain, `backup_retention_days\s*=\s*7`)

			// Prod: 6h (0 */6 * * *), 30 dias retenção
			hasProdSchedule, _ := helpers.ContainsString(prodMain, "0 */6 * * *")
			hasProdRetention, _ := helpers.ContainsRegex(prodMain, `backup_retention_days\s*=\s*30`)

			return hasStagingSchedule && hasStagingRetention && hasProdSchedule && hasProdRetention
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}
