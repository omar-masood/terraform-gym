# =============================================================================
# S3 WEBSITE MODULE - INPUT VARIABLES
# =============================================================================

variable "bucket_name" {
  description = "Name of the S3 bucket for the static website"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must start and end with a letter or number."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket (recommended for prod)"
  type        = bool
  default     = false
}

variable "site_content" {
  description = "Content configuration for the website"
  type = object({
    heading          = string
    message          = string
    background_color = string
    badge_color      = string
  })

  default = {
    heading          = "Welcome"
    message          = "This site is under construction."
    background_color = "#f5f5f5"
    badge_color      = "#666666"
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
