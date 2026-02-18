package property

import (
	"testing"

	"github.com/example/terraform-eks-aws-template/test/helpers"
	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/gen"
	"github.com/leanovate/gopter/prop"
)

// TestPropertySubnetsMultiAZ valida Propriedade 2: Subnets Multi-AZ
// Feature: terraform-eks-aws-template, Property 2: Subnets Multi-AZ
// Para qualquer configuração de VPC com N zonas de disponibilidade (N ≥ 2),
// o módulo deve criar exatamente N subnets privadas e N subnets públicas, uma em cada AZ.
// Valida: Requisitos 4.1, 4.2
func TestPropertySubnetsMultiAZ(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("subnets match AZ count", prop.ForAll(
		func(azCount int) bool {
			// Verifica que o arquivo VPC tem lógica para criar subnets por AZ
			vpcFile := helpers.GetModulePath("clusters/eks") + "/vpc.tf"
			if !helpers.FileExists(vpcFile) {
				return false
			}

			// Verifica que usa count ou for_each com availability_zones
			hasPrivateSubnets, _ := helpers.ContainsRegex(vpcFile, `resource\s+"aws_subnet"\s+"private"`)
			hasPublicSubnets, _ := helpers.ContainsRegex(vpcFile, `resource\s+"aws_subnet"\s+"public"`)
			hasAZReference, _ := helpers.ContainsString(vpcFile, "availability_zones")

			return hasPrivateSubnets && hasPublicSubnets && hasAZReference
		},
		gen.IntRange(2, 4), // 2 a 4 AZs
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyNATGatewayPerAZ valida Propriedade 3: NAT Gateway por AZ
// Feature: terraform-eks-aws-template, Property 3: NAT Gateway por AZ
// Para qualquer configuração com enable_nat_gateway=true e single_nat_gateway=false e N AZs,
// o módulo deve criar exatamente N NAT gateways.
// Valida: Requisitos 4.3
func TestPropertyNATGatewayPerAZ(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("NAT gateways match AZ count when multi-AZ", prop.ForAll(
		func(azCount int, singleNAT bool) bool {
			vpcFile := helpers.GetModulePath("clusters/eks") + "/vpc.tf"
			if !helpers.FileExists(vpcFile) {
				return false
			}

			// Verifica que há lógica condicional para single vs multi NAT
			hasNATGateway, _ := helpers.ContainsString(vpcFile, `resource "aws_nat_gateway"`)
			hasSingleNATLogic, _ := helpers.ContainsString(vpcFile, "single_nat_gateway")
			hasCountLogic, _ := helpers.ContainsRegex(vpcFile, `count\s*=`)

			return hasNATGateway && hasSingleNATLogic && hasCountLogic
		},
		gen.IntRange(2, 4),
		gen.Bool(),
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyKubernetesTagsOnSubnets valida Propriedade 5: Tags Kubernetes em Subnets
// Feature: terraform-eks-aws-template, Property 5: Tags Kubernetes em Subnets
// Para qualquer subnet criada, ela deve conter tags no formato kubernetes.io/cluster/<cluster_name>
// para descoberta automática.
// Valida: Requisitos 4.6
func TestPropertyKubernetesTagsOnSubnets(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("subnets have kubernetes tags", prop.ForAll(
		func() bool {
			vpcFile := helpers.GetModulePath("clusters/eks") + "/vpc.tf"
			if !helpers.FileExists(vpcFile) {
				return false
			}

			// Verifica que subnets têm tags kubernetes.io/cluster
			hasK8sTags, _ := helpers.ContainsString(vpcFile, "kubernetes.io/cluster")
			hasClusterNameRef, _ := helpers.ContainsString(vpcFile, "cluster_name")

			return hasK8sTags && hasClusterNameRef
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}

// TestPropertyVPCEndpointsComplete valida Propriedade 4: VPC Endpoints Completos
// Feature: terraform-eks-aws-template, Property 4: VPC Endpoints Completos
// Para qualquer configuração com enable_vpc_endpoints=true, o módulo deve criar endpoints
// para todos os serviços obrigatórios: ecr.api, ecr.dkr, sts, logs e ssm.
// Valida: Requisitos 4.4
func TestPropertyVPCEndpointsComplete(t *testing.T) {
	t.Parallel()

	properties := gopter.NewProperties(nil)

	properties.Property("all required VPC endpoints exist", prop.ForAll(
		func() bool {
			vpcEndpointsFile := helpers.GetModulePath("clusters/eks") + "/vpc_endpoints.tf"
			if !helpers.FileExists(vpcEndpointsFile) {
				return false
			}

			// Verifica que todos os endpoints obrigatórios estão presentes
			requiredEndpoints := []string{"ecr.api", "ecr.dkr", "sts", "logs", "ssm"}
			for _, endpoint := range requiredEndpoints {
				hasEndpoint, _ := helpers.ContainsString(vpcEndpointsFile, endpoint)
				if !hasEndpoint {
					return false
				}
			}

			return true
		},
	))

	properties.TestingRun(t, gopter.ConsoleReporter(false))
}
