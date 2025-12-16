# Challenge: Pokedex Infrastructure - STARTER
# Variables File

# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

variable "aws_region" {
  description = "AWS region (EC2 path only)"
  type        = string
  default     = "us-east-1"
}

# ============================================================================
# TRAINER INFORMATION
# ============================================================================

variable "student_name" {
  description = "Your name/username - the Pokemon Trainer!"
  type        = string

  # TODO: Add validation to ensure name is not empty
  # validation {
  #   condition     = ...
  #   error_message = "Trainer name cannot be empty!"
  # }
}

# ============================================================================
# POKEMON TEAM
# ============================================================================

# TODO: Define the pokemon_team variable
# Requirements:
# - Type: list(object({ name = string, id = number }))
# - Add validation for team size (1-6 Pokemon)
# - Add validation for Pokemon IDs (1-1010)
# - Add validation for Pokemon names (lowercase, no spaces)
#
# Hint: Use alltrue(), can(), regex(), and length()

# variable "pokemon_team" {
#   description = "Your Pokemon team! (1-6 Pokemon)"
#   type        = ...
#
#   validation {
#     # TODO: Team size must be 1-6
#   }
#
#   validation {
#     # TODO: Pokemon IDs must be 1-1010
#   }
#
#   validation {
#     # TODO: Pokemon names must be lowercase with no spaces
#   }
# }

# ============================================================================
# DEPLOYMENT CONFIGURATION
# ============================================================================

variable "deployment_path" {
  description = "Choose 'ec2' or 'docker'"
  type        = string
  default     = "docker" # Change to "ec2" if using AWS

  validation {
    condition     = contains(["ec2", "docker"], var.deployment_path)
    error_message = "deployment_path must be 'ec2' or 'docker'."
  }
}

variable "instance_type" {
  description = "EC2 instance type (EC2 path only)"
  type        = string
  default     = "t3.micro"
}

variable "docker_image" {
  description = "Docker image to use (Docker path only)"
  type        = string
  default     = "nginx:alpine"
}

# ============================================================================
# TAGS / LABELS
# ============================================================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "pokemon-gym"
}

variable "auto_teardown" {
  description = "Tag to indicate resources should be auto-torn down"
  type        = string
  default     = "2h"
}
