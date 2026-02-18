# ============================================================================
# VPC Endpoints para Serviços AWS
# ============================================================================
# VPC Endpoints permitem que recursos na VPC acessem serviços AWS sem passar
# pela internet, reduzindo custos de tráfego e melhorando segurança.
# ============================================================================

locals {
  # Mapa de VPC endpoints a criar quando habilitado
  vpc_endpoints = var.enable_vpc_endpoints ? {
    ecr_api = {
      service             = "ecr.api"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    ecr_dkr = {
      service             = "ecr.dkr"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    sts = {
      service             = "sts"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    logs = {
      service             = "logs"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      private_dns_enabled = true
    }
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = false
    }
  } : {}
}

# ----------------------------------------------------------------------------
# VPC Endpoints do Tipo Interface
# ----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "interface" {
  for_each = {
    for name, config in local.vpc_endpoints :
    name => config
    if config.service_type == "Interface"
  }

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${local.region}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = each.value.private_dns_enabled

  subnet_ids = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints[0].id
  ]

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-${each.key}-endpoint"
      Service = each.value.service
    }
  )
}

# ----------------------------------------------------------------------------
# VPC Endpoint do Tipo Gateway (S3)
# ----------------------------------------------------------------------------

resource "aws_vpc_endpoint" "gateway" {
  for_each = {
    for name, config in local.vpc_endpoints :
    name => config
    if config.service_type == "Gateway"
  }

  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${local.region}.${each.value.service}"
  vpc_endpoint_type = "Gateway"

  route_table_ids = concat(
    [aws_route_table.public.id],
    aws_route_table.private[*].id
  )

  tags = merge(
    var.tags,
    {
      Name    = "${var.cluster_name}-${each.key}-endpoint"
      Service = each.value.service
    }
  )
}

# ----------------------------------------------------------------------------
# Data Source para Região Atual
# ----------------------------------------------------------------------------

data "aws_region" "current" {}

# Usar o ID da região ao invés de name (deprecated)
locals {
  region = data.aws_region.current.id
}
