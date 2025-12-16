# Exercise 05: Dynamic Types - Port Power! (EC2 Version) - STARTER
#
# Create security group rules dynamically based on Pokemon types!
# Each type opens a different port (fire=8080, water=8081, etc.)

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ============================================================================
# VARIABLES
# ============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "student_name" {
  description = "Your name/username for resource naming"
  type        = string
  default     = "pokemon-trainer"
}

# TODO: Define a pokemon variable as a map
# Use the same structure as Exercise 04!
# Example: bulbasaur = { id = 1, type = "grass" }
variable "pokemon" {
  description = "Map of Pokemon to analyze for types"
  type = map(object({
    id   = number
    type = string
  }))
  default = {
    # TODO: Add your Pokemon team here (at least 3)
    # Hint: Choose Pokemon with different types for best effect!
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# TODO: Fetch Pokemon data from the API using for_each
# Hint: Use the pattern from Exercise 04
data "http" "pokemon" {
  # TODO: Add for_each here
  # TODO: Set the URL

  request_headers = {
    Accept = "application/json"
  }
}

# ============================================================================
# LOCALS
# ============================================================================

locals {
  # TODO: Parse the Pokemon API responses
  pokemon_data = {
    # Hint: Use jsondecode() on each response
  }

  # TODO: Extract types for each Pokemon
  # Hint: Pokemon have a "types" array in the API response
  # Each type is in: p.types[*].type.name
  pokemon_types = {
    # TODO: Create a map of pokemon_name => list_of_types
  }

  # TODO: Flatten all types into a single list
  all_types = [
    # Hint: Use flatten() and values()
  ]

  # TODO: Get unique types only
  # Hint: Use toset() to remove duplicates
  unique_types = []

  # Pokemon Type → Port Mapping
  # Each type gets a unique port!
  type_ports = {
    fire     = 8080 # Hot port for Fire types
    water    = 8081 # Flows through
    electric = 443  # High voltage (HTTPS)
    grass    = 80   # Grows anywhere (HTTP)
    normal   = 22   # Basic SSH
    psychic  = 8443 # Mind-bending secure
    ghost    = 666  # Spooky!
    dragon   = 9000 # Over 9000!
    fighting = 3000 # Battle port
    flying   = 8888 # Up in the air
    poison   = 5432 # Database port (it spreads!)
    ground   = 8082 # Down to earth
    rock     = 8083 # Solid foundation
    bug      = 8084 # Debug port
    ice      = 8085 # Cool port
    fairy    = 8086 # Magical
    steel    = 8087 # Reinforced
    dark     = 8088 # Shadow port
  }
}

# ============================================================================
# SECURITY GROUP WITH DYNAMIC RULES
# ============================================================================

# TODO: Create a security group with dynamic ingress rules
resource "aws_security_group" "pokemon_types" {
  # TODO: Add name and description

  # TODO: Add a dynamic "ingress" block
  # - for_each should iterate over unique_types
  # - Use lookup() to map types to ports (default: 8000)
  # - Add description mentioning the Pokemon type
  # - Set protocol to "tcp", cidr_blocks to ["0.0.0.0/0"]

  # Always allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "pokemon-types-sg-${var.student_name}"
    Purpose     = "Dynamic rules based on Pokemon types"
    Trainer     = var.student_name
    Environment = "pokemon-gym"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

# TODO: Output the security group ID
output "security_group_id" {
  description = "The ID of the Pokemon types security group"
  value       = "" # TODO
}

# TODO: Output all unique types found
output "pokemon_types_found" {
  description = "All unique Pokemon types in your team"
  value       = [] # TODO
}

# TODO: Output the type → port mapping
output "type_port_mapping" {
  description = "Which port each Pokemon type opens"
  value = {
    # TODO: Create a map showing each unique type and its port
    # Hint: Use a for expression with lookup()
  }
}

# TODO: Output a summary of Pokemon and their types
output "pokemon_summary" {
  description = "Summary of your Pokemon team and their types"
  value = {
    # TODO: Create a map showing each Pokemon and its types
  }
}

# TODO: STRETCH GOAL - Add a count of how many rules were created
# output "rules_created" { ... }
