# Backend Configuration
#
# This exercise uses local state by default for simplicity.
# In production, you should use remote state with locking (S3 + DynamoDB).
#
# To use remote state, uncomment and configure the backend block below:

# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "terraform-gym/jerry-05-config-drift/terraform.tfstate"
#     region         = "us-west-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-locks"
#   }
# }

# For this exercise, we're using local state stored in:
# ./terraform.tfstate
#
# This makes it easier to simulate Jerry's chaos and reset the exercise.
