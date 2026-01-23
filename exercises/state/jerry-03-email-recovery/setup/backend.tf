# Local backend configuration
# This is what Jerry was using (the problem!)

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

# TODO: After recovering state, migrate to S3 backend for safety
# Uncomment and configure the below, then run: terraform init -migrate-state

# terraform {
#   backend "s3" {
#     bucket = "your-terraform-state-bucket"
#     key    = "jerry-recovery/terraform.tfstate"
#     region = "us-east-1"
#
#     # Optional but recommended: DynamoDB table for state locking
#     # dynamodb_table = "terraform-state-lock"
#   }
# }
