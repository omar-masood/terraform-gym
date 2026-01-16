# =============================================================================
# S3 WEBSITE MODULE - OUTPUTS
# =============================================================================

output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "website_endpoint" {
  description = "The website endpoint (without protocol)"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "website_url" {
  description = "The full website URL (with http://)"
  value       = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}
