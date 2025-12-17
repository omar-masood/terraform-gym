# Exercise 01: Terraform Basics
# Your first Terraform configuration!

# TODO: Add terraform block
# Required version: >= 1.9.0
# Required provider: aws from hashicorp/aws, version ~> 5.0

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# TODO: Add provider block for AWS
#Region: us-east-1

provider "aws" {
  region = "us-east-1"
}

# TODO: Add resource block for S3 bucket
# Resource type: aws_s3_bucket
# Resource name: my_first_bucket
# Bucket name: terraform-gym-first-YOURNAME (must be globally unique!)
# Add tags: Name, Environment, ManagedBy

resource "aws_s3_bucket" "my_first_bucket" {
  bucket = "my-meraj-bucket-2023"

  tags = {
    Name        = "my bucket"
    Environment = "prod"
    ManagedBy   = "aws"
  }
}

# After completing:
# 1. Run: terraform init
# 2. Run: terraform fmt
# 3. Run: terraform validate
# 4. Run: terraform plan
# 5. Run: terraform apply
# 6. Verify in AWS Console or: aws s3 ls
# 7. Run: terraform destroy
