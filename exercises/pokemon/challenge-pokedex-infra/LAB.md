# Challenge: Pokedex Infrastructure

**Time:** 45-60 minutes | **Difficulty:** ⭐⭐⭐ Advanced | **Cost:** ~$0.05 (EC2) or $0.00 (Docker)

## Scenario

You're a Pokemon Trainer who's decided to modernize your Pokemon Gym by deploying infrastructure for your entire team! Your gym needs:

- A compute instance for each Pokemon on your team
- Security rules based on Pokemon types
- Proper validation to ensure only valid Pokemon teams
- A beautiful Pokedex report showing your team's stats

This is the **capstone exercise** - it combines EVERYTHING you've learned in exercises 01-05!

## What You'll Demonstrate

By completing this challenge, you'll prove you can:

- ✅ Fetch external API data (`data "http"`, `jsondecode()`)
- ✅ Define and validate complex types (`object()`, `list(object())`)
- ✅ Use `for_each` for stable resource addressing
- ✅ Generate configuration with `dynamic` blocks
- ✅ Apply custom conditions (`validation`, `precondition`, `postcondition`)
- ✅ Transform data with `for` expressions
- ✅ Use functions like `lookup()`, `flatten()`, `try()`, `can()`
- ✅ Create comprehensive outputs

## Challenge Requirements

### 1. Pokemon Team Variable (10 points)

Define a `pokemon_team` variable that:

- Type: `list(object({ name = string, id = number }))`
- Minimum 1 Pokemon, maximum 6 (like a real Pokemon team!)
- Each Pokemon must have:
  - `name`: The Pokemon's name (lowercase)
  - `id`: The Pokemon's ID number (1-1010)
- Add validation blocks to enforce these constraints

**Example:**
```hcl
pokemon_team = [
  { name = "bulbasaur", id = 1 },
  { name = "charmander", id = 4 },
  { name = "squirtle", id = 7 },
  { name = "pikachu", id = 25 },
]
```

### 2. Fetch Pokemon Data (10 points)

For each Pokemon in your team:

- Fetch data from the PokeAPI: `https://pokeapi.co/api/v2/pokemon/{id}`
- Parse the JSON response with `jsondecode()`
- Extract:
  - Name
  - ID
  - Types (list)
  - HP stat
  - Sprite URL (front_default)

### 3. Create Infrastructure with for_each (15 points)

**Choose ONE path:**

**EC2 Path:**
- Create EC2 instances using `for_each` (NOT `count`!)
- One instance per Pokemon
- Key by Pokemon name for stable addressing
- Use `t3.micro` instances

**Docker Path:**
- Create Docker containers using `for_each`
- One container per Pokemon
- Key by Pokemon name
- Use `nginx:alpine` image

### 4. Tag/Label Resources (10 points)

Each instance/container must have tags/labels including:

- Pokemon name
- Pokemon ID
- Pokemon types (as comma-separated string)
- Pokemon HP
- Your trainer name
- Environment: "pokemon-gym"

### 5. Dynamic Security Configuration (20 points)

**EC2 Path:**
- Create a security group with dynamic ingress rules
- One rule per unique Pokemon type across your team
- Map types to ports (fire=8080, water=8081, etc.)
- Use `lookup()` with a default fallback (8000)
- Attach security group to all instances

**Docker Path:**
- Add dynamic environment variables to each container
- One env var per Pokemon type: `POKEMON_TYPE_<TYPE>=<port>`
- Use `lookup()` with a default fallback (8000)
- Add dynamic labels for each type

### 6. Custom Conditions (10 points)

Add these validation checks:

**Precondition** on instances/containers:
- Pokemon HP must be greater than 30
- Location: Inside the resource block
- Error message: "Only Pokemon with HP > 30 can battle! {name} has HP {hp}."

**Variable validation**:
- Team size must be 1-6
- Pokemon IDs must be 1-1010
- Pokemon names must be lowercase with no spaces

### 7. Comprehensive Outputs (15 points)

Create outputs that display:

**`team_roster`**: A map showing each Pokemon with:
- Pokemon name, ID, types
- Instance ID / Container ID
- HP
- Sprite URL

**`pokedex_report`**: A formatted multi-line string showing:
```
=================================
    POKEMON GYM POKEDEX
=================================

Trainer: <your name>
Team Size: X Pokemon

POKEMON ROSTER:
1. BULBASAUR (ID: 1)
   Types: grass, poison
   HP: 45
   Instance: i-xxxxx / Container: pokemon-bulbasaur

2. CHARMANDER (ID: 4)
   ...

TEAM STATS:
- Total HP: XXX
- Types: grass, poison, fire, water (X unique)
- Strongest: POKEMON_NAME (HP: XX)

INFRASTRUCTURE:
- Instances/Containers: X
- Security Rules: X (EC2) / Env Vars: X (Docker)
```

**`type_coverage`**: Map of type → list of Pokemon with that type

**`team_stats`**: Object with total_hp, unique_types_count, strongest_pokemon

