# Input variables for Jerry 02: Remote Lock

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "student_name" {
  description = "Your name (used for unique resource names)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.student_name))
    error_message = "Student name must be lowercase letters, numbers, and hyphens only."
  }
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state (must already exist)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket))
    error_message = "Invalid S3 bucket name format."
  }
}
