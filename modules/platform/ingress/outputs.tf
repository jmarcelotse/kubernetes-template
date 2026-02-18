output "namespace_ingress" {
  description = "Namespace onde ingress controller foi instalado"
  value       = kubernetes_namespace.ingress.metadata[0].name
}

output "namespace_cert_manager" {
  description = "Namespace onde cert-manager foi instalado"
  value       = kubernetes_namespace.cert_manager.metadata[0].name
}

output "namespace_external_dns" {
  description = "Namespace onde external-dns foi instalado"
  value       = kubernetes_namespace.external_dns.metadata[0].name
}

output "ingress_type" {
  description = "Tipo de ingress controller instalado"
  value       = var.ingress_type
}

output "ingress_class" {
  description = "IngressClass a usar em recursos Ingress"
  value       = var.ingress_type == "alb" ? "alb" : "nginx"
}

output "cluster_issuer_name" {
  description = "Nome do ClusterIssuer para certificados TLS"
  value       = "letsencrypt-${var.letsencrypt_environment}"
}

output "alb_controller_role_arn" {
  description = "ARN da IAM role do AWS Load Balancer Controller"
  value       = var.ingress_type == "alb" ? aws_iam_role.alb_controller[0].arn : null
}

output "external_dns_role_arn" {
  description = "ARN da IAM role do external-dns"
  value       = aws_iam_role.external_dns.arn
}
