# Random suffix for unique bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

# S3 Bucket - Jerry will mess with these tags!
resource "aws_s3_bucket" "data" {
  bucket = "company-data-${var.student_name}-${random_id.suffix.hex}"

  tags = {
    Name        = "Company Data Bucket"
    Environment = var.environment  # Jerry changes this to "Production"
    ManagedBy   = "Terraform"      # Jerry removes this
    # Note: Jerry will ADD a "CostCenter" tag that doesn't exist here
  }
}

# Enable versioning (good practice)
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption (good practice)
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access (security best practice)
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
