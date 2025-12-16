# Exercise 03: VM Squad with `count`

**Time:** 30 minutes | **Difficulty:** ⭐⭐ Intermediate | **Cost:** ~$0.02 (EC2) or $0.00 (Docker)

## Objective

Create multiple compute instances named after Pokemon fetched from the PokeAPI! Learn how `count` and `count.index` work by building a "squad" of VMs.

## What You'll Learn

- Using `count` to create multiple resources
- Accessing `count.index` for unique values per resource
- Chaining data sources with count
- Using `element()` and list indexing
- The key limitation of `count` (and why `for_each` exists!)

## Choose Your Path

| Path | Provider | Cost | Requirements |
|------|----------|------|--------------|
| **EC2** | AWS | ~$0.02 | AWS credentials |
| **Docker** | Docker | $0.00 | Docker running |

Both paths teach the same `count` concepts - choose based on your setup!

## The Challenge

Build infrastructure that:

1. Takes a list of Pokemon IDs as input (e.g., `[1, 4, 7]` for the original starters)
2. Fetches each Pokemon's data from the PokeAPI
3. Creates a compute instance for each Pokemon, named after it
4. Tags/labels each instance with Pokemon metadata
5. Outputs the full squad roster

## How `count` Works

```hcl
# Create 3 instances
resource "aws_instance" "example" {
  count = 3

  tags = {
    Name = "server-${count.index}"  # server-0, server-1, server-2
  }
}

# Access specific instance
aws_instance.example[0]  # First instance
aws_instance.example[1]  # Second instance

# Access all instances
aws_instance.example[*].id  # List of all IDs
```

### With a List Variable

```hcl
variable "pokemon_ids" {
  default = [1, 4, 7]  # bulbasaur, charmander, squirtle
}

resource "aws_instance" "pokemon" {
  count = length(var.pokemon_ids)

  tags = {
    PokemonID = var.pokemon_ids[count.index]  # 1, 4, 7
  }
}
```

## The Count Problem (Important!)

**What happens if you remove an item from the middle of the list?**

```hcl
# Original: [1, 4, 7] creates instances at index 0, 1, 2
# Remove 4: [1, 7] 

# Terraform sees:
# - Index 0: was ID 1, still ID 1 ✅ No change
# - Index 1: was ID 4, now ID 7 ❌ DESTROY and RECREATE!
# - Index 2: was ID 7, now gone ❌ DESTROY!
```

**This is why `for_each` was invented!** You'll learn it in Exercise 04.

## Directory Structure

```
exercise-03-vm-squad-count/
├── README.md           # This file
├── ec2/
│   ├── starter/
│   └── solution/
└── docker/
    ├── starter/
    └── solution/
```

## Instructions

### EC2 Path

```bash
cd ec2/
cp -r starter/ my-solution/
cd my-solution/
# Complete the TODOs
terraform init && terraform apply
```

### Docker Path

```bash
cd docker/
cp -r starter/ my-solution/
cd my-solution/
# Complete the TODOs
terraform init && terraform apply
```

## Success Criteria

- [ ] Creates 3 compute instances (or as many Pokemon IDs provided)
- [ ] Each instance is named after its Pokemon
- [ ] Pokemon data is fetched from the real API
- [ ] Tags/labels include Pokemon type and ID
- [ ] Outputs show the full squad roster
- [ ] Can add/remove Pokemon by changing the variable

## Testing the Count Problem

After your initial deploy works, try this experiment:

1. Start with `pokemon_ids = [1, 4, 7]` - Apply
2. Change to `pokemon_ids = [1, 7]` - Plan (don't apply!)
3. Observe: Which instances does Terraform want to destroy/recreate?
4. This demonstrates why `count` can be dangerous for production workloads!

## Hints

<details>
<summary>Hint 1: Fetching Multiple Pokemon</summary>

Use `count` on the data source too:

```hcl
data "http" "pokemon" {
  count = length(var.pokemon_ids)
  url   = "https://pokeapi.co/api/v2/pokemon/${var.pokemon_ids[count.index]}"
}
```

</details>

<details>
<summary>Hint 2: Extracting Names</summary>

Parse each response and extract names:

```hcl
locals {
  pokemon_data = [
    for i, response in data.http.pokemon : jsondecode(response.response_body)
  ]
  pokemon_names = [for p in local.pokemon_data : p.name]
}
```

</details>

<details>
<summary>Hint 3: Matching Indices</summary>

The key is that `count.index` in the data source matches `count.index` in the resource:

```hcl
resource "aws_instance" "pokemon" {
  count = length(var.pokemon_ids)
  
  tags = {
    Name = local.pokemon_names[count.index]  # Same index!
  }
}
```

</details>

## Stretch Goals

1. **Add HP to tags**: Include the Pokemon's HP stat in the instance tags
2. **Type-based instance sizing**: Use larger instances for Pokemon with higher HP
3. **Output sprite URLs**: Include the Pokemon sprite URLs in outputs
4. **Experiment with count changes**: See what happens when you reorder the list

## Cleanup

**Important!** Don't forget to destroy your resources:

```bash
terraform destroy
```

For EC2: Verify no running instances in the AWS Console
For Docker: Verify with `docker ps`

## What's Next?

Exercise 04 teaches `for_each` - the solution to the count problem. You'll create the same Pokemon squad but with stable resource addressing!

---

**Gotta Deploy 'Em All!** 🎮