### 8. Stretch Goals (Bonus 10 points)

Choose any 2:

- **S3 Bucket for Sprites**: Create an S3 bucket to store Pokemon sprites
- **Trainer Card**: Use `templatefile()` to generate an HTML trainer card
- **Multiple Environments**: Support "gym-leader" vs "trainer" configurations
- **Type Effectiveness**: Fetch type data and show strengths/weaknesses
- **Auto-scaling Groups**: Create ASG instead of individual instances (EC2 only)

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                  PokeAPI                             │
│      https://pokeapi.co/api/v2/pokemon/{id}         │
└────────────────────┬────────────────────────────────┘
                     │ HTTP GET
                     ↓
┌─────────────────────────────────────────────────────┐
│              Terraform (You!)                        │
│  ┌─────────────────────────────────────────────┐   │
│  │  Variable: pokemon_team                      │   │
│  │  [bulbasaur, charmander, squirtle, ...]     │   │
│  └─────────────────────────────────────────────┘   │
│                     │                                │
│                     ↓                                │
│  ┌─────────────────────────────────────────────┐   │
│  │  Data Source: http (for_each)               │   │
│  │  Fetch each Pokemon's data                  │   │
│  └─────────────────────────────────────────────┘   │
│                     │                                │
│                     ↓                                │
│  ┌─────────────────────────────────────────────┐   │
│  │  Locals: Parse & Transform                  │   │
│  │  - pokemon_data (jsondecode)                │   │
│  │  - pokemon_types                            │   │
│  │  - unique_types (flatten + toset)           │   │
│  └─────────────────────────────────────────────┘   │
│                     │                                │
│        ┌────────────┴────────────┐                  │
│        ↓                         ↓                   │
│  ┌──────────────┐      ┌──────────────────┐        │
│  │ EC2 / Docker │      │ Security Group / │        │
│  │  (for_each)  │      │ Dynamic Env Vars │        │
│  │              │      │  (dynamic block) │        │
│  └──────────────┘      └──────────────────┘        │
└─────────────────────────────────────────────────────┘
                     │
                     ↓
         ┌───────────────────────┐
         │   Pokedex Report      │
         │   (outputs)           │
         └───────────────────────┘
```

## Setup Instructions

### Step 1: Choose Your Path

```bash
# EC2 Path (requires AWS credentials)
cd starter/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your team

# OR Docker Path (no AWS needed)
cd starter/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your team
```

### Step 2: Define Your Team

Edit `terraform.tfvars`:

```hcl
pokemon_team = [
  { name = "bulbasaur", id = 1 },
  { name = "charmander", id = 4 },
  { name = "squirtle", id = 7 },
  { name = "pikachu", id = 25 },
  { name = "snorlax", id = 143 },
  { name = "dragonite", id = 149 },
]

student_name = "your-name"
```

### Step 3: Implement the Challenge

Work through each file:

1. **variables.tf**: Define variables with validation
2. **main.tf**: Implement data sources, locals, and resources
3. **outputs.tf**: Create comprehensive outputs

### Step 4: Test and Validate

```bash
terraform init
terraform validate
terraform fmt
terraform plan
```

### Step 5: Deploy!

```bash
terraform apply
```

### Step 6: Admire Your Pokedex

```bash
terraform output pokedex_report
```

### Step 7: Clean Up

```bash
terraform destroy
```

## Success Criteria Checklist

Use this checklist to verify you've completed all requirements:

- [ ] Variable `pokemon_team` defined with proper type
- [ ] Validation: Team size 1-6
- [ ] Validation: Pokemon IDs 1-1010
- [ ] Validation: Names are lowercase
- [ ] Fetches data for each Pokemon from API
- [ ] Uses `for_each` (NOT `count`) for resources
- [ ] Resources keyed by Pokemon name
- [ ] All required tags/labels present
- [ ] Dynamic security config based on types
- [ ] Uses `lookup()` with default fallback
- [ ] Precondition checks HP > 30
- [ ] Output: `team_roster` with all details
- [ ] Output: `pokedex_report` formatted nicely
- [ ] Output: `type_coverage` map
- [ ] Output: `team_stats` object
- [ ] Code is formatted (`terraform fmt`)
- [ ] Code validates (`terraform validate`)
- [ ] Plan shows expected resources
- [ ] Apply succeeds without errors
- [ ] Outputs display correctly

## Hints

<details>
<summary>Hint 1: Variable Validation</summary>

```hcl
variable "pokemon_team" {
  type = list(object({
    name = string
    id   = number
  }))

  validation {
    condition     = length(var.pokemon_team) >= 1 && length(var.pokemon_team) <= 6
    error_message = "Pokemon team must have 1-6 Pokemon (you have ${length(var.pokemon_team)})."
  }

  validation {
    condition = alltrue([
      for p in var.pokemon_team : p.id >= 1 && p.id <= 1010
    ])
    error_message = "Pokemon IDs must be between 1 and 1010."
  }

  validation {
    condition = alltrue([
      for p in var.pokemon_team : can(regex("^[a-z0-9-]+$", p.name))
    ])
    error_message = "Pokemon names must be lowercase with no spaces."
  }
}
```

</details>

<details>
<summary>Hint 2: Fetching Pokemon Data</summary>

```hcl
# Convert list to map for for_each
locals {
  pokemon_map = {
    for p in var.pokemon_team : p.name => p
  }
}

