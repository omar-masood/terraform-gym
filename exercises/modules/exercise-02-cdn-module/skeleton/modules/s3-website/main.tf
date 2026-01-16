# =============================================================================
# S3 STATIC WEBSITE MODULE
# =============================================================================
# This module creates an S3 bucket configured for static website hosting
# with encryption enforced and optional versioning.
# =============================================================================

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  # Default tags that every resource should have
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-website"
  }

  # Merge default tags with any additional tags passed in
  # User-provided tags override defaults if there's a conflict
  all_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}

# -----------------------------------------------------------------------------
# Website Configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# -----------------------------------------------------------------------------
# Public Access Settings
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------------------------------------------------------
# Bucket Policy - Allow Public Read
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  # Must wait for public access block to be configured
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Server-Side Encryption (ENFORCED - Always On)
# -----------------------------------------------------------------------------
# Security requirement: All buckets must have encryption enabled.
# This is NOT configurable because compliance is not optional.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# -----------------------------------------------------------------------------
# Versioning (Optional - Configurable)
# -----------------------------------------------------------------------------
# Versioning is recommended for production but optional for dev/staging.
# Controlled by the enable_versioning variable.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# -----------------------------------------------------------------------------
# Website Content
# -----------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile("${path.module}/templates/index.html.tftpl", {
    environment      = var.environment
    heading          = var.site_content.heading
    message          = var.site_content.message
    background_color = var.site_content.background_color
    badge_color      = var.site_content.badge_color
  })

  # Ensure bucket policy is in place before uploading
  depends_on = [aws_s3_bucket_policy.this]
}
