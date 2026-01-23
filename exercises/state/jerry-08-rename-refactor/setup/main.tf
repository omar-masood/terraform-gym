# Random suffixes for unique bucket names
resource "random_id" "suffix1" {
  byte_length = 4
}

resource "random_id" "suffix2" {
  byte_length = 4
}

# S3 Bucket 1 - Jerry will rename this to "application_data"
resource "aws_s3_bucket" "bucket1" {
  bucket = "app-bucket1-${var.student_name}-${random_id.suffix1.hex}"

  tags = {
    Name        = "Application Bucket"
    Environment = var.environment
    Purpose     = "Application Data Storage"
    ManagedBy   = "Terraform"
  }
}

# S3 Bucket 2 - Jerry will rename this to "user_uploads"
resource "aws_s3_bucket" "bucket2" {
  bucket = "app-bucket2-${var.student_name}-${random_id.suffix2.hex}"

  tags = {
    Name        = "Upload Bucket"
    Environment = var.environment
    Purpose     = "User Upload Storage"
    ManagedBy   = "Terraform"
  }
}

# Versioning for bucket1
resource "aws_s3_bucket_versioning" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Versioning for bucket2
resource "aws_s3_bucket_versioning" "bucket2" {
  bucket = aws_s3_bucket.bucket2.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encryption for bucket1
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Encryption for bucket2
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket2" {
  bucket = aws_s3_bucket.bucket2.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for bucket1
resource "aws_s3_bucket_public_access_block" "bucket1" {
  bucket = aws_s3_bucket.bucket1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Block public access for bucket2
resource "aws_s3_bucket_public_access_block" "bucket2" {
  bucket = aws_s3_bucket.bucket2.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
