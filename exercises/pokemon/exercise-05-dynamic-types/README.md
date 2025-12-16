# Exercise 05: Dynamic Types - Port Power!

**Time:** 30 minutes | **Difficulty:** ⭐⭐⭐ Advanced | **Cost:** ~$0.02 (EC2) or $0.00 (Docker)

## Objective

Create security group rules or container configurations dynamically based on Pokemon types! Learn how `dynamic` blocks let you generate nested configuration blocks programmatically.

## What You'll Learn

- Using `dynamic` blocks to generate nested blocks
- `for_each` within dynamic blocks
- `lookup()` function for safe value access with defaults
- Combining API data with dynamic configuration
- When to use dynamic blocks vs explicit blocks
- Filtering collections before iteration

## The Power of Dynamic Blocks

Sometimes you need to generate multiple nested blocks (like security group rules) based on dynamic data. Instead of writing them all out manually, use `dynamic` blocks!

### Traditional Approach (Rigid):

```hcl
resource "aws_security_group" "pokemon_sg" {
  name = "pokemon-sg"

  # Must manually write each rule
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # What if you need 10 more rules? 😱
}
```

### Dynamic Approach (Flexible):

```hcl
resource "aws_security_group" "pokemon_sg" {
  name = "pokemon-sg"

  # Generate rules automatically!
  dynamic "ingress" {
    for_each = var.pokemon_types
    content {
      from_port   = local.type_ports[ingress.value]
      to_port     = local.type_ports[ingress.value]
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

## Choose Your Path

| Path | Provider | Cost | Requirements |
|------|----------|------|--------------|
| **EC2** | AWS | ~$0.02 | AWS credentials |
| **Docker** | Docker | $0.00 | Docker running |

Both paths teach the same `dynamic` block concepts - choose based on your setup!

## The Challenge

Build infrastructure that:

1. Fetches Pokemon data from the API
2. Extracts their types (fire, water, electric, etc.)
3. **EC2**: Creates a security group with dynamic ingress rules based on types
4. **Docker**: Creates containers with dynamic port mappings or environment variables based on types
5. Maps each Pokemon type to a specific port number
6. Uses `lookup()` for safe port mapping with fallbacks
7. Demonstrates filtering (e.g., only certain type categories)

## How Dynamic Blocks Work

### Basic Structure

```hcl
resource "aws_security_group" "example" {
  name = "example"

  # Instead of writing multiple ingress blocks...
  dynamic "ingress" {
    for_each = var.ports      # Iterate over this collection
    content {                  # Define what each block looks like
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

### Iterator Variables

```hcl
dynamic "ingress" {
  for_each = var.ports
  
  # Default iterator name matches the block name
  # ingress.key   = index or map key
  # ingress.value = the current item
  
  content {
    from_port = ingress.value
  }
}

# Custom iterator name
dynamic "ingress" {
  for_each = var.ports
  iterator = port           # Use 'port' instead of 'ingress'
  
  content {
    from_port = port.value  # Now use port.value
  }
}
```

### With Maps

```hcl
variable "port_rules" {
  default = {
    http  = { port = 80, description = "HTTP" }
    https = { port = 443, description = "HTTPS" }
    ssh   = { port = 22, description = "SSH" }
  }
}

dynamic "ingress" {
  for_each = var.port_rules
  content {
    description = ingress.value.description
    from_port   = ingress.value.port
    to_port     = ingress.value.port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## Pokemon Type → Port Mapping

In this exercise, we'll map Pokemon types to network ports:

```hcl
locals {
  type_ports = {
    fire     = 8080  # Hot port for Fire types
    water    = 8081  # Flows through
    electric = 443   # High voltage (HTTPS)
    grass    = 80    # Grows anywhere (HTTP)
    normal   = 22    # Basic SSH
    psychic  = 8443  # Mind-bending secure
    ghost    = 666   # Spooky!
    dragon   = 9000  # Over 9000!
    fighting = 3000  # Battle port
    flying   = 8888  # Up in the air
    poison   = 5432  # Database port (it spreads!)
    ground   = 8082  # Down to earth
    rock     = 8083  # Solid foundation
    bug      = 8084  # Debug port
    ice      = 8085  # Cool port
    fairy    = 8086  # Magical
    steel    = 8087  # Reinforced
    dark     = 8088  # Shadow port
  }
}
```

## Directory Structure

```
exercise-05-dynamic-types/
├── README.md           # This file
├── ec2/
│   ├── starter/
│   │   └── main.tf
│   └── solution/
│       └── main.tf
└── docker/
    ├── starter/
    │   └── main.tf
    └── solution/
        └── main.tf
```

## Instructions

### Step 1: Choose Your Path

```bash
# EC2 Path
cd ec2/starter/
# Complete the TODOs

# OR Docker Path
cd docker/starter/
# Complete the TODOs
```

### Step 2: Understand the Pattern

Your task is to:

1. Fetch Pokemon data for a team (use the map variable pattern from Exercise 04)
2. Extract all unique types from your Pokemon
3. Create a map of type → port mappings
4. Use `dynamic` blocks to generate rules/configurations for each type
5. Use `lookup()` to handle types not in your port map

### Step 3: Apply and Test

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

### Step 4: Verify Dynamic Generation

**For EC2:** Check the security group in AWS Console - you should see one ingress rule per unique Pokemon type in your squad!

**For Docker:** Check container configurations - you should see dynamic port mappings or environment variables based on types!

## Success Criteria

- [ ] Fetches Pokemon data from API
- [ ] Extracts unique types from Pokemon
- [ ] Uses `dynamic` blocks to generate nested configuration
- [ ] Maps Pokemon types to ports using `lookup()`
- [ ] Handles unknown types with default fallback
- [ ] Creates one rule/config per unique type
- [ ] Outputs show which types map to which ports

## Key Concepts

### The `lookup()` Function

Safely retrieve values from a map with a default fallback:

```hcl
lookup(map, key, default)

# Example:
lookup(local.type_ports, "fire", 8000)     # Returns 8080
lookup(local.type_ports, "unknown", 8000)  # Returns 8000 (default)
```

### Getting Unique Types

Pokemon can have multiple types (e.g., Bulbasaur is grass/poison). Extract unique types:

```hcl
locals {
  # Flatten all types from all Pokemon
  all_types = flatten([
    for name, p in local.pokemon_data : [
      for t in p.types : t.type.name
    ]
  ])

  # Get unique types only
  unique_types = toset(local.all_types)
}
```

### Conditional Dynamic Blocks

You can conditionally generate blocks:

```hcl
dynamic "ingress" {
  # Only create rules for "special" types
  for_each = toset([
    for t in local.unique_types : t
    if contains(["fire", "water", "electric"], t)
  ])

  content {
    # ... rule config
  }
}
```

## Hints

<details>
<summary>Hint 1: Extracting Pokemon Types</summary>

Pokemon data from the API has types in a nested structure:

```hcl
locals {
  pokemon_data = {
    for name, response in data.http.pokemon : name => jsondecode(response.response_body)
  }

  # Extract types for each Pokemon
  pokemon_types = {
    for name, p in local.pokemon_data : name => [
      for t in p.types : t.type.name
    ]
  }

  # Flatten to get all types
  all_types = flatten(values(local.pokemon_types))

  # Get unique types
  unique_types = toset(local.all_types)
}
```

</details>

<details>
<summary>Hint 2: Dynamic Security Group Rules (EC2)</summary>

```hcl
resource "aws_security_group" "pokemon_types" {
  name        = "pokemon-types-sg"
  description = "Dynamic rules based on Pokemon types"

  dynamic "ingress" {
    for_each = local.unique_types

    content {
      description = "Port for ${ingress.value} type Pokemon"
      from_port   = lookup(local.type_ports, ingress.value, 8000)
      to_port     = lookup(local.type_ports, ingress.value, 8000)
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Always allow outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

</details>

<details>
<summary>Hint 3: Dynamic Container Ports (Docker)</summary>

```hcl
resource "docker_container" "pokemon" {
  for_each = var.pokemon

  name  = "pokemon-${each.key}"
  image = docker_image.nginx.image_id

  # Dynamic port mapping based on Pokemon types
  dynamic "ports" {
    for_each = local.pokemon_types[each.key]

    content {
      internal = 80
      external = lookup(local.type_ports, ports.value, 8000)
    }
  }

  # Or use dynamic env variables
  dynamic "env" {
    for_each = local.pokemon_types[each.key]

    content {
      name  = "POKEMON_TYPE_${upper(env.value)}"
      value = lookup(local.type_ports, env.value, 8000)
    }
  }
}
```

</details>

<details>
<summary>Hint 4: Filtering Types</summary>

Create rules only for primary types (offensive types):

```hcl
locals {
  primary_types = ["fire", "water", "electric", "grass", "dragon", "psychic"]

  filtered_types = toset([
    for t in local.unique_types : t
    if contains(local.primary_types, t)
  ])
}

dynamic "ingress" {
  for_each = local.filtered_types
  # ... rest of config
}
```

</details>

## When to Use Dynamic Blocks

| Use Case | Use Dynamic? |
|----------|--------------|
| Configuration is known at write time | ❌ Use explicit blocks |
| Number of blocks varies based on input | ✅ Use dynamic |
| Blocks are identical or formulaic | ✅ Use dynamic |
| Need to generate 0 or many blocks | ✅ Use dynamic |
| Each block is unique and complex | ❌ Use explicit blocks |

**Warning:** Don't overuse dynamic blocks! They can make code harder to read. Use them when you truly need dynamic generation.

## Stretch Goals

1. **Type Categories**: Group types into categories (offensive, defensive, special) and create separate rule sets
2. **Priority Rules**: Assign priority to each type and create ordered rules
3. **Multi-Protocol**: Generate both TCP and UDP rules for certain types
4. **Type Effectiveness**: Use the PokeAPI type endpoint to fetch type effectiveness data and create rules based on damage relationships
5. **Conditional Generation**: Only create rules for types if your Pokemon has high stats

## Cleanup

```bash
terraform destroy
```

**EC2**: Verify security group is deleted in AWS Console
**Docker**: Verify with `docker ps` and `docker network ls`

## What's Next?

You've mastered all the core concepts! Now it's time for the **Challenge: Pokedex Infrastructure** - a capstone exercise that combines everything you've learned!

---

**Gotta Configure 'Em All!** 🎮⚡
