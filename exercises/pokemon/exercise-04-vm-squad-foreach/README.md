# Exercise 04: VM Squad with `for_each`

**Time:** 30 minutes | **Difficulty:** ⭐⭐ Intermediate | **Cost:** ~$0.02 (EC2) or $0.00 (Docker)

## Objective

Create the same Pokemon VM squad from Exercise 03, but using `for_each` instead of `count`. Learn why `for_each` creates more stable infrastructure!

## What You'll Learn

- Using `for_each` with sets and maps
- Accessing `each.key` and `each.value`
- Resource addressing with `for_each` (e.g., `aws_instance.pokemon["pikachu"]`)
- Why `for_each` is safer than `count` for dynamic collections
- Converting between data structures with `toset()` and `tomap()`

## The Key Difference

### With `count` (Exercise 03):
```hcl
# Resources are addressed by INDEX
aws_instance.pokemon[0]  # First Pokemon
aws_instance.pokemon[1]  # Second Pokemon

# Remove the first Pokemon → Everything shifts! 💥
```

### With `for_each` (This Exercise):
```hcl
# Resources are addressed by KEY
aws_instance.pokemon["bulbasaur"]   # Always Bulbasaur
aws_instance.pokemon["charmander"]  # Always Charmander

# Remove Bulbasaur → Only Bulbasaur is destroyed! ✅
```

## Choose Your Path

| Path | Provider | Cost | Requirements |
|------|----------|------|--------------|
| **EC2** | AWS | ~$0.02 | AWS credentials |
| **Docker** | Docker | $0.00 | Docker running |

## The Challenge

Build the same infrastructure as Exercise 03, but:

1. Use a **map** variable instead of a list for Pokemon
2. Use `for_each` instead of `count`
3. Access resources by Pokemon name, not index
4. Prove that removing a Pokemon only affects that one resource

## How `for_each` Works

### With a Set

```hcl
variable "pokemon_names" {
  type    = set(string)
  default = ["bulbasaur", "charmander", "squirtle"]
}

resource "aws_instance" "pokemon" {
  for_each = var.pokemon_names

  tags = {
    Name = "pokemon-${each.key}"  # each.key = each.value for sets
  }
}

# Access: aws_instance.pokemon["bulbasaur"]
```

### With a Map (More Powerful!)

```hcl
variable "pokemon" {
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

resource "aws_instance" "pokemon" {
  for_each = var.pokemon

  tags = {
    Name        = "pokemon-${each.key}"        # "bulbasaur", "charmander", etc.
    PokemonID   = each.value.id                # 1, 4, 7
    PokemonType = each.value.type              # "grass", "fire", "water"
  }
}

# Access: aws_instance.pokemon["charmander"].id
```

## The Stability Test

After completing the exercise, try this:

### With Exercise 03 (`count`):
```hcl
# Original: pokemon_ids = [1, 4, 7]
# Remove charmander (4): pokemon_ids = [1, 7]

# terraform plan shows:
# - aws_instance.pokemon[1] will be DESTROYED (was charmander)
# - aws_instance.pokemon[2] will be DESTROYED (was squirtle)
# + aws_instance.pokemon[1] will be CREATED (now squirtle!)
```

### With Exercise 04 (`for_each`):
```hcl
# Original: pokemon = { bulbasaur = {...}, charmander = {...}, squirtle = {...} }
# Remove charmander

# terraform plan shows:
# - aws_instance.pokemon["charmander"] will be DESTROYED
# 
# That's it! Bulbasaur and Squirtle are unchanged.
```

## Directory Structure

```
exercise-04-vm-squad-foreach/
├── README.md           # This file
├── ec2/
│   ├── starter/
│   └── solution/
└── docker/
    ├── starter/
    └── solution/
```

## Instructions

### Step 1: Choose Your Path

```bash
# EC2 Path
cd ec2/
cp -r starter/ my-solution/

# OR Docker Path
cd docker/
cp -r starter/ my-solution/
```

### Step 2: Complete the Exercise

The key differences from Exercise 03:

1. **Variable is a map**, not a list
2. **Use `for_each`** instead of `count`
3. **Access with `each.key`** (Pokemon name) and `each.value` (Pokemon data)
4. **Reference with name**, e.g., `aws_instance.pokemon["pikachu"]`

### Step 3: Apply and Test

```bash
terraform init
terraform apply
```

### Step 4: Test the Stability!

1. Apply with all 3 Pokemon
2. Remove one Pokemon from the middle of your map
3. Run `terraform plan`
4. Observe: Only ONE resource is destroyed!

## Success Criteria

- [ ] Uses `for_each` with a map variable
- [ ] Resources are addressable by Pokemon name
- [ ] Removing a Pokemon only destroys that specific resource
- [ ] All Pokemon metadata in tags/labels
- [ ] Outputs show the squad roster

## Hints

<details>
<summary>Hint 1: Map Variable Structure</summary>

```hcl
variable "pokemon" {
  type = map(object({
    id   = number
    type = string
    hp   = number
  }))
  default = {
    bulbasaur = { id = 1, type = "grass", hp = 45 }
    charmander = { id = 4, type = "fire", hp = 39 }
    squirtle = { id = 7, type = "water", hp = 44 }
  }
}
```

</details>

<details>
<summary>Hint 2: Fetching API Data with for_each</summary>

You can use `for_each` on data sources too:

```hcl
data "http" "pokemon" {
  for_each = var.pokemon

  url = "https://pokeapi.co/api/v2/pokemon/${each.value.id}"
}

# Access: data.http.pokemon["bulbasaur"].response_body
```

</details>

<details>
<summary>Hint 3: Using each.key and each.value</summary>

```hcl
resource "aws_instance" "pokemon" {
  for_each = var.pokemon

  tags = {
    Name        = "pokemon-${each.key}"    # The map key (pokemon name)
    PokemonID   = each.value.id            # From the object value
    PokemonType = each.value.type          # From the object value
  }
}
```

</details>

<details>
<summary>Hint 4: Iterating in Outputs</summary>

```hcl
output "squad_roster" {
  value = {
    for name, instance in aws_instance.pokemon : name => {
      instance_id = instance.id
      private_ip  = instance.private_ip
    }
  }
}
```

</details>

## When to Use `count` vs `for_each`

| Use Case | Recommendation |
|----------|----------------|
| Fixed number of identical resources | `count` |
| Resources identified by unique key | `for_each` |
| List where order matters | `count` |
| Resources that may be added/removed | `for_each` |
| Simple numeric iteration | `count` |
| Complex objects with identifiers | `for_each` |

**Rule of thumb:** If your resources have meaningful names or identifiers, use `for_each`!

## Stretch Goals

1. **Add dynamic API fetching**: Fetch real Pokemon data for each entry in the map
2. **Hybrid approach**: Store just IDs in the map, fetch details from API
3. **Add HP-based sizing**: Use `each.value.hp` to determine instance size
4. **Multi-type Pokemon**: Handle Pokemon with multiple types

## Cleanup

```bash
terraform destroy
```

## What's Next?

Exercise 05 teaches dynamic blocks - another powerful iteration technique for generating nested configuration blocks!

---

**Gotta Loop 'Em All!** 🎮
