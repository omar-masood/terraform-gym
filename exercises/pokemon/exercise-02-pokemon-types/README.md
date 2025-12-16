# Exercise 02: Pokemon Custom Types

**Time:** 25 minutes | **Difficulty:** ⭐⭐ Intermediate | **Cost:** $0.00

## Objective

Define complex Terraform types that model Pokemon data, including custom objects, lists of objects, maps, and validation rules.

## What You'll Learn

- Defining `object()` types with multiple fields
- Using `list(object())` for collections
- Using `map(object())` for named collections  
- Optional fields with `optional()`
- Input validation with `validation` blocks
- Type constraints and error handling

## Prerequisites

- Completed Exercise 01 (Pokemon Data Fetching)
- Understanding of basic Terraform variables

## The Challenge

Create type definitions for:

1. **A single Pokemon** - Object with name, types, HP, and optional fields
2. **A Pokemon team** - List of up to 6 Pokemon
3. **A Pokedex** - Map of Pokemon keyed by name
4. **Validation rules** - Team size limits, valid types, HP ranges

## Real-World Connection

These patterns are used constantly in production Terraform:

```hcl
# AWS Example: Defining subnet configuration
variable "subnets" {
  type = list(object({
    name              = string
    cidr_block        = string
    availability_zone = string
    public            = optional(bool, false)
  }))
}

# The Pokemon version teaches the same concept with more fun!
variable "pokemon_team" {
  type = list(object({
    name    = string
    type    = string
    hp      = number
    shiny   = optional(bool, false)
  }))
}
```

## Instructions

### Step 1: Copy the Starter Files

```bash
cp -r starter/ my-solution/
cd my-solution/
```

### Step 2: Complete the Type Definitions

Open `variables.tf` and complete each TODO:

1. Define a `pokemon` object type
2. Define a `pokemon_team` list with validation
3. Define a `pokedex` map type
4. Add validation rules for Pokemon types

### Step 3: Create Test Data

Edit `terraform.tfvars` to create your Pokemon team!

### Step 4: Test Your Types

```bash
terraform init
terraform validate
terraform plan
```

### Step 5: Test Validation

Try breaking the rules to see validation in action:
- Add 7 Pokemon to your team (should fail!)
- Use HP of 500 (should fail!)
- Use an invalid type like "banana" (should fail!)

## Success Criteria

- [ ] All variables have proper type definitions
- [ ] `terraform validate` passes with valid data
- [ ] Validation fails for teams larger than 6
- [ ] Validation fails for invalid Pokemon types
- [ ] Validation fails for HP outside 1-255 range
- [ ] Optional fields work correctly

## Key Concepts

### Object Types

```hcl
variable "pokemon" {
  type = object({
    name = string          # Required string
    hp   = number          # Required number
    type = string          # Required string
  })
}

# Usage in terraform.tfvars:
pokemon = {
  name = "pikachu"
  hp   = 35
  type = "electric"
}
```

### Optional Fields (Terraform 1.3+)

```hcl
variable "pokemon" {
  type = object({
    name  = string
    hp    = number
    shiny = optional(bool, false)  # Default to false if not provided
    level = optional(number)        # Default to null if not provided
  })
}
```

### List of Objects

```hcl
variable "team" {
  type = list(object({
    name = string
    type = string
  }))
}

# Usage:
team = [
  { name = "pikachu", type = "electric" },
  { name = "charizard", type = "fire" },
]
```

### Map of Objects

```hcl
variable "pokedex" {
  type = map(object({
    id   = number
    type = string
    hp   = number
  }))
}

# Usage - keys are the Pokemon names:
pokedex = {
  pikachu = { id = 25, type = "electric", hp = 35 }
  bulbasaur = { id = 1, type = "grass", hp = 45 }
}

# Access: var.pokedex["pikachu"].hp
```

### Validation Blocks

```hcl
variable "pokemon_team" {
  type = list(object({
    name = string
    hp   = number
  }))

  validation {
    condition     = length(var.pokemon_team) <= 6
    error_message = "A Pokemon team can have at most 6 members!"
  }

  validation {
    condition     = alltrue([for p in var.pokemon_team : p.hp >= 1 && p.hp <= 255])
    error_message = "Pokemon HP must be between 1 and 255."
  }
}
```

### Useful Validation Functions

| Function | Purpose | Example |
|----------|---------|---------|
| `length()` | Count items | `length(var.team) <= 6` |
| `alltrue()` | All conditions true | `alltrue([for p in var.team : p.hp > 0])` |
| `anytrue()` | At least one true | `anytrue([for p in var.team : p.type == "water"])` |
| `contains()` | Item in list | `contains(["fire", "water"], var.type)` |
| `can()` | Expression valid | `can(regex("^[a-z]+$", var.name))` |

## Hints

<details>
<summary>Hint 1: Valid Pokemon Types</summary>

Create a local list of valid types to reference in validation:

```hcl
locals {
  valid_types = ["normal", "fire", "water", "electric", "grass", "ice", 
                 "fighting", "poison", "ground", "flying", "psychic", 
                 "bug", "rock", "ghost", "dragon", "dark", "steel", "fairy"]
}

validation {
  condition     = alltrue([for p in var.team : contains(local.valid_types, p.type)])
  error_message = "Invalid Pokemon type. Must be one of: ${join(", ", local.valid_types)}"
}
```

Wait - you can't use locals in validation! Use the list directly in the condition.

</details>

<details>
<summary>Hint 2: Checking All Items</summary>

Use `alltrue()` with a for expression:

```hcl
condition = alltrue([
  for pokemon in var.team : pokemon.hp >= 1 && pokemon.hp <= 255
])
```

</details>

<details>
<summary>Hint 3: Multiple Validations</summary>

You can have multiple validation blocks on one variable:

```hcl
variable "team" {
  type = list(object({...}))

  validation {
    condition     = length(var.team) <= 6
    error_message = "Team too large!"
  }

  validation {
    condition     = length(var.team) >= 1
    error_message = "Team must have at least 1 Pokemon!"
  }
}
```

</details>

## Stretch Goals

1. **Add dual types**: Change `type` to `types` as a `list(string)` with max 2 items
2. **Add moves**: Each Pokemon can have up to 4 moves (list of strings)
3. **Add level**: Optional level 1-100 with validation
4. **Add evolution chain**: Optional reference to pre/post evolution names

## Expected Output

With valid data:

```
$ terraform validate
Success! The configuration is valid.

$ terraform plan
...
pokemon_team_names = ["pikachu", "charizard", "blastoise"]
team_total_hp = 192
```

With invalid data (team of 7):

```
$ terraform validate
╷
│ Error: Invalid value for variable
│
│   on variables.tf line 10:
│   10: variable "pokemon_team" {
│
│ A Pokemon team can have at most 6 members!
```

## Common Errors

### "Inconsistent object type"
You're missing a required field in one of your objects:
```hcl
# Wrong - missing 'type'
{ name = "pikachu", hp = 35 }

# Right
{ name = "pikachu", hp = 35, type = "electric" }
```

### "Invalid value for variable"
Your validation failed! Read the error message - it tells you what's wrong.

### "Cannot use locals in validation"
Validation conditions can only reference the variable itself, not locals or other variables.

## Cleanup

No resources to destroy! This exercise only uses variable definitions.

## What's Next?

In Exercise 03, you'll use these Pokemon types to create actual infrastructure - VMs named after your Pokemon team using `count`!

---

**Gotta Type 'Em All!** 🎮
