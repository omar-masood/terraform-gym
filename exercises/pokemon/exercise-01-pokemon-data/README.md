# Exercise 01: Pokemon Data Fetching

**Time:** 20 minutes | **Difficulty:** ⭐ Beginner | **Cost:** $0.00

## Objective

Fetch Pokemon data from the PokeAPI and extract useful information using Terraform data sources and JSON parsing.

## What You'll Learn

- Using the `http` data source to call external APIs
- Parsing JSON responses with `jsondecode()`
- Extracting nested data with `locals`
- Using `for` expressions to transform lists
- Creating informative outputs

## Prerequisites

- Terraform 1.9.0+
- Internet access (to reach https://pokeapi.co)
- No cloud credentials needed!

## The Challenge

Build a Terraform configuration that:

1. Fetches a Pokemon's data from the PokeAPI
2. Extracts the Pokemon's name, ID, height, and weight
3. Extracts all of the Pokemon's types (some Pokemon have two!)
4. Extracts the Pokemon's HP stat
5. Outputs a formatted "Pokedex entry"

## Instructions

### Step 1: Test the API

Before writing any Terraform, understand what the API returns:

```bash
# Fetch Pikachu's data
curl -s https://pokeapi.co/api/v2/pokemon/pikachu | jq '.'

# See just the fields we care about
curl -s https://pokeapi.co/api/v2/pokemon/pikachu | jq '{
  name: .name,
  id: .id,
  height: .height,
  weight: .weight,
  types: [.types[].type.name],
  hp: .stats[] | select(.stat.name == "hp") | .base_stat
}'
```

### Step 2: Copy the Starter Files

```bash
cp -r starter/ my-solution/
cd my-solution/
```

### Step 3: Complete the TODOs

Open `main.tf` and complete each TODO section. The comments guide you through:

1. Configure the `http` provider
2. Create an `http` data source to fetch Pokemon data
3. Parse the JSON response in a `locals` block
4. Extract nested data (types, HP stat)

### Step 4: Test Your Solution

```bash
terraform init
terraform plan
terraform apply
```

### Step 5: Verify Outputs

Your outputs should look something like:

```
pokemon_id = 25
pokemon_name = "pikachu"
pokemon_height = 4
pokemon_weight = 60
pokemon_types = ["electric"]
pokemon_hp = 35
pokedex_entry = "PIKACHU (#25) - Type: ELECTRIC - HP: 35 - Height: 0.4m - Weight: 6.0kg"
```

## Success Criteria

- [ ] `terraform init` completes successfully
- [ ] `terraform validate` shows no errors
- [ ] `terraform apply` succeeds without creating any resources (data sources only!)
- [ ] All outputs display correct Pokemon information
- [ ] Try changing the Pokemon name variable and re-applying

## Key Concepts

### HTTP Data Source

```hcl
data "http" "example" {
  url = "https://api.example.com/data"

  # Optional: Add headers
  request_headers = {
    Accept = "application/json"
  }
}

# Access the response
# data.http.example.response_body  -> Raw string
# data.http.example.status_code    -> HTTP status (200, 404, etc.)
```

### JSON Parsing

```hcl
locals {
  # Parse JSON string into HCL object
  parsed = jsondecode(data.http.example.response_body)

  # Now access fields like a normal object
  name = local.parsed.name
  items = local.parsed.items  # If it's a list
}
```

### For Expressions

```hcl
# Transform a list
types = [for t in local.pokemon.types : t.type.name]

# Filter a list
fire_types = [for t in local.pokemon.types : t.type.name if t.type.name == "fire"]

# Transform to uppercase
upper_types = [for t in local.types : upper(t)]
```

### Filtering with for

To find a specific item in a list (like the HP stat):

```hcl
# Method 1: Filter and take first
hp_stat = [for s in local.pokemon.stats : s.base_stat if s.stat.name == "hp"][0]

# Method 2: Use try() for safety
hp_stat = try([for s in local.pokemon.stats : s.base_stat if s.stat.name == "hp"][0], 0)
```

## Hints

<details>
<summary>Hint 1: Provider Configuration</summary>

The `http` provider doesn't need any configuration! Just declare it:

```hcl
terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}
```

</details>

<details>
<summary>Hint 2: Building the URL</summary>

Use string interpolation to include the variable:

```hcl
data "http" "pokemon" {
  url = "https://pokeapi.co/api/v2/pokemon/${var.pokemon_name}"
}
```

</details>

<details>
<summary>Hint 3: Extracting Types</summary>

The types array looks like: `[{slot: 1, type: {name: "electric", url: "..."}}]`

To get just the type names:

```hcl
types = [for t in local.pokemon.types : t.type.name]
```

</details>

<details>
<summary>Hint 4: Finding HP</summary>

Stats is an array where each item has `stat.name` and `base_stat`. Filter for HP:

```hcl
hp = [for s in local.pokemon.stats : s.base_stat if s.stat.name == "hp"][0]
```

</details>

## Stretch Goals

1. **Add more stats**: Extract attack, defense, and speed stats
2. **Fetch sprite URL**: Output the Pokemon's front sprite image URL
3. **Multiple Pokemon**: Modify to fetch 3 Pokemon and output all their names
4. **Error handling**: What happens if you request a Pokemon that doesn't exist? Add `try()` for safety

## Common Errors

### "Invalid character"
The API returned HTML instead of JSON (maybe a 404). Check your Pokemon name spelling!

### "Invalid index"
You're trying to access an array index that doesn't exist. Use `try()` for safety:
```hcl
hp = try(local.hp_stats[0], 0)
```

### "Provider not found"
Run `terraform init` to download the http provider.

## Cleanup

No resources to destroy! This exercise only uses data sources.

```bash
cd ..
rm -rf my-solution/  # Optional: remove your work
```

## What's Next?

In Exercise 02, you'll learn to define custom Pokemon types using Terraform's type system, including validation rules!

---

**Gotta Fetch 'Em All!** 🎮
