# Exercise 02: Pokemon Custom Types
#
# Define complex types to model Pokemon data
# No resources needed - just variables and locals!

terraform {
  required_version = ">= 1.9.0"
}

# ============================================================================
# STEP 1: Define valid Pokemon types as a local
# ============================================================================

locals {
  # All valid Pokemon types (used for reference in outputs)
  valid_pokemon_types = [
    "normal", "fire", "water", "electric", "grass", "ice",
    "fighting", "poison", "ground", "flying", "psychic",
    "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"
  ]
}

# ============================================================================
# STEP 2: Define a single Pokemon variable (in variables.tf)
# ============================================================================

# See variables.tf - complete the pokemon_team variable definition

# ============================================================================
# STEP 3: Create computed values from the team
# ============================================================================

locals {
  # TODO: Extract just the names from the team
  # Hint: Use a for expression
  team_names = []  # Replace with: [for p in var.pokemon_team : p.name]

  # TODO: Calculate total HP of the team
  # Hint: Use sum() with a for expression
  team_total_hp = 0  # Replace with: sum([for p in var.pokemon_team : p.hp])

  # TODO: Filter for just fire-type Pokemon
  fire_types = []  # Replace with: [for p in var.pokemon_team : p.name if p.type == "fire"]

  # TODO: Create a map of name -> HP for quick lookup
  hp_lookup = {}  # Replace with: { for p in var.pokemon_team : p.name => p.hp }
}

# ============================================================================
# STEP 4: Outputs (uncomment when ready)
# ============================================================================

# output "pokemon_team_names" {
#   description = "Names of all Pokemon on the team"
#   value       = local.team_names
# }

# output "team_total_hp" {
#   description = "Combined HP of all team members"
#   value       = local.team_total_hp
# }

# output "fire_type_pokemon" {
#   description = "Names of fire-type Pokemon on the team"
#   value       = local.fire_types
# }

# output "hp_lookup_table" {
#   description = "Map of Pokemon names to their HP"
#   value       = local.hp_lookup
# }

# output "team_size" {
#   description = "Number of Pokemon on the team"
#   value       = length(var.pokemon_team)
# }
