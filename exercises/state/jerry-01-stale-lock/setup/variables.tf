variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "student_id" {
  description = "Your unique student identifier (GitHub username)"
  type        = string
}
