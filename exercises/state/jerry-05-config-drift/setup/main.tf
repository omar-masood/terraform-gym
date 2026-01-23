# Jerry-05: Config Drift - S3 Bucket with Security Settings
#
# This configuration creates an S3 bucket with:
# - Versioning enabled (protects against accidental deletes)
# - Server-side encryption (AES256)
# - Public access blocked
# - Proper tagging
#
# Jerry will disable versioning and encryption via AWS Console,
# creating configuration drift that affects security.

# Random suffix to ensure unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# The S3 bucket itself
resource "aws_s3_bucket" "important_data" {
  bucket = "important-data-${var.student_name}-${random_id.suffix.hex}"

  tags = {
    Name        = "Important Data Bucket"
    Purpose     = "Stores critical application data"
    DataClass   = "confidential"
    Compliance  = "required"
  }
}

# Versioning configuration
# This protects against accidental deletes and overwrites
# Jerry will SUSPEND this via the Console
resource "aws_s3_bucket_versioning" "important_data" {
  bucket = aws_s3_bucket.important_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption configuration
# This encrypts data at rest using AES256
# Jerry will DELETE this via the Console
resource "aws_s3_bucket_server_side_encryption_configuration" "important_data" {
  bucket = aws_s3_bucket.important_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Public access block
# This prevents accidental public exposure
# Jerry will NOT touch this (thankfully)
resource "aws_s3_bucket_public_access_block" "important_data" {
  bucket = aws_s3_bucket.important_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rule (optional - for demonstration)
# Shows that not everything Jerry could touch, he did
resource "aws_s3_bucket_lifecycle_configuration" "important_data" {
  bucket = aws_s3_bucket.important_data.id

  rule {
    id     = "archive-old-versions"
    status = "Enabled"

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
