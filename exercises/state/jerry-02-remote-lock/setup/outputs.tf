# Outputs for Jerry 02: Remote Lock

output "bucket_name" {
  description = "Name of the test S3 bucket"
  value       = aws_s3_bucket.test.id
}

output "bucket_arn" {
  description = "ARN of the test S3 bucket"
  value       = aws_s3_bucket.test.arn
}

output "state_bucket" {
  description = "S3 bucket storing Terraform state"
  value       = var.state_bucket
}

output "state_key" {
  description = "S3 key for the state file"
  value       = "gym/state/jerry-02-remote-lock/terraform.tfstate"
}

output "lock_file_path" {
  description = "S3 path where lock file would be created"
  value       = "s3://${var.state_bucket}/gym/state/jerry-02-remote-lock/terraform.tfstate.tflock"
}
