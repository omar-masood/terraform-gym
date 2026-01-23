variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name (will be set by simulate-jerry.sh)"
  type        = string
  default     = "jerry-important-data-PLACEHOLDER"

  # This will be overwritten by simulate-jerry.sh with a unique name
  # DO NOT manually set this value
}
