terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend (no remote state for this exercise)
  # This makes it easier to demonstrate local locking
}

provider "aws" {
  region = var.aws_region
}

# Simple S3 bucket for demonstration
resource "aws_s3_bucket" "demo" {
  bucket = "jerry-lock-demo-${var.student_id}"

  tags = {
    Name        = "Jerry Lock Demo"
    Environment = "Learning"
    ManagedBy   = "Terraform"
    Exercise    = "jerry-01-stale-lock"
  }
}

resource "aws_s3_bucket_versioning" "demo" {
  bucket = aws_s3_bucket.demo.id

  versioning_configuration {
    status = "Enabled"
  }
}
