# =============================================================================
# ROOT MODULE - VARIABLES
# =============================================================================

variable "unique_suffix" {
  description = "Unique suffix for bucket names (use your name or a random string)"
  type        = string

  validation {
    condition     = length(var.unique_suffix) >= 3 && length(var.unique_suffix) <= 20
    error_message = "Unique suffix must be between 3 and 20 characters."
  }
}
