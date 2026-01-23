# S3 Backend Configuration with Native Locking
#
# This exercise REQUIRES S3 backend to demonstrate remote locking.
#
# Before running terraform init, update terraform.tfvars with your state_bucket name.

terraform {
  backend "s3" {
    # Bucket name comes from -backend-config or terraform.tfvars
    # You can set this during init:
    #   terraform init -backend-config="bucket=your-bucket-name"
    #
    # Or uncomment and set directly:
    # bucket = "terraform-state-YOUR-ACCOUNT-ID"

    key          = "gym/state/jerry-02-remote-lock/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true

    # Native S3 locking (Terraform 1.9+)
    # Creates <key>.tflock file in S3 instead of using DynamoDB
    use_lockfile = true
  }
}

# Note: You'll need to provide the bucket name during init.
# See terraform.tfvars.example for the expected format.
