package helpers

import (
	"reflect"

	"github.com/leanovate/gopter"
	"github.com/leanovate/gopter/gen"
)

// GenEnvironment gera nomes de ambiente válidos
func GenEnvironment() gopter.Gen {
	return gen.OneConstOf("staging", "prod")
}

// GenAZCount gera número de availability zones (2-4)
func GenAZCount() gopter.Gen {
	return gen.IntRange(2, 4)
}

// GenVPCCIDR gera CIDRs válidos para VPC
func GenVPCCIDR() gopter.Gen {
	return gen.OneConstOf(
		"10.0.0.0/16",
		"10.1.0.0/16",
		"10.2.0.0/16",
		"172.16.0.0/16",
		"192.168.0.0/16",
	)
}

// GenKubernetesVersion gera versões válidas do Kubernetes
func GenKubernetesVersion() gopter.Gen {
	return gen.OneConstOf(
		"1.24", "1.25", "1.26", "1.27", "1.28", "1.29", "1.30",
	)
}

// GenInstanceType gera tipos de instância EC2 válidos
func GenInstanceType() gopter.Gen {
	return gen.OneConstOf(
		"t3.medium", "t3.large", "t3.xlarge",
		"m5.large", "m5.xlarge", "m5.2xlarge",
	)
}

// GenNodeGroupSize gera tamanhos válidos para node groups
func GenNodeGroupSize() gopter.Gen {
	return gen.IntRange(1, 10)
}

// GenRetentionDays gera dias de retenção válidos
func GenRetentionDays() gopter.Gen {
	return gen.OneConstOf(1, 3, 5, 7, 14, 30, 60, 90)
}

// GenPolicyEngine gera engines de política válidos
func GenPolicyEngine() gopter.Gen {
	return gen.OneConstOf("kyverno", "gatekeeper")
}

// GenEnforcementMode gera modos de enforcement válidos
func GenEnforcementMode() gopter.Gen {
	return gen.OneConstOf("audit", "enforce")
}

// GenIngressType gera tipos de ingress válidos
func GenIngressType() gopter.Gen {
	return gen.OneConstOf("alb", "nginx")
}

// NodeGroupConfig representa configuração de um node group
type NodeGroupConfig struct {
	InstanceTypes []string
	MinSize       int
	MaxSize       int
	DesiredSize   int
	DiskSize      int
	Labels        map[string]string
	Taints        []Taint
}

// Taint representa um taint do Kubernetes
type Taint struct {
	Key    string
	Value  string
	Effect string
}

// GenNodeGroup gera configurações válidas de node group
func GenNodeGroup() gopter.Gen {
	return gen.Struct(reflect.TypeOf(&NodeGroupConfig{}), map[string]gopter.Gen{
		"InstanceTypes": gen.SliceOf(GenInstanceType(), reflect.TypeOf("")),
		"MinSize":       gen.IntRange(1, 5),
		"MaxSize":       gen.IntRange(5, 50),
		"DesiredSize":   gen.IntRange(2, 10),
		"DiskSize":      gen.IntRange(20, 500),
		"Labels": gen.MapOf(
			gen.Identifier(),
			gen.Identifier(),
		),
		"Taints": gen.SliceOf(GenTaint(), reflect.TypeOf(Taint{})),
	}).SuchThat(func(v interface{}) bool {
		ng := v.(*NodeGroupConfig)
		return ng.MinSize <= ng.DesiredSize &&
			ng.DesiredSize <= ng.MaxSize &&
			len(ng.InstanceTypes) > 0
	})
}

// GenTaint gera taints válidos
func GenTaint() gopter.Gen {
	return gen.Struct(reflect.TypeOf(&Taint{}), map[string]gopter.Gen{
		"Key":    gen.Identifier(),
		"Value":  gen.AlphaString(),
		"Effect": gen.OneConstOf("NoSchedule", "PreferNoSchedule", "NoExecute"),
	})
}

// GenBool gera valores booleanos
func GenBool() gopter.Gen {
	return gen.Bool()
}

// GenPositiveInt gera inteiros positivos
func GenPositiveInt(max int) gopter.Gen {
	return gen.IntRange(1, max)
}
