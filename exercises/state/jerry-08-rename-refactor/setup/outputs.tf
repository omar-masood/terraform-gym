# Bucket 1 outputs
output "bucket1_name" {
  description = "Name of the first S3 bucket (application data)"
  value       = aws_s3_bucket.bucket1.id
}

output "bucket1_arn" {
  description = "ARN of the first S3 bucket"
  value       = aws_s3_bucket.bucket1.arn
}

# Bucket 2 outputs
output "bucket2_name" {
  description = "Name of the second S3 bucket (user uploads)"
  value       = aws_s3_bucket.bucket2.id
}

output "bucket2_arn" {
  description = "ARN of the second S3 bucket"
  value       = aws_s3_bucket.bucket2.arn
}

# Region output
output "aws_region" {
  description = "AWS region where buckets are deployed"
  value       = var.aws_region
}

# Summary for easy reference
output "bucket_summary" {
  description = "Summary of created buckets"
  value = {
    bucket1 = aws_s3_bucket.bucket1.id
    bucket2 = aws_s3_bucket.bucket2.id
    region  = var.aws_region
  }
}
