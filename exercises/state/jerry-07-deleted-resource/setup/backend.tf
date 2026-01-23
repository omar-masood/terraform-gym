# S3 Backend Configuration
# This exercise uses S3 backend (more realistic for team scenarios)

terraform {
  backend "s3" {
    bucket = "terraform-gym-state"
    key    = "jerry-07-deleted-resource/terraform.tfstate"
    region = "us-east-1"

    # Note: Update this bucket name to match your actual state bucket
    # The simulate-jerry.sh script will help configure this
  }
}

# To use local backend instead (for testing):
# 1. Comment out the s3 backend above
# 2. Uncomment the local backend below
# 3. Run: terraform init -migrate-state

# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }
