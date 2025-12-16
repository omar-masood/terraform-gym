# Exercise 05: Dynamic Types - Port Power! (Docker Version) - STARTER
#
# Create containers with dynamic environment variables based on Pokemon types!
# Each type gets its own env var with the corresponding port number.

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

# TODO: Define a pokemon variable as a map
# Use the same structure as Exercise 04!
variable "pokemon" {
  description = "Map of Pokemon to create containers for"
  type = map(object({
    id   = number
    type = string
  }))
  default = {
    # TODO: Add your Pokemon team here (at least 3)
    # Hint: Choose Pokemon with different types!
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

# TODO: Fetch Pokemon data from the API using for_each
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
  pokemon_types = {
    # TODO: Create a map of pokemon_name => list_of_types
  }

  # TODO: Flatten all types into a single list
  all_types = [
    # Hint: Use flatten() and values()
  ]

  # TODO: Get unique types only
  unique_types = []

  # Pokemon Type → Port Mapping
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
# DOCKER RESOURCES
# ============================================================================

resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# TODO: Create containers with dynamic env variables
resource "docker_container" "pokemon" {
  # TODO: Add for_each to create one container per Pokemon

  # TODO: Set name and image

  # TODO: Add a dynamic "env" block
  # - for_each should iterate over THIS Pokemon's types (not all unique types!)
  # - Each env var should be named: POKEMON_TYPE_<TYPE> = <port>
  # - Use lookup() to map types to ports (default: 8000)
  # - Hint: local.pokemon_types[each.key] gives you the types for the current Pokemon

  # TODO: Add a dynamic "labels" block for each type
  # - Label name: pokemon.type.<index>
  # - Label value: the type name

  # Regular labels (not dynamic)
  labels {
    label = "pokemon.name"
    value = "" # TODO: Set to each.key
  }

  labels {
    label = "trainer"
    value = var.student_name
  }

  labels {
    label = "managed-by"
    value = "terraform"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

# TODO: Output all unique types found
output "pokemon_types_found" {
  description = "All unique Pokemon types in your team"
  value       = [] # TODO
}

# TODO: Output the type → port mapping
output "type_port_mapping" {
  description = "Which port each Pokemon type maps to"
  value = {
    # TODO
  }
}

# TODO: Output container details with their types
output "container_details" {
  description = "Details of each Pokemon container and their types"
  value = {
    # TODO: Show container name, types, and env vars
  }
}

# TODO: Output a summary
output "dynamic_env_summary" {
  description = "Summary of dynamic environment variables created"
  value       = "" # TODO: Use a heredoc to create a nice summary
}
