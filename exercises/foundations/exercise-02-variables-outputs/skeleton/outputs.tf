# Outputs for Exercise 02

# TODO: Add output for bucket name
output "bucket_name" {
  description = "bucket name"
  value       = var.bucket_name
}

# TODO: Add output for bucket ARN

output "bucket_arn" {
  description = "bucket arn"
  value       = aws_s3_bucket.example.arn
}

# TODO: Add output for bucket region

output "bucket_region" {
  description = "bucket region"
  value       = var.aws_region
}
# TODO: Add output for all tags (mark as sensitive for practice)

output "bucket_tags" {
  description = "bucket tags"
  value = merge(
    var.common_tags,
    {
      Name = "Exercise 02 Bucket"
  })
  sensitive = true

}
