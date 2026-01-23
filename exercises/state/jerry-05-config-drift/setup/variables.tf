# Variables for Jerry-05: Config Drift Exercise

variable "student_name" {
  description = "Your name (used for bucket naming and tagging)"
  type        = string

  validation {
    condition     = length(var.student_name) > 0 && length(var.student_name) <= 20
    error_message = "Student name must be between 1 and 20 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.student_name))
    error_message = "Student name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-west-2)."
  }
}
