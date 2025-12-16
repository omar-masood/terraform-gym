# Challenge: Pokedex Infrastructure - STARTER
# Main Terraform Configuration

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Provider configuration - only one will be used based on deployment_path
provider "aws" {
  region = var.aws_region
}

provider "docker" {}

# ============================================================================
# DATA SOURCES - FETCH POKEMON DATA FROM API
# ============================================================================

# TODO: Convert pokemon_team list to a map for for_each
# Hint: Use a for expression to create { name => {name, id} }
locals {
  # pokemon_map = {
  #   for p in var.pokemon_team : p.name => p
  # }
}

# TODO: Fetch Pokemon data from the API
# Requirements:
# - Use data "http" with for_each (NOT count!)
# - Iterate over local.pokemon_map
# - URL: https://pokeapi.co/api/v2/pokemon/{id}
# - Add Accept: application/json header

# data "http" "pokemon" {
#   for_each = ...
#
#   url = "https://pokeapi.co/api/v2/pokemon/${...}"
#
#   request_headers = {
#     Accept = "application/json"
#   }
# }

# ============================================================================
# LOCALS - PARSE AND TRANSFORM POKEMON DATA
# ============================================================================

locals {
  # TODO: Parse Pokemon API responses
  # Hint: Use jsondecode() on each response_body
  # pokemon_data = {
  #   for name, response in data.http.pokemon : name => jsondecode(response.response_body)
  # }

  # TODO: Extract types for each Pokemon
  # Hint: p.types is an array, each item has .type.name
  # pokemon_types = {
  #   for name, p in local.pokemon_data : name => [
  #     for t in p.types : t.type.name
  #   ]
  # }

  # TODO: Extract HP for each Pokemon
  # Hint: Find the stat where s.stat.name == "hp"
  # pokemon_hp = {
  #   for name, p in local.pokemon_data : name => [
  #     for s in p.stats : s.base_stat if s.stat.name == "hp"
  #   ][0]
  # }

  # TODO: Extract sprite URLs
  # Hint: p.sprites.front_default
  # pokemon_sprites = {
  #   for name, p in local.pokemon_data : name => p.sprites.front_default
  # }

  # TODO: Get all unique types across the entire team
  # Hint: flatten() all types, then toset() to remove duplicates
  # all_types = flatten(values(local.pokemon_types))
  # unique_types = toset(local.all_types)

  # Pokemon Type → Port Mapping
  type_ports = {
    fire     = 8080
    water    = 8081
    electric = 443
    grass    = 80
    normal   = 22
    psychic  = 8443
    ghost    = 666
    dragon   = 9000
    fighting = 3000
    flying   = 8888
    poison   = 5432
    ground   = 8082
    rock     = 8083
    bug      = 8084
    ice      = 8085
    fairy    = 8086
    steel    = 8087
    dark     = 8088
  }

  # TODO: Calculate team stats
  # total_hp = sum(values(local.pokemon_hp))
  # strongest_pokemon = {
  #   name = ...
  #   hp = max(values(local.pokemon_hp))...
  # }
}

# ============================================================================
# EC2 RESOURCES (if deployment_path == "ec2")
# ============================================================================

# TODO: Get latest Amazon Linux 2023 AMI
# data "aws_ami" "amazon_linux" {
#   most_recent = true
#   owners      = ["amazon"]
#
#   filter {
#     name   = "name"
#     values = ["al2023-ami-2023*-kernel-*-x86_64"]
#   }
# }

# TODO: Create security group with dynamic ingress rules
# Requirements:
# - Name it something unique (include var.student_name)
# - Use dynamic "ingress" block
# - Iterate over local.unique_types
# - Use lookup() to map types to ports (default: 8000)
# - Set protocol to "tcp", cidr_blocks to ["0.0.0.0/0"]
# - Add descriptive descriptions

# resource "aws_security_group" "pokemon_gym" {
#   count = var.deployment_path == "ec2" ? 1 : 0
#
#   name        = "pokemon-gym-${var.student_name}"
#   description = "Dynamic security group based on Pokemon types"
#
#   dynamic "ingress" {
#     # TODO: for_each over unique types
#     # TODO: content block with from_port, to_port, protocol, cidr_blocks
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = {
#     Name        = "pokemon-gym-sg-${var.student_name}"
#     Trainer     = var.student_name
#     Environment = var.environment
#   }
# }

# TODO: Create EC2 instances for each Pokemon
# Requirements:
# - Use for_each with local.pokemon_map
# - Instance type from var.instance_type
# - AMI from data.aws_ami.amazon_linux
# - Attach security group
# - Add lifecycle precondition: HP must be > 30
# - Add all required tags

# resource "aws_instance" "pokemon" {
#   count = var.deployment_path == "ec2" ? length(local.pokemon_map) : 0
#   # WRONG! Use for_each instead! This is just a hint of the structure
#
#   # TODO: Use for_each = local.pokemon_map
#   # TODO: Set ami, instance_type
#   # TODO: Set vpc_security_group_ids with security group from above
#   # TODO: Add lifecycle block with precondition checking HP > 30
#   # TODO: Add tags for name, id, types, hp, trainer, environment
# }

# ============================================================================
# DOCKER RESOURCES (if deployment_path == "docker")
# ============================================================================

# TODO: Pull Docker image
# resource "docker_image" "pokemon" {
#   count = var.deployment_path == "docker" ? 1 : 0
#
#   name         = var.docker_image
#   keep_locally = true
# }

# TODO: Create Docker containers for each Pokemon
# Requirements:
# - Use for_each with local.pokemon_map
# - Name: pokemon-{name}
# - Image from docker_image.pokemon
# - Add lifecycle precondition: HP must be > 30
# - Dynamic "env" blocks for each type (POKEMON_TYPE_<TYPE>=<port>)
# - Dynamic "labels" blocks for each type
# - Static labels for name, id, types, hp, trainer

# resource "docker_container" "pokemon" {
#   count = var.deployment_path == "docker" ? length(local.pokemon_map) : 0
#   # WRONG! Use for_each instead!
#
#   # TODO: Use for_each = local.pokemon_map
#   # TODO: Set name and image
#   # TODO: Add lifecycle block with precondition checking HP > 30
#   # TODO: Add dynamic "env" block for types
#   # TODO: Add dynamic "labels" block for types
#   # TODO: Add static labels
# }

# ============================================================================
# HELPFUL COMMENTS
# ============================================================================

# Remember the key concepts:
# 1. Use for_each with MAPS or SETS (not lists!)
# 2. Dynamic blocks: dynamic "block_name" { for_each = ... content { ... } }
# 3. Preconditions go inside lifecycle blocks
# 4. Use lookup(map, key, default) for safe value retrieval
# 5. flatten() and toset() to get unique values
# 6. Access for_each items with each.key and each.value

# Need help? Check the hints in LAB.md!
