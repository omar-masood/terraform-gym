# Simple S3 bucket for testing state locking
#
# This creates a basic S3 bucket so we have infrastructure to manage.
# The focus is on the state locking, not the bucket itself.

# Random suffix for unique bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 bucket
resource "aws_s3_bucket" "test" {
  bucket = "jerry-02-test-${var.student_name}-${random_id.suffix.hex}"

  tags = {
    Name        = "Jerry 02 Test Bucket"
    Environment = "Learning"
    Exercise    = "jerry-02-remote-lock"
    ManagedBy   = "Terraform"
  }
}

# Enable versioning (best practice)
resource "aws_s3_bucket_versioning" "test" {
  bucket = aws_s3_bucket.test.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
