# Outputs for Jerry-05: Config Drift Exercise

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.important_data.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.important_data.arn
}

output "bucket_region" {
  description = "Region where the bucket is located"
  value       = aws_s3_bucket.important_data.region
}

output "versioning_status" {
  description = "Current versioning status (from Terraform's perspective)"
  value       = aws_s3_bucket_versioning.important_data.versioning_configuration[0].status
}

output "encryption_algorithm" {
  description = "Server-side encryption algorithm (from Terraform's perspective)"
  value       = aws_s3_bucket_server_side_encryption_configuration.important_data.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

output "check_actual_config_commands" {
  description = "Commands to check actual AWS configuration (vs Terraform state)"
  value = {
    versioning = "aws s3api get-bucket-versioning --bucket ${aws_s3_bucket.important_data.id}"
    encryption = "aws s3api get-bucket-encryption --bucket ${aws_s3_bucket.important_data.id}"
    public_access = "aws s3api get-public-access-block --bucket ${aws_s3_bucket.important_data.id}"
  }
}

output "important_note" {
  description = "Important reminder about Terraform state vs actual configuration"
  value = <<-EOT

  ⚠️  IMPORTANT: These outputs show what Terraform THINKS the configuration is
  (based on state). After Jerry's changes, the ACTUAL AWS configuration will differ.

  Always verify drift with: terraform plan

  Check actual AWS config with the commands in 'check_actual_config_commands' output.
  EOT
}