data "http" "pokemon" {
  for_each = local.pokemon_map

  url = "https://pokeapi.co/api/v2/pokemon/${each.value.id}"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  pokemon_data = {
    for name, response in data.http.pokemon : name => jsondecode(response.response_body)
  }
}
```

</details>

<details>
<summary>Hint 3: Extracting HP from Stats</summary>

```hcl
locals {
  pokemon_hp = {
    for name, p in local.pokemon_data : name => [
      for s in p.stats : s.base_stat if s.stat.name == "hp"
    ][0]
  }
}
```

</details>

<details>
<summary>Hint 4: Precondition Example</summary>

```hcl
resource "aws_instance" "pokemon" {
  for_each = local.pokemon_map

  # ... other config

  lifecycle {
    precondition {
      condition     = local.pokemon_hp[each.key] > 30
      error_message = "Only Pokemon with HP > 30 can battle! ${each.key} has HP ${local.pokemon_hp[each.key]}."
    }
  }
}
```

</details>

<details>
<summary>Hint 5: Dynamic Blocks</summary>

```hcl
# For security group (EC2)
resource "aws_security_group" "pokemon_gym" {
  dynamic "ingress" {
    for_each = local.unique_types

    content {
      description = "Port for ${ingress.value} type"
      from_port   = lookup(local.type_ports, ingress.value, 8000)
      to_port     = lookup(local.type_ports, ingress.value, 8000)
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

# For containers (Docker)
resource "docker_container" "pokemon" {
  for_each = local.pokemon_map

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
<summary>Hint 6: Formatted Pokedex Report</summary>

```hcl
output "pokedex_report" {
  value = <<-EOT
    =================================
        POKEMON GYM POKEDEX
    =================================

    Trainer: ${var.student_name}
    Team Size: ${length(var.pokemon_team)} Pokemon

    POKEMON ROSTER:
    %{for idx, p in var.pokemon_team~}
    ${idx + 1}. ${upper(p.name)} (ID: ${p.id})
       Types: ${join(", ", local.pokemon_types[p.name])}
       HP: ${local.pokemon_hp[p.name]}
       Instance: ${aws_instance.pokemon[p.name].id}

    %{endfor~}
    TEAM STATS:
    - Total HP: ${sum(values(local.pokemon_hp))}
    - Types: ${join(", ", sort(tolist(local.unique_types)))} (${length(local.unique_types)} unique)

  EOT
}
```

</details>

## Common Pitfalls

1. **Using `count` instead of `for_each`**: The requirements specifically ask for `for_each`!

2. **List vs Map for for_each**: Remember, `for_each` needs a map or set, not a list. Convert your list to a map first.

3. **Forgetting `tostring()` in labels**: Docker labels must be strings. Use `tostring(p.id)`.

4. **HP extraction**: HP is nested in the stats array. Use a `for` expression with a filter.

5. **Unique types**: Don't forget to flatten and deduplicate types across all Pokemon!

6. **Preconditions**: They go inside a `lifecycle` block, not directly in the resource.

## Validation Strategy

Before applying, test each component:

```bash
# Test variable validation
terraform validate

# Check data fetching
terraform console
> data.http.pokemon
> local.pokemon_data

# Verify type extraction
> local.pokemon_types
> local.unique_types

# Check HP extraction
> local.pokemon_hp
```

## What's Being Tested

This challenge tests your ability to:

| Concept | From Exercise | Points |
|---------|---------------|--------|
| Fetch API data | Exercise 01 | 10 |
| Complex types & validation | Exercise 02 | 10 |
| for_each usage | Exercise 04 | 15 |
| Dynamic blocks | Exercise 05 | 20 |
| Conditions & checks | Exercise 02 | 10 |
| Data transformation | All | 15 |
| Outputs | All | 15 |
| **Bonus** | - | 10 |

## Time Management

Recommended time allocation:

- **10 min**: Setup and variable definitions
- **15 min**: Data fetching and parsing
- **10 min**: Resource creation with for_each
- **10 min**: Dynamic security configuration
- **10 min**: Outputs
- **5 min**: Testing and validation

## After You Finish

1. **Review the solution**: Compare your approach to the reference solution
2. **Experiment**: Try different Pokemon teams, types, conditions
3. **Break things**: Remove a Pokemon mid-apply and see what happens
4. **Optimize**: Can you make the code more concise? More readable?

## Need Help?

- Review the exercise READMEs for exercises 01-05
- Check the hints (but try on your own first!)
- Use `terraform console` to debug expressions
- Read Terraform error messages carefully - they're usually helpful!

---

**Good luck, Trainer! May the best team win!** 🎮⚡

*Gotta Deploy 'Em All!*
