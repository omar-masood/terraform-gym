# Exercise 02: Pokemon Custom Types - Variables
#
# Complete the type definitions and validation rules below

# ============================================================================
# SINGLE POKEMON TYPE
# ============================================================================

# This shows the pattern - a simple object type
variable "favorite_pokemon" {
  description = "Your single favorite Pokemon"
  type = object({
    name = string
    type = string
    hp   = number
  })
  default = {
    name = "pikachu"
    type = "electric"
    hp   = 35
  }
}

# ============================================================================
# POKEMON TEAM (with validation)
# ============================================================================

# TODO: Complete this variable definition
variable "pokemon_team" {
  description = "Your Pokemon team (max 6 members)"

  # TODO: Define the type as list(object({...}))
  # Each Pokemon should have:
  # - name (string, required)
  # - type (string, required)
  # - hp (number, required)
  # - shiny (bool, optional, default false)
  # - level (number, optional)
  type = list(object({
    name  = string
    type  = string
    hp    = number
    # TODO: Add optional fields for shiny and level
    # Hint: shiny = optional(bool, false)
  }))

  # TODO: Add validation - team must have 1-6 members
  # validation {
  #   condition     = ???
  #   error_message = "A Pokemon team must have between 1 and 6 members!"
  # }

  # TODO: Add validation - HP must be between 1 and 255
  # validation {
  #   condition     = ???
  #   error_message = "Pokemon HP must be between 1 and 255."
  # }

  # TODO: Add validation - type must be valid
  # Valid types: normal, fire, water, electric, grass, ice, fighting, poison,
  #              ground, flying, psychic, bug, rock, ghost, dragon, dark, steel, fairy
  # Hint: Use contains() with alltrue()
  # validation {
  #   condition     = ???
  #   error_message = "Invalid Pokemon type."
  # }

  default = [
    { name = "pikachu", type = "electric", hp = 35 },
    { name = "charizard", type = "fire", hp = 78 },
    { name = "blastoise", type = "water", hp = 79 },
  ]
}

# ============================================================================
# POKEDEX (map of Pokemon)
# ============================================================================

# TODO: Define a pokedex variable as a map
# The key is the Pokemon name, value is an object with id, type, hp
variable "pokedex" {
  description = "A collection of Pokemon indexed by name"

  # TODO: Define type as map(object({...}))
  type = map(object({
    id   = number
    type = string
    hp   = number
  }))

  default = {
    bulbasaur = { id = 1, type = "grass", hp = 45 }
    charmander = { id = 4, type = "fire", hp = 39 }
    squirtle = { id = 7, type = "water", hp = 44 }
    pikachu = { id = 25, type = "electric", hp = 35 }
  }
}

# ============================================================================
# STRETCH: Pokemon with multiple types
# ============================================================================

# Some Pokemon have two types (e.g., Charizard is Fire/Flying)
# TODO: Define a variable for dual-type Pokemon
# variable "dual_type_pokemon" {
#   type = object({
#     name  = string
#     types = list(string)  # Can have 1 or 2 types
#     hp    = number
#   })
#
#   validation {
#     condition     = length(var.dual_type_pokemon.types) >= 1 && length(var.dual_type_pokemon.types) <= 2
#     error_message = "Pokemon can have 1 or 2 types."
#   }
#
#   default = {
#     name  = "charizard"
#     types = ["fire", "flying"]
#     hp    = 78
#   }
# }
