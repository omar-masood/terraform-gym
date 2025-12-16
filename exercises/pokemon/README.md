# 🎮 Deploy 'Em All: Pokemon Infrastructure Series

**Master advanced Terraform through Pokemon!**

Learn `count`, `for_each`, complex types, dynamic blocks, and API data sources by building infrastructure named after your favorite Pokemon.

## Series Overview

| Exercise | Concept | Time | Difficulty |
|----------|---------|------|------------|
| [01: Pokemon Data](#exercise-01) | Data sources, JSON parsing, locals | 20 min | ⭐ Beginner |
| [02: Pokemon Types](#exercise-02) | Custom object types, validation | 25 min | ⭐⭐ Intermediate |
| [03: VM Squad (count)](#exercise-03) | `count`, `count.index`, EC2/Docker | 30 min | ⭐⭐ Intermediate |
| [04: VM Squad (for_each)](#exercise-04) | `for_each`, `each.key`, comparing approaches | 30 min | ⭐⭐ Intermediate |
| [05: Dynamic Types](#exercise-05) | Dynamic blocks, conditional logic | 30 min | ⭐⭐⭐ Advanced |
| [Challenge: Pokedex Infra](#challenge) | Combine everything! | 45-60 min | ⭐⭐⭐ Advanced |

## The Pokemon API

We'll use the free [PokeAPI](https://pokeapi.co/) - no authentication required!

### Quick API Reference

**Get a Pokemon by name or ID:**
```bash
curl https://pokeapi.co/api/v2/pokemon/pikachu
curl https://pokeapi.co/api/v2/pokemon/25
```

**Get a Pokemon type:**
```bash
curl https://pokeapi.co/api/v2/type/electric
```

### Key API Response Fields

When you fetch a Pokemon, you get a LOT of data. Here are the fields we'll use:

```json
{
  "id": 25,
  "name": "pikachu",
  "height": 4,
  "weight": 60,
  "types": [
    {
      "slot": 1,
      "type": {
        "name": "electric",
        "url": "https://pokeapi.co/api/v2/type/13/"
      }
    }
  ],
  "stats": [
    {
      "base_stat": 35,
      "stat": {
        "name": "hp"
      }
    },
    {
      "base_stat": 55,
      "stat": {
        "name": "attack"
      }
    }
  ],
  "sprites": {
    "front_default": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/25.png"
  }
}
```

### Testing the API

Before writing Terraform, always test with curl:

```bash
# Get Pikachu
curl -s https://pokeapi.co/api/v2/pokemon/pikachu | jq '.name, .id, .types[].type.name'

# Get the original starters
curl -s https://pokeapi.co/api/v2/pokemon/1 | jq '.name'   # bulbasaur
curl -s https://pokeapi.co/api/v2/pokemon/4 | jq '.name'   # charmander  
curl -s https://pokeapi.co/api/v2/pokemon/7 | jq '.name'   # squirtle

# Get type info
curl -s https://pokeapi.co/api/v2/type/fire | jq '.name, .damage_relations.double_damage_to[].name'
```

## Prerequisites

- Terraform 1.9.0+
- For EC2 exercises: AWS credentials configured
- For Docker exercises: Docker running (available in devcontainer)
- Internet access (to reach PokeAPI)

## Learning Path

### Path A: Cloud Focus (AWS)
Complete exercises using EC2 instances:
1. Exercise 01 → 02 → 03-ec2 → 04-ec2 → 05 → Challenge

### Path B: Local Focus (Docker)
Complete exercises using Docker containers:
1. Exercise 01 → 02 → 03-docker → 04-docker → 05 → Challenge

### Path C: Compare Both
Do both EC2 and Docker versions to understand provider differences:
1. Exercise 01 → 02 → 03-ec2 → 03-docker → 04-ec2 → 04-docker → 05 → Challenge

## Quick Reference: Pokemon IDs

| ID | Pokemon | Type | Notes |
|----|---------|------|-------|
| 1 | Bulbasaur | Grass/Poison | Starter |
| 4 | Charmander | Fire | Starter |
| 7 | Squirtle | Water | Starter |
| 25 | Pikachu | Electric | Mascot |
| 39 | Jigglypuff | Normal/Fairy | |
| 52 | Meowth | Normal | |
| 94 | Gengar | Ghost/Poison | |
| 130 | Gyarados | Water/Flying | |
| 143 | Snorlax | Normal | |
| 149 | Dragonite | Dragon/Flying | |
| 150 | Mewtwo | Psychic | Legendary |
| 151 | Mew | Psychic | Mythical |

## Concepts You'll Master

### From the TF Associate Exam

| Objective | Exercise Coverage |
|-----------|-------------------|
| 4d: Complex types | Exercise 02, 03, 04 |
| 4e: Functions & expressions | Exercise 01, 03, 04, 05 |
| 4f: Resource dependencies | Exercise 03, 04, 05 |
| 4g: Custom conditions | Exercise 02, Challenge |

### Terraform Features

- `data "http"` - Fetching external API data
- `jsondecode()` - Parsing JSON responses
- `locals` - Computed values
- `count` and `count.index` - Creating multiple resources
- `for_each`, `each.key`, `each.value` - Map-based iteration
- `for` expressions - Transforming data
- `dynamic` blocks - Generating nested blocks
- `object()` type - Custom complex types
- `validation` blocks - Input validation
- `lookup()`, `try()`, `can()` - Safe value access

## Directory Structure

```
pokemon/
├── README.md                          # This file
├── exercise-01-pokemon-data/
│   ├── README.md
│   ├── starter/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── solution/
│       └── main.tf
├── exercise-02-pokemon-types/
├── exercise-03-vm-squad-count/
│   ├── ec2/                           # AWS version
│   └── docker/                        # Docker version
├── exercise-04-vm-squad-foreach/
│   ├── ec2/
│   └── docker/
├── exercise-05-dynamic-types/
└── challenge-pokedex-infra/
    ├── LAB.md
    ├── RUBRIC.md
    ├── starter/
    └── solution/
```

## Tips for Success

1. **Test APIs with curl first** - Understand the JSON structure before writing Terraform
2. **Use `terraform console`** - Great for testing expressions interactively
3. **Read error messages carefully** - Terraform errors tell you exactly what's wrong
4. **Compare count vs for_each** - Understanding the difference is crucial for the exam!

## Getting Started

```bash
cd terraform-gym/exercises/pokemon/exercise-01-pokemon-data
cat README.md
```

---

**Gotta Deploy 'Em All!** 🎮⚡
