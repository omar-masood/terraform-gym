# Exercise 04: Pokemon VM Squad with for_each (EC2 Version)
#
# Create EC2 instances named after Pokemon using for_each!
# This approach is MORE STABLE than count - removing a Pokemon
# only destroys that specific instance!
#
# Your mission:
# 1. Use a map variable for Pokemon data
# 2. Fetch Pokemon data from the API using for_each
# 3. Create an EC2 instance for each Pokemon
# 4. Access instances by name, not index!

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

# TODO: This is the key difference from Exercise 03!
# Instead of a list of IDs, we use a map keyed by Pokemon name
variable "pokemon" {
  description = "Map of Pokemon to create instances for"
  type = map(object({
    id   = number
    type = string
  }))
  default = {
    bulbasaur  = { id = 1, type = "grass" }
    charmander = { id = 4, type = "fire" }
    squirtle   = { id = 7, type = "water" }
  }
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

# TODO: Fetch Pokemon data using for_each instead of count!
# Hint: for_each = var.pokemon
# Hint: Use each.value.id in the URL
# Hint: Access with each.key (the Pokemon name)
data "http" "pokemon" {
  # YOUR CODE HERE - use for_each!
  for_each = {}  # Replace with var.pokemon

  url = "https://pokeapi.co/api/v2/pokemon/1"  # Replace with dynamic URL using each.value.id

  request_headers = {
    Accept = "application/json"
  }
}

# ============================================================================
# LOCALS - Parse the Pokemon data
# ============================================================================

locals {
  # TODO: Parse each Pokemon response into HCL objects
  # With for_each, we get a MAP not a LIST
  # The key is the Pokemon name, value is the parsed data
  pokemon_data = {
    # Hint: for name, response in data.http.pokemon : name => jsondecode(response.response_body)
  }

  # TODO: Extract HP for each Pokemon (as a map)
  pokemon_hp = {
    # Hint: for name, p in local.pokemon_data : name => [for s in p.stats : s.base_stat if s.stat.name == "hp"][0]
  }
}

# ============================================================================
# EC2 INSTANCES - One per Pokemon!
# ============================================================================

# TODO: Create EC2 instances using for_each
resource "aws_instance" "pokemon" {
  # YOUR CODE HERE - use for_each!
  for_each = {}  # Replace with var.pokemon

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tags = {
    # TODO: Use each.key for the Pokemon name!
    Name = "pokemon-placeholder"  # Replace: "pokemon-${each.key}"

    # TODO: Use each.value for the Pokemon data from the variable
    # PokemonID   = each.value.id
    # PokemonType = each.value.type

    # TODO: Use local.pokemon_hp[each.key] for the HP from API
    # PokemonHP   = local.pokemon_hp[each.key]

    Trainer      = var.student_name
    AutoTeardown = "2h"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

# Uncomment these outputs once your resources are working:

# output "squad_roster" {
#   description = "Your Pokemon squad!"
#   value = {
#     for name, instance in aws_instance.pokemon : name => {
#       pokemon_name = name
#       pokemon_type = var.pokemon[name].type
#       instance_id  = instance.id
#       private_ip   = instance.private_ip
#     }
#   }
# }

# output "pokemon_names" {
#   description = "Names of all Pokemon in your squad"
#   value       = keys(aws_instance.pokemon)
# }

# output "instance_ids" {
#   description = "Map of Pokemon names to EC2 instance IDs"
#   value       = { for name, instance in aws_instance.pokemon : name => instance.id }
# }

# Access a specific Pokemon!
# output "charmander_instance" {
#   description = "Charmander's instance details"
#   value       = aws_instance.pokemon["charmander"].id
# }
