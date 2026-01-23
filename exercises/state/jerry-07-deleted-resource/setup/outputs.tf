output "app_data_bucket" {
  description = "Name of the application data bucket (active)"
  value       = aws_s3_bucket.app_data.id
}

output "app_data_bucket_arn" {
  description = "ARN of the application data bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "old_logs_bucket" {
  description = "Name of the old logs bucket (Jerry will delete this)"
  value       = aws_s3_bucket.old_logs.id
}

output "old_logs_bucket_arn" {
  description = "ARN of the old logs bucket"
  value       = aws_s3_bucket.old_logs.arn
}

output "versioning_status" {
  description = "Versioning status of app_data bucket"
  value       = aws_s3_bucket_versioning.app_data.versioning_configuration[0].status
}
