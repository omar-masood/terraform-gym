# API Explorer Challenge 🎲
#
# Your task: Query a public API and combine it with random generated values
#
# Documentation:
# - HTTP Provider: https://registry.terraform.io/providers/hashicorp/http/latest/docs
# - Random Provider: https://registry.terraform.io/providers/hashicorp/random/latest/docs
#
# TIP: Test your API first with curl!
# curl https://pokeapi.co/api/v2/pokemon/25

# TODO: Configure the required providers (hashicorp/http and hashicorp/random)
terraform {
  required_providers {
    # Your code here
  }
}

# TODO: Configure the providers (hint: they don't need any configuration!)
provider "http" {
  # Nothing needed here
}

provider "random" {
  # Nothing needed here
}

# TODO: Create a random_integer resource to generate Pokemon ID
# - Use var.lucky_min and var.lucky_max for the range


# TODO: Create an http data source to fetch a Pokemon
# The data source should:
# - Use the var.pokemon_api_url variable combined with the random Pokemon ID
# - Include an Accept header for application/json


# TODO: Create a locals block to parse the JSON response
# Hint: Use jsondecode() on the response_body attribute
# Extract: pokemon_name, pokemon_id, pokemon_type, pokemon_weight, pokemon_height
locals {
  # Your code here
}

# TODO: Create a random_pet resource for the trainer name
# Note: This is a RESOURCE, not a data source!
# - Use var.pet_prefix for the prefix
# - Set length to 2


# TODO: Create a random_integer resource for the trainer level
# - Range from 1 to 100
