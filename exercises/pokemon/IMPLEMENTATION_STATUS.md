# 🎮 Deploy 'Em All: Pokemon Infrastructure Series

## Implementation Status & Roadmap

**Last Updated:** December 16, 2025

---

## Series Overview

A progressive exercise series teaching advanced Terraform concepts through Pokemon, building on the existing `api-explorer` exercise foundation. Students fetch real data from the PokeAPI and use it to create infrastructure.

### Learning Objectives (TF Associate 004)

| Objective | Description | Exercise Coverage |
|-----------|-------------|-------------------|
| 4d | Complex types (`object`, `list`, `map`) | Exercise 02, 03, 04 |
| 4e | Functions & expressions (`for`, `for_each`, `count`) | Exercise 01, 03, 04, 05 |
| 4f | Resource dependencies | Exercise 03, 04, 05 |
| 4g | Custom conditions & validation | Exercise 02, Challenge |

---

## Implementation Status

### ✅ Complete

| Exercise | README | Starter | Solution | Notes |
|----------|:------:|:-------:|:--------:|-------|
| **Series README** | ✅ | - | - | Overview, API docs, learning paths |
| **01: Pokemon Data** | ✅ | ✅ | ✅ | `data "http"`, `jsondecode()`, locals |
| **02: Pokemon Types** | ✅ | ✅ | ✅ | `object()`, `list(object())`, validation |
| **03: VM Squad (count)** | ✅ | ✅ EC2 | ✅ EC2 | `count`, `count.index` |
| **03: VM Squad (count)** | ✅ | ✅ Docker | ✅ Docker | Same concepts, no AWS needed |
| **04: VM Squad (for_each)** | ✅ | ✅ EC2 | ✅ EC2 | `for_each`, `each.key`, stable addressing |
| **04: VM Squad (for_each)** | ✅ | ✅ Docker | ✅ Docker | Same concepts, no AWS needed |

### ✅ Complete (Continued)

| Exercise | README | Starter | Solution | Notes |
|----------|:------:|:-------:|:--------:|-------|
| **05: Dynamic Types** | ✅ | ✅ EC2 | ✅ EC2 | `dynamic` blocks, conditional logic |
| **05: Dynamic Types** | ✅ | ✅ Docker | ✅ Docker | Dynamic env vars and labels |
| **Challenge: Pokedex Infra** | ✅ LAB.md | ✅ | ✅ | Capstone combining all concepts |
| **Challenge: Pokedex Infra** | ✅ RUBRIC.md | ✅ | ✅ | Grading criteria included |

---

## Directory Structure

```
terraform-gym/exercises/pokemon/
├── README.md                           ✅ Complete
├── IMPLEMENTATION_STATUS.md            ✅ This file
│
├── exercise-01-pokemon-data/           ✅ Complete
│   ├── README.md
│   ├── starter/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── solution/
│       └── main.tf
│
├── exercise-02-pokemon-types/          ✅ Complete
│   ├── README.md
│   ├── starter/
│   │   └── variables.tf
│   └── solution/
│       └── main.tf
│
├── exercise-03-vm-squad-count/         ✅ Complete
│   ├── README.md
│   ├── ec2/
│   │   ├── starter/main.tf
│   │   └── solution/main.tf
│   └── docker/
│       ├── starter/main.tf
│       └── solution/main.tf
│
├── exercise-04-vm-squad-foreach/       ✅ Complete
│   ├── README.md
│   ├── ec2/
│   │   ├── starter/main.tf
│   │   └── solution/main.tf
│   └── docker/
│       ├── starter/main.tf
│       └── solution/main.tf
│
├── exercise-05-dynamic-types/          ✅ Complete
│   ├── README.md
│   ├── ec2/
│   │   ├── starter/main.tf
│   │   └── solution/main.tf
│   └── docker/
│       ├── starter/main.tf
│       └── solution/main.tf
│
└── challenge-pokedex-infra/            ✅ Complete
    ├── LAB.md
    ├── RUBRIC.md
    ├── starter/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── terraform.tfvars.example
    └── solution/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── terraform.tfvars
```

---

## Remaining Work

### Exercise 05: Dynamic Types with Pokemon

**Concept:** Create security group rules dynamically based on Pokemon types

**Planned content:**
- Map Pokemon types to ports (fire=8080, water=8081, electric=443, etc.)
- Use `dynamic` blocks to generate ingress rules
- Demonstrate `lookup()` for safe value access
- Show conditional logic with `for_each` filtering

