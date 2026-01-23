# Jerry's S3 Infrastructure Configuration
# This configuration matches the resources in jerry-backup.tfstate

# NOTE: The bucket name will be set by simulate-jerry.sh
# DO NOT manually edit this file before running the simulation

resource "aws_s3_bucket" "important_data" {
  bucket = var.bucket_name  # Will be set to match the state file

  tags = {
    Name        = "Jerry Important Data"
    Owner       = "jerry"
    Environment = "production"
  }
}

resource "aws_s3_bucket_versioning" "important_data" {
  bucket = aws_s3_bucket.important_data.id

  versioning_configuration {
    status = "Enabled"
  }
}
