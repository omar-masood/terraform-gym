# Exercise 02: Variables and Outputs

terraform {
  required_version = ">= 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region # Using variable!
}

# TODO: Create resource using variables
# Use var.bucket_name, var.environment, var.enable_versioning

resource "aws_s3_bucket" "example" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = merge(
    var.common_tags,
    {
      Name = "Exercise 02 Bucket"
    }
  )
}

# TODO: Add versioning resource IF enable_versioning is true
# Hint: Use count = var.enable_versioning ? 1 : 0

# TODO: Complete outputs.tf with bucket details



