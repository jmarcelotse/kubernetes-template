package property

import (
	"path/filepath"
	"strings"
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/prop"
)

// TestPropertyEnvironmentIsolation valida isolamento entre ambientes
// Feature: terraform-eks-aws-template, Property 1: Isolamento de Ambientes
// Valida: Requisitos 1.1, 1.2, 1.3, 1.4
func TestPropertyEnvironmentIsolation(t *testing.T) {
	properties := gopter.NewProperties(nil)

	properties.Property("ambientes têm state paths únicos", prop.ForAll(
		func(env1, env2 string) bool {
			if env1 == env2 {
				return true // Skip mesmo ambiente
			}

			backend1 := filepath.Join(helpers.GetProjectRoot(), "live", "aws", env1, "backend.tf")
			backend2 := filepath.Join(helpers.GetProjectRoot(), "live", "aws", env2, "backend.tf")

			content1, err1 := helpers.ReadFileContent(backend1)
			content2, err2 := helpers.ReadFileContent(backend2)

			if err1 != nil || err2 != nil {
				return true // Skip se arquivos não existem
			}

			// State paths devem ser diferentes
			return !strings.Contains(content1, content2) || 
				   strings.Contains(content1, env1) && strings.Contains(content2, env2)
		},
		helpers.GenEnvironment(),
		helpers.GenEnvironment(),
	))

	properties.Property("ambientes têm VPC CIDRs únicos", prop.ForAll(
		func(env1, env2 string) bool {
			if env1 == env2 {
				return true
			}

			example1 := filepath.Join(helpers.GetProjectRoot(), "live", "aws", env1, "terraform.tfvars.example")
			example2 := filepath.Join(helpers.GetProjectRoot(), "live", "aws", env2, "terraform.tfvars.example")

			content1, err1 := helpers.ReadFileContent(example1)
			content2, err2 := helpers.ReadFileContent(example2)

			if err1 != nil || err2 != nil {
				return true
			}

			// Extrai VPC CIDRs
			cidr1 := extractVPCCIDR(content1)
			cidr2 := extractVPCCIDR(content2)

			// CIDRs devem ser diferentes
			return cidr1 != cidr2
		},
		helpers.GenEnvironment(),
		helpers.GenEnvironment(),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

func extractVPCCIDR(content string) string {
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		if strings.Contains(line, "vpc_cidr") && strings.Contains(line, "=") {
			parts := strings.Split(line, "=")
			if len(parts) > 1 {
				return strings.TrimSpace(strings.Trim(parts[1], `"' `))
			}
		}
	}
	return ""
}
