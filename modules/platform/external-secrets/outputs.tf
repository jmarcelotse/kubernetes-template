output "namespace" {
  description = "Namespace onde External Secrets Operator foi instalado"
  value       = kubernetes_namespace.external_secrets.metadata[0].name
}

output "service_account_name" {
  description = "Nome da service account do External Secrets Operator"
  value       = var.service_account_name
}

output "service_account_role_arn" {
  description = "ARN da IAM role para service account"
  value       = aws_iam_role.external_secrets.arn
}

output "cluster_secret_store_name" {
  description = "Nome do ClusterSecretStore para Secrets Manager"
  value       = "aws-secrets-manager"
}

output "cluster_secret_store_ssm_name" {
  description = "Nome do ClusterSecretStore para Parameter Store"
  value       = "aws-parameter-store"
}
