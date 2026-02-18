output "namespace" {
  description = "Namespace onde Velero foi instalado"
  value       = kubernetes_namespace.velero.metadata[0].name
}

output "backup_bucket_name" {
  description = "Nome do bucket S3 para backups"
  value       = aws_s3_bucket.velero_backups.id
}

output "backup_bucket_arn" {
  description = "ARN do bucket S3 para backups"
  value       = aws_s3_bucket.velero_backups.arn
}

output "service_account_role_arn" {
  description = "ARN da IAM role para service account"
  value       = aws_iam_role.velero.arn
}

output "backup_schedule" {
  description = "Schedule configurado para backups"
  value       = var.backup_schedule
}

output "backup_retention_days" {
  description = "Dias de retenção de backups"
  value       = var.backup_retention_days
}
