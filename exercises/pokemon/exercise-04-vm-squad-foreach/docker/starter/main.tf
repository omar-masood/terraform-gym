# Exercise 04: Pokemon VM Squad with for_each (Docker Version)
#
# Create Docker containers named after Pokemon using for_each!
# This approach is MORE STABLE than count - removing a Pokemon
# only destroys that specific container!
#
# Your mission:
# 1. Use a map variable for Pokemon data
# 2. Fetch Pokemon data from the API using for_each
# 3. Create a Docker container for each Pokemon
# 4. Access containers by name, not index!

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

provider "docker" {}

# ============================================================================
# VARIABLES
# ============================================================================

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

# TODO: This is the key difference from Exercise 03!
# Instead of a list of IDs, we use a map keyed by Pokemon name
variable "pokemon" {
  description = "Map of Pokemon to create containers for"
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

# TODO: Fetch Pokemon data using for_each instead of count!
# Hint: for_each = var.pokemon
# Hint: Use each.value.id in the URL
data "http" "pokemon" {
  # YOUR CODE HERE - use for_each!
  for_each = {}  # Replace with var.pokemon

  url = "https://pokeapi.co/api/v2/pokemon/1"  # Replace with dynamic URL

  request_headers = {
    Accept = "application/json"
  }
}

# ============================================================================
# LOCALS
# ============================================================================

locals {
  # TODO: Parse each Pokemon response into HCL objects (as a map!)
  pokemon_data = {
    # Hint: for name, response in data.http.pokemon : name => jsondecode(response.response_body)
  }

  # TODO: Extract HP for each Pokemon
  pokemon_hp = {
    # Hint: for name, p in local.pokemon_data : name => [for s in p.stats : s.base_stat if s.stat.name == "hp"][0]
  }

  # Create port assignments - each Pokemon gets a unique port
  # Using index() to get position in sorted keys
  pokemon_ports = {
    for name in keys(var.pokemon) : name => var.base_port + index(keys(var.pokemon), name)
  }
}

# ============================================================================
# DOCKER RESOURCES
# ============================================================================

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# TODO: Create Docker containers using for_each
resource "docker_container" "pokemon" {
  # YOUR CODE HERE - use for_each!
  for_each = {}  # Replace with var.pokemon

  name  = "pokemon-placeholder"  # Replace: "pokemon-${each.key}"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.base_port  # TODO: Use local.pokemon_ports[each.key]
  }

  # TODO: Add labels using each.key and each.value
  labels {
    label = "pokemon.name"
    value = "placeholder"  # Replace with each.key
  }

  labels {
    label = "pokemon.type"
    value = "placeholder"  # Replace with each.value.type
  }

  labels {
    label = "pokemon.id"
    value = "0"  # Replace with each.value.id
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
#   value = {
#     for name, container in docker_container.pokemon : name => {
#       pokemon_name = name
#       pokemon_type = var.pokemon[name].type
#       port         = local.pokemon_ports[name]
#       url          = "http://localhost:${local.pokemon_ports[name]}"
#     }
#   }
# }

# output "pokemon_names" {
#   description = "Names of all Pokemon in your squad"
#   value       = keys(docker_container.pokemon)
# }

# Access a specific Pokemon!
# output "charmander_url" {
#   description = "URL for Charmander's container"
#   value       = "http://localhost:${local.pokemon_ports["charmander"]}"
# }
