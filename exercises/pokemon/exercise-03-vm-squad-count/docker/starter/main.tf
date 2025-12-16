# Exercise 03: Pokemon VM Squad (Docker Version)
#
# Create Docker containers named after Pokemon using count!
# No AWS required - just Docker!
#
# Your mission:
# 1. Fetch Pokemon data from the API for each ID
# 2. Create a Docker container for each Pokemon
# 3. Name each container after its Pokemon
# 4. Label with Pokemon metadata

terraform {
  required_version = ">= 1.9.0"

  required_providers {
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

provider "docker" {
  # Uses local Docker socket by default
}

# ============================================================================
# VARIABLES
# ============================================================================

variable "pokemon_ids" {
  description = "List of Pokemon IDs to create containers for"
  type        = list(number)
  default     = [1, 4, 7]  # Bulbasaur, Charmander, Squirtle - the OG starters!
}

variable "student_name" {
  description = "Your name/username for resource naming"
  type        = string
  default     = "pokemon-trainer"
}

variable "base_port" {
  description = "Starting port number for containers"
  type        = number
  default     = 8080
}

# ============================================================================
# DATA SOURCES
# ============================================================================

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
  pokemon_data = [
    # Hint: for response in data.http.pokemon : jsondecode(response.response_body)
  ]

  # TODO: Extract just the names as a simple list
  pokemon_names = [
    # Hint: for p in local.pokemon_data : p.name
  ]

  # TODO: Extract primary type for each Pokemon
  pokemon_types = [
    # Hint: for p in local.pokemon_data : p.types[0].type.name
  ]
}

# ============================================================================
# DOCKER IMAGE
# ============================================================================

# Pull nginx image - we'll use it for all Pokemon containers
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# ============================================================================
# DOCKER CONTAINERS - One per Pokemon!
# ============================================================================

# TODO: Create Docker containers using count
resource "docker_container" "pokemon" {
  # YOUR CODE HERE
  count = 0  # Replace with correct count

  name  = "pokemon-placeholder"  # Replace with dynamic Pokemon name
  image = docker_image.nginx.image_id

  # Each container gets a unique port: base_port + index
  ports {
    internal = 80
    external = var.base_port  # TODO: Make this unique per container using count.index
  }

  # TODO: Add labels with Pokemon metadata
  labels {
    label = "pokemon.name"
    value = "placeholder"  # Replace with actual Pokemon name
  }

  labels {
    label = "pokemon.type"
    value = "placeholder"  # Replace with actual Pokemon type
  }

  labels {
    label = "trainer"
    value = var.student_name
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

# Uncomment these outputs once your resources are working:

# output "squad_roster" {
#   description = "Your Pokemon container squad!"
#   value = [
#     for i, container in docker_container.pokemon : {
#       name = local.pokemon_names[i]
#       type = local.pokemon_types[i]
#       port = var.base_port + i
#       url  = "http://localhost:${var.base_port + i}"
#     }
#   ]
# }

# output "pokemon_names" {
#   description = "Names of all Pokemon in your squad"
#   value       = local.pokemon_names
# }

# output "container_ids" {
#   description = "Docker container IDs"
#   value       = docker_container.pokemon[*].id
# }

# output "access_urls" {
#   description = "URLs to access each Pokemon's nginx server"
#   value       = [for i in range(length(var.pokemon_ids)) : "http://localhost:${var.base_port + i}"]
# }