**Example pattern:**
```hcl
variable "pokemon_types" {
  type    = set(string)
  default = ["fire", "water", "electric"]
}

locals {
  type_ports = {
    fire     = 8080
    water    = 8081
    electric = 443
    grass    = 80
  }
}

resource "aws_security_group" "pokemon_sg" {
  dynamic "ingress" {
    for_each = var.pokemon_types
    content {
      description = "Port for ${ingress.value} type"
      from_port   = lookup(local.type_ports, ingress.value, 8000)
      to_port     = lookup(local.type_ports, ingress.value, 8000)
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

**Estimated effort:** 2-3 hours

---

### Challenge: Full Pokedex Infrastructure

**Concept:** Capstone exercise combining all learned skills

**Requirements:**
1. Fetch 6 Pokemon from the API (trainer's team)
2. Use custom types with validation (team size, HP range, valid types)
3. Deploy EC2/Docker instances using `for_each`
4. Create security groups with `dynamic` blocks based on Pokemon types
5. Use `precondition` to validate team composition
6. Output formatted "Pokedex Report"

**Stretch goals:**
- S3 bucket for Pokemon data storage (using course module)
- `templatefile()` for trainer card HTML generation
- Multiple environments (gym leaders vs trainers)

**Deliverables:**
- `LAB.md` - Full challenge specification
- `RUBRIC.md` - Grading criteria
- `starter/` - Scaffolded files with TODOs
- `solution/` - Complete reference implementation

**Estimated effort:** 4-6 hours

---

## Integration with terraform-course

### Proposed Week 3 Structure

| Day | terraform-course | terraform-gym |
|-----|------------------|---------------|
| Day 1 | Lab 0: Complex Types intro | Exercise 01-02: Pokemon Data & Types |
| Day 2 | Lab 0: `count` vs `for_each` | Exercise 03-04: VM Squad both ways |
| Day 3 | Lab 1: Conditions & Checks | Exercise 05: Dynamic blocks |
| Homework | - | Challenge: Full Pokedex Infra |

### Course Progression Update Needed

Update `terraform-course/COURSE_PROGRESSION.md` to include:
- Week 3: Advanced Configuration (Pokemon Edition!)
- References to terraform-gym Pokemon exercises
- Learning path options (EC2 vs Docker)

---

## Design Decisions

### Real API vs Mock Data
**Decision:** Use real PokeAPI
**Rationale:** Teaches API fluency, more engaging, builds on api-explorer exercise

### EC2 vs Docker
**Decision:** Both paths available
**Rationale:** 
- EC2: Real AWS experience, ties to main course
- Docker: Free, fast, works in devcontainer without AWS creds
- Students can choose or do both to compare

### Exercise Naming
**Decision:** "Deploy 'Em All" series
**Rationale:** Fun Pokemon reference, memorable

### Complexity Progression
1. **Exercise 01:** Pure data fetching, no resources created
2. **Exercise 02:** Type definitions only, no resources
3. **Exercise 03:** Resources with `count` (simpler but flawed)
4. **Exercise 04:** Resources with `for_each` (production pattern)
5. **Exercise 05:** Advanced patterns (`dynamic` blocks)
6. **Challenge:** Combine everything

---

## Testing Checklist

Before marking complete, each exercise should be tested:

- [ ] `terraform init` succeeds
- [ ] `terraform validate` passes
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` creates resources correctly
- [ ] Outputs display correct Pokemon data
- [ ] `terraform destroy` cleans up properly
- [ ] Works in devcontainer environment
- [ ] README instructions are accurate
- [ ] Hints are helpful but not giving away answers

### Tested Exercises

| Exercise | EC2 Tested | Docker Tested | Devcontainer |
|----------|:----------:|:-------------:|:------------:|
| 01 | N/A | N/A | ⬜ |
| 02 | N/A | N/A | ⬜ |
| 03 | ⬜ | ⬜ | ⬜ |
| 04 | ⬜ | ⬜ | ⬜ |
| 05 | ⬜ | ⬜ | ⬜ |
| Challenge | ⬜ | ⬜ | ⬜ |

---

## Quick Reference: Pokemon IDs

For exercise testing and examples:

| ID | Pokemon | Type | Notes |
|----|---------|------|-------|
| 1 | Bulbasaur | Grass/Poison | Starter |
| 4 | Charmander | Fire | Starter |
| 7 | Squirtle | Water | Starter |
| 25 | Pikachu | Electric | Mascot |
| 94 | Gengar | Ghost/Poison | Good for dual-type examples |
| 149 | Dragonite | Dragon/Flying | High stats |
| 150 | Mewtwo | Psychic | Legendary |

---

## Next Actions

1. **[✅] Create Exercise 05: Dynamic Types**
   - ✅ README with dynamic block explanation
   - ✅ Starter with TODOs
   - ✅ Solution with security group example
   - ✅ Both EC2 and Docker versions

2. **[✅] Create Challenge: Pokedex Infra**
   - ✅ LAB.md with full requirements
   - ✅ RUBRIC.md for grading
   - ✅ Starter scaffolding
   - ✅ Complete solution

3. **[ ] Test all exercises**
   - Run through each exercise end-to-end
   - Verify in devcontainer
   - Check Docker-in-Docker works

4. **[ ] Update INDEX.md**
   - Add Pokemon series to exercise index
   - Update difficulty ratings
   - Add time estimates

5. **[ ] Update terraform-course**
   - Create Week 03 structure
   - Link to Pokemon exercises
   - Update COURSE_PROGRESSION.md

---

## Related Files

- Series README: `/exercises/pokemon/README.md`
- Gym Index: `/exercises/INDEX.md`
- API Explorer (foundation): `/exercises/api-explorer/`
- Course Progression: `terraform-course/COURSE_PROGRESSION.md`

---

**Gotta Deploy 'Em All!** 🎮⚡
