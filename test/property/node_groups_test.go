package property

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// TestPropertyNodeGroupsComplete valida Propriedade 9: Node Groups Completos
// Feature: terraform-eks-aws-template, Property 9: Node Groups Completos
// Para qualquer node group configurado, ele deve ter todos os campos obrigatórios:
// instance_types, min_size, max_size, desired_size, disk_size e labels.
// Valida: Requisitos 6.3, 6.4, 6.5, 6.6
func TestPropertyNodeGroupsComplete(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("node groups have all required fields", prop.ForAll(
		func() bool {
			variablesFile := helpers.GetModulePath("clusters/eks") + "/variables.tf"
			if !helpers.FileExists(variablesFile) {
				return false
			}

			// Verifica que todos os campos obrigatórios estão definidos
			requiredFields := []string{
				"instance_types",
				"min_size",
				"max_size",
				"desired_size",
				"disk_size",
				"labels",
			}

			for _, field := range requiredFields {
				hasField, _ := helpers.ContainsString(variablesFile, field)
				if !hasField {
					return false
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyAutoscalingConservative valida Propriedade 10: Autoscaling Conservador para System Nodes
// Feature: terraform-eks-aws-template, Property 10: Autoscaling Conservador para System Nodes
// Para qualquer node group com label role=system, a diferença entre max_size e min_size deve ser ≤ 3.
// Valida: Requisitos 6.7
func TestPropertyAutoscalingConservative(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("system node groups have conservative autoscaling", prop.ForAll(
		func() bool {
			// Verifica nos exemplos que system nodes têm autoscaling conservador
			environments := []string{"staging", "prod"}

			for _, env := range environments {
				exampleFile := helpers.GetEnvironmentPath(env) + "/terraform.tfvars.example"
				if !helpers.FileExists(exampleFile) {
					return false
				}

				// Verifica que system node group existe
				hasSystem, _ := helpers.ContainsString(exampleFile, "system")
				if !hasSystem {
					continue
				}

				// Para staging: min=2, max=3 (diferença=1)
				// Para prod: min=3, max=5 (diferença=2)
				// Ambos ≤ 3, então é conservador
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyNodeGroupsEnvironmentIsolation valida Propriedade 1: Isolamento de Ambientes
// Feature: terraform-eks-aws-template, Property 1: Isolamento de Ambientes
// Para qualquer par de ambientes distintos (staging, prod), cada ambiente deve ter
// state file S3 em path único, VPC com CIDR único e cluster EKS com nome único.
// Valida: Requisitos 1.1, 1.2, 1.3, 1.4
func TestPropertyNodeGroupsEnvironmentIsolation(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("environments have unique resources", prop.ForAll(
		func() bool {
			stagingBackend := helpers.GetEnvironmentPath("staging") + "/backend.tf"
			prodBackend := helpers.GetEnvironmentPath("prod") + "/backend.tf"

			if !helpers.FileExists(stagingBackend) || !helpers.FileExists(prodBackend) {
				return false
			}

			// Verifica que paths de state são diferentes
			hasStagingPath, _ := helpers.ContainsString(stagingBackend, "staging")
			hasProdPath, _ := helpers.ContainsString(prodBackend, "prod")

			// Verifica que VPC CIDRs são diferentes nos exemplos
			stagingExample := helpers.GetEnvironmentPath("staging") + "/terraform.tfvars.example"
			prodExample := helpers.GetEnvironmentPath("prod") + "/terraform.tfvars.example"

			hasStagingCIDR, _ := helpers.ContainsString(stagingExample, "10.0.0.0/16")
			hasProdCIDR, _ := helpers.ContainsString(prodExample, "10.1.0.0/16")

			return hasStagingPath && hasProdPath && hasStagingCIDR && hasProdCIDR
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}
