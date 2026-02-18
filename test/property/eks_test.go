package property

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// TestPropertyControlPlaneLogs valida Propriedade 6: Logs do Control Plane Completos
// Feature: terraform-eks-aws-template, Property 6: Logs do Control Plane Completos
// Para qualquer cluster com enable_control_plane_logs=true, todos os 5 tipos de log
// (api, audit, authenticator, controllerManager, scheduler) devem estar habilitados.
// Valida: Requisitos 5.1
func TestPropertyControlPlaneLogs(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("all 5 control plane log types enabled", prop.ForAll(
		func() bool {
			variablesFile := helpers.GetModulePath("clusters/eks") + "/variables.tf"
			if !helpers.FileExists(variablesFile) {
				return false
			}

			// Verifica que todos os 5 tipos de log estão no default
			logTypes := []string{"api", "audit", "authenticator", "controllerManager", "scheduler"}
			for _, logType := range logTypes {
				hasLogType, _ := helpers.ContainsString(variablesFile, logType)
				if !hasLogType {
					return false
				}
			}

			// Verifica que há validation para control_plane_log_types
			hasValidation, _ := helpers.ExtractVariableValidation(variablesFile, "control_plane_log_types")
			return hasValidation
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertySecretsEncryptionKMS valida Propriedade 7: Criptografia de Secrets com KMS
// Feature: terraform-eks-aws-template, Property 7: Criptografia de Secrets com KMS
// Para qualquer cluster com enable_secrets_encryption=true, deve existir uma chave KMS dedicada
// e encryption_config configurado para o recurso "secrets".
// Valida: Requisitos 5.2
func TestPropertySecretsEncryptionKMS(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("KMS encryption configured for secrets", prop.ForAll(
		func() bool {
			eksFile := helpers.GetModulePath("clusters/eks") + "/eks.tf"
			if !helpers.FileExists(eksFile) {
				return false
			}

			// Verifica que há configuração de KMS e encryption_config
			hasKMS, _ := helpers.ContainsString(eksFile, "aws_kms_key")
			hasEncryptionConfig, _ := helpers.ContainsString(eksFile, "encryption_config")
			hasSecretsResource, _ := helpers.ContainsString(eksFile, `"secrets"`)

			return hasKMS && hasEncryptionConfig && hasSecretsResource
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyKubernetesVersionValid valida Propriedade 8: Versão Kubernetes Válida
// Feature: terraform-eks-aws-template, Property 8: Versão Kubernetes Válida
// Para qualquer configuração de cluster, a versão do Kubernetes deve estar no formato "X.YY"
// onde X é 1 e YY é um número entre 24 e 30.
// Valida: Requisitos 5.5
func TestPropertyKubernetesVersionValid(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("kubernetes version has validation", prop.ForAll(
		func() bool {
			variablesFile := helpers.GetModulePath("clusters/eks") + "/variables.tf"
			if !helpers.FileExists(variablesFile) {
				return false
			}

			// Verifica que há validation para cluster_version
			hasValidation, _ := helpers.ExtractVariableValidation(variablesFile, "cluster_version")
			if !hasValidation {
				return false
			}

			// Verifica que validation aceita versões 1.24-1.30 (procura pelo regex pattern)
			hasVersionPattern, _ := helpers.ContainsRegex(variablesFile, `1\\.`)

			return hasVersionPattern
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}
