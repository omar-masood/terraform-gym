# Challenge: Pokedex Infrastructure - STARTER
# Outputs File

# ============================================================================
# REQUIRED OUTPUT 1: TEAM ROSTER
# ============================================================================

# TODO: Create team_roster output
# Requirements:
# - Map of pokemon_name => details
# - Include: name, id, types, hp, sprite, instance_id/container_id
# - Use conditional logic based on deployment_path

# output "team_roster" {
#   description = "Complete roster of your Pokemon team"
#   value = {
#     for name in keys(local.pokemon_map) : name => {
#       pokemon_name = name
#       pokemon_id   = local.pokemon_data[name].id
#       types        = local.pokemon_types[name]
#       hp           = local.pokemon_hp[name]
#       sprite       = local.pokemon_sprites[name]
#       # TODO: Add instance_id (EC2) or container_id (Docker) based on deployment_path
#       resource_id = var.deployment_path == "ec2" ? "..." : "..."
#     }
#   }
# }

# ============================================================================
# REQUIRED OUTPUT 2: POKEDEX REPORT
# ============================================================================

# TODO: Create pokedex_report output
# Requirements:
# - Formatted multi-line string using heredoc (<<-EOT ... EOT)
# - Include: Trainer name, team size, roster with details, team stats
# - Use %{for...} template directives for iteration
# - Make it look nice!

# output "pokedex_report" {
#   description = "Formatted Pokedex report"
#   value = <<-EOT
#     =================================
#         POKEMON GYM POKEDEX
#     =================================
#
#     Trainer: ${var.student_name}
#     Team Size: ${length(var.pokemon_team)} Pokemon
#
#     POKEMON ROSTER:
#     %{for idx, p in var.pokemon_team~}
#     ${idx + 1}. ${upper(p.name)} (ID: ${p.id})
#        TODO: Add types, HP, instance/container info
#     %{endfor~}
#
#     TEAM STATS:
#     - Total HP: TODO
#     - Types: TODO (X unique)
#     - Strongest: TODO
#
#     INFRASTRUCTURE:
#     - Instances/Containers: ${length(var.pokemon_team)}
#     - Security Rules / Env Vars: TODO
#
#   EOT
# }

# ============================================================================
# REQUIRED OUTPUT 3: TYPE COVERAGE
# ============================================================================

# TODO: Create type_coverage output
# Requirements:
# - Map of type => list of Pokemon with that type
# - Show which Pokemon have each type

# output "type_coverage" {
#   description = "Which Pokemon have which types"
#   value = {
#     # TODO: For each unique type, list the Pokemon that have it
#     # Hint: Use a for expression with contains()
#     # for type in local.unique_types : type => [
#     #   for name, types in local.pokemon_types : name if contains(types, type)
#     # ]
#   }
# }

# ============================================================================
# REQUIRED OUTPUT 4: TEAM STATS
# ============================================================================

# TODO: Create team_stats output
# Requirements:
# - Object with: total_hp, unique_types_count, strongest_pokemon {name, hp}

# output "team_stats" {
#   description = "Statistics about your Pokemon team"
#   value = {
#     # TODO: total_hp = sum(values(local.pokemon_hp))
#     # TODO: unique_types_count = length(local.unique_types)
#     # TODO: strongest_pokemon = {
#     #   name = ...
#     #   hp = max(values(local.pokemon_hp))...
#     # }
#     # TODO: weakest_pokemon (optional)
#     # TODO: average_hp (optional)
#   }
# }

# ============================================================================
# HELPFUL OUTPUTS (Optional but Recommended)
# ============================================================================

# output "unique_types" {
#   description = "All unique Pokemon types in your team"
#   value       = sort(tolist(local.unique_types))
# }

# output "type_port_mapping" {
#   description = "Mapping of types to ports"
#   value = {
#     for type in local.unique_types : type => lookup(local.type_ports, type, 8000)
#   }
# }

# output "security_group_id" {
#   description = "Security group ID (EC2 only)"
#   value       = var.deployment_path == "ec2" ? "TODO" : "N/A (Docker path)"
# }

# output "verification_commands" {
#   description = "Commands to verify your deployment"
#   value = var.deployment_path == "ec2" ? <<-EOT
#     === EC2 VERIFICATION ===
#
#     # List all Pokemon instances:
#     aws ec2 describe-instances --filters "Name=tag:Trainer,Values=${var.student_name}" --region ${var.aws_region}
#
#     # View security group rules:
#     aws ec2 describe-security-groups --group-ids TODO --region ${var.aws_region}
#
#   EOT : <<-EOT
#     === DOCKER VERIFICATION ===
#
#     # List all Pokemon containers:
#     docker ps --filter "label=trainer=${var.student_name}"
#
#     # Check a Pokemon's env vars:
#     docker exec pokemon-bulbasaur env | grep POKEMON
#
#     # View container labels:
#     docker inspect pokemon-bulbasaur --format='{{json .Config.Labels}}' | jq .
#
#   EOT
# }

# ============================================================================
# DEBUGGING OUTPUTS (Uncomment while developing)
# ============================================================================

# output "debug_pokemon_data" {
#   value = local.pokemon_data
# }
#
# output "debug_pokemon_types" {
#   value = local.pokemon_types
# }
#
# output "debug_pokemon_hp" {
#   value = local.pokemon_hp
# }
