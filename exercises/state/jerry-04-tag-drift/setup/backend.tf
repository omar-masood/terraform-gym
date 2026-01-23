# Backend Configuration
# 
# This exercise uses local backend by default.
# For S3 backend (more realistic), uncomment below and update values:
#
# terraform {
#   backend "s3" {
#     bucket       = "terraform-state-YOUR-ACCOUNT-ID"
#     key          = "gym/state/jerry-04-tag-drift/terraform.tfstate"
#     region       = "us-east-1"
#     encrypt      = true
#     use_lockfile = true
#   }
# }
