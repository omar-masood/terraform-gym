# Jerry-07: Deleted Resource
# Infrastructure for the exercise

# Random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# Primary application data bucket (this one stays)
resource "aws_s3_bucket" "app_data" {
  bucket = "app-data-${random_id.suffix.hex}"

  tags = {
    Name        = "Application Data"
    Environment = "production"
    Purpose     = "Active application storage"
  }
}

resource "aws_s3_bucket_versioning" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Old logs bucket (Jerry will delete this one!)
resource "aws_s3_bucket" "old_logs" {
  bucket = "old-logs-${random_id.suffix.hex}"

  tags = {
    Name        = "Old Logs"
    Environment = "legacy"
    Purpose     = "Historical log storage"
    Status      = "deprecated"
  }
}

# Note: This bucket will be deleted by simulate-jerry.sh
# But it will still be in Terraform state!
# That's the whole point of this exercise.
