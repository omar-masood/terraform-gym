# =============================================================================
# CDN MODULE - OUTPUTS
# =============================================================================

output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cdn_url" {
  description = "The HTTPS URL of the CDN"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}
