# Exercise 03: Pokemon VM Squad (EC2 Version)
#
# Create EC2 instances named after Pokemon using count!
#
# Your mission:
# 1. Fetch Pokemon data from the API for each ID
# 2. Create an EC2 instance for each Pokemon
# 3. Name each instance after its Pokemon
# 4. Tag with Pokemon metadata

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

variable "pokemon_ids" {
  description = "List of Pokemon IDs to create instances for"
  type        = list(number)
  default     = [1, 4, 7]  # Bulbasaur, Charmander, Squirtle - the OG starters!
}

variable "student_name" {
  description = "Your name/username for resource naming"
  type        = string
  default     = "pokemon-trainer"
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# Get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-kernel-*-x86_64"]
  }
}

# TODO: Fetch Pokemon data for EACH Pokemon ID
# Hint: Use count = length(var.pokemon_ids)
# Hint: Use var.pokemon_ids[count.index] in the URL
data "http" "pokemon" {
  # YOUR CODE HERE
  count = 0  # Replace with correct count

  url = "https://pokeapi.co/api/v2/pokemon/1"  # Replace with dynamic URL

  request_headers = {
    Accept = "application/json"
  }
}

# ============================================================================
# LOCALS - Parse the Pokemon data
# ============================================================================

locals {
  # TODO: Parse each Pokemon response into HCL objects
  # This should be a list of Pokemon data objects
  pokemon_data = [
    # Hint: for i, response in data.http.pokemon : jsondecode(response.response_body)
  ]

  # TODO: Extract just the names as a simple list
  pokemon_names = [
    # Hint: for p in local.pokemon_data : p.name
  ]

  # TODO: Extract types for each Pokemon
  pokemon_types = [
    # Hint: for p in local.pokemon_data : [for t in p.types : t.type.name]
  ]
}

# ============================================================================
# EC2 INSTANCES - One per Pokemon!
# ============================================================================

# TODO: Create EC2 instances using count
resource "aws_instance" "pokemon" {
  # YOUR CODE HERE
  count = 0  # Replace with correct count

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    # TODO: Set Name tag to "pokemon-{pokemon_name}"
    Name = "pokemon-placeholder"  # Replace with dynamic name

    # TODO: Add these tags with correct values:
    # PokemonID   = the Pokemon's ID from the API
    # PokemonType = the Pokemon's primary type
    # Trainer     = var.student_name
    # AutoTeardown = "2h"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

# Uncomment these outputs once your resources are working:

# output "squad_roster" {
#   description = "Your Pokemon squad!"
#   value = [
#     for i, instance in aws_instance.pokemon : {
#       name        = local.pokemon_names[i]
#       instance_id = instance.id
#       private_ip  = instance.private_ip
#     }
#   ]
# }

# output "pokemon_names" {
#   description = "Names of all Pokemon in your squad"
#   value       = local.pokemon_names
# }

# output "instance_ids" {
#   description = "EC2 instance IDs"
#   value       = aws_instance.pokemon[*].id
# }
