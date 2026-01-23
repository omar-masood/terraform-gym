# Backend Configuration
#
# This exercise uses S3 backend (recommended for rename scenarios)
#
# SETUP INSTRUCTIONS:
# 1. Create an S3 bucket for Terraform state (if you don't have one):
#    aws s3 mb s3://terraform-state-YOUR-ACCOUNT-ID
#
# 2. Update the bucket name below to match your state bucket
#
# 3. Uncomment the backend configuration below
#
# For local backend (simpler but less realistic), comment out the terraform block below

terraform {
  backend "s3" {
    bucket       = "terraform-state-gym"  # Update with your bucket name
    key          = "gym/state/jerry-08-rename-refactor/terraform.tfstate"
    region       = "us-east-1"            # Update if using different region
    encrypt      = true
    use_lockfile = true
  }
}

# Alternative: Local backend (uncomment if you don't want to use S3)
# Note: Local backend is simpler but doesn't demonstrate team scenarios
#
# Just comment out the terraform block above to use local backend
