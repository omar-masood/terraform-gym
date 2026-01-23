variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "student_name" {
  description = "Your name or GitHub username (used for unique bucket naming)"
  type        = string
  default     = "student"
}

variable "environment" {
  description = "Environment tag for resources"
  type        = string
  default     = "Learning"
}
