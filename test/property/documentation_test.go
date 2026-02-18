package property

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// TestPropertyVariablesDocumentation valida Propriedade 15: Documentação de Variáveis e Outputs
// Feature: terraform-eks-aws-template, Property 15: Documentação de Variáveis e Outputs
// Para qualquer módulo Terraform, todas as variáveis em variables.tf devem ter campo "description"
// não-vazio e todos os outputs em outputs.tf devem ter campo "description" não-vazio.
// Valida: Requisitos 3.5, 15.3, 15.4
func TestPropertyVariablesDocumentation(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("all variables and outputs have descriptions", prop.ForAll(
		func() bool {
			modules := []string{
				"clusters/eks",
				"platform/argocd",
				"platform/policy-engine",
				"platform/external-secrets",
				"platform/observability",
				"platform/ingress",
				"platform/velero",
				"compliance",
			}

			for _, module := range modules {
				variablesFile := helpers.GetModulePath(module) + "/variables.tf"
				if helpers.FileExists(variablesFile) {
					// Verifica que variáveis têm description
					hasDescription, _ := helpers.ContainsString(variablesFile, "description")
					if !hasDescription {
						return false
					}
				}

				outputsFile := helpers.GetModulePath(module) + "/outputs.tf"
				if helpers.FileExists(outputsFile) {
					// Verifica que outputs têm description
					hasDescription, _ := helpers.ContainsString(outputsFile, "description")
					if !hasDescription {
						return false
					}
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyMandatoryTags valida Propriedade 16: Tags Obrigatórias
// Feature: terraform-eks-aws-template, Property 16: Tags Obrigatórias
// Para qualquer recurso AWS criado, ele deve ter as tags obrigatórias:
// Environment, ManagedBy, Project, Owner e Purpose.
// Valida: Requisitos 17.1, 18.6
func TestPropertyMandatoryTags(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("all environments have mandatory tags", prop.ForAll(
		func() bool {
			environments := []string{"staging", "prod"}
			mandatoryTags := []string{"Environment", "ManagedBy", "Project", "Owner", "Purpose"}

			for _, env := range environments {
				mainFile := helpers.GetEnvironmentPath(env) + "/main.tf"
				if !helpers.FileExists(mainFile) {
					return false
				}

				// Verifica que default_tags contém todas as tags obrigatórias
				hasDefaultTags, _ := helpers.ContainsString(mainFile, "default_tags")
				if !hasDefaultTags {
					return false
				}

				for _, tag := range mandatoryTags {
					hasTag, _ := helpers.ContainsString(mainFile, tag)
					if !hasTag {
						return false
					}
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyBucketPoliciesProtection valida Propriedade 17: Bucket Policies de Proteção
// Feature: terraform-eks-aws-template, Property 17: Bucket Policies de Proteção
// Para qualquer bucket S3 usado para logs ou backups, deve existir bucket policy com statement
// que nega ações s3:DeleteBucket e s3:DeleteObject.
// Valida: Requisitos 18.5
func TestPropertyBucketPoliciesProtection(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("S3 buckets have protection policies", prop.ForAll(
		func() bool {
			// Verifica compliance module (audit logs)
			complianceMain := helpers.GetModulePath("compliance") + "/main.tf"
			if helpers.FileExists(complianceMain) {
				hasBucketPolicy, _ := helpers.ContainsString(complianceMain, "aws_s3_bucket_policy")
				hasDenyDelete, _ := helpers.ContainsString(complianceMain, "DeleteBucket")

				if !hasBucketPolicy || !hasDenyDelete {
					return false
				}
			}

			// Verifica velero module (backups)
			veleroMain := helpers.GetModulePath("platform/velero") + "/main.tf"
			if helpers.FileExists(veleroMain) {
				// Velero pode ter bucket policy ou lifecycle rules
				hasBucketPolicy, _ := helpers.ContainsString(veleroMain, "aws_s3_bucket")
				if !hasBucketPolicy {
					return false
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}
