output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.important_data.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.important_data.arn
}

output "versioning_status" {
  description = "Versioning status of the bucket"
  value       = aws_s3_bucket_versioning.important_data.versioning_configuration[0].status
}
