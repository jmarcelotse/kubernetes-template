output "audit_logs_bucket_name" {
  description = "Nome do bucket S3 para logs de auditoria"
  value       = aws_s3_bucket.audit_logs.id
}

output "audit_logs_bucket_arn" {
  description = "ARN do bucket S3 para logs de auditoria"
  value       = aws_s3_bucket.audit_logs.arn
}

output "cloudtrail_id" {
  description = "ID do CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].id : null
}

output "cloudtrail_arn" {
  description = "ARN do CloudTrail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "config_recorder_id" {
  description = "ID do AWS Config Recorder"
  value       = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
}

output "guardduty_detector_id" {
  description = "ID do GuardDuty Detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}
