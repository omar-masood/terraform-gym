# Jerry 06: Import Rescue
#
# This file is intentionally (almost) empty!
#
# Your task is to:
# 1. Discover what Jerry created (use AWS CLI)
# 2. Write Terraform configuration that matches the existing bucket
# 3. Import the bucket into Terraform state
# 4. Verify with `terraform plan` showing no changes
#
# Hints:
# - Jerry's bucket name follows pattern: jerry-prod-data-XXXXXX
# - Jerry enabled versioning (you'll need to import that too!)
# - Jerry added tags (your config must match them exactly)
# - Use `aws s3 ls | grep jerry` to find the bucket
# - Use `aws s3api get-bucket-versioning --bucket <name>` to check versioning
# - Use `aws s3api get-bucket-tagging --bucket <name>` to check tags
#
# Resources you'll need:
# - aws_s3_bucket
# - aws_s3_bucket_versioning
#
# Good luck! 🚀

# TODO: Write your Terraform configuration here
#
# Example structure:
#
# resource "aws_s3_bucket" "jerry_bucket" {
#   bucket = "???"  # Replace with actual bucket name from discovery
#
#   tags = {
#     # Match Jerry's tags exactly!
#   }
# }
#
# resource "aws_s3_bucket_versioning" "jerry_bucket" {
#   bucket = aws_s3_bucket.jerry_bucket.id
#
#   versioning_configuration {
#     status = "???"  # Enabled or Suspended?
#   }
# }
