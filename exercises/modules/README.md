# Terraform Modules: From Copy-Paste to Reusable Infrastructure

**Total Time:** ~3 hours  
**Difficulty:** Intermediate  
**Prerequisites:** Completed S3 exercises, comfortable with variables and outputs

---

## The Scenario

You're a platform engineer at **Acme Corp**. The Marketing team just submitted a ticket:

> "We need a website to preview campaign designs before launch. Can you spin up something quick?"

No problem—you deploy an S3 static website in 10 minutes. Done.

Then another ticket arrives:

> "This is great! Can we get a staging version for stakeholder review?"

You copy-paste your Terraform code, change a few names... done.

Then:

> "Perfect! Now we need the production version. Oh, and Security says all buckets need encryption enabled. Can you update all three?"

You stare at your three nearly-identical Terraform files. Change one, change all three. Miss one, fail the audit. There has to be a better way.

**There is. It's called modules.**

---

## What You'll Build

By the end of this exercise series, you'll have:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Root Module                                    │
│                                                                          │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐        │
│  │   DEV           │   │   STAGING       │   │   PROD          │        │
│  │  ┌───────────┐  │   │  ┌───────────┐  │   │  ┌───────────┐  │        │
│  │  │ s3-website│  │   │  │ s3-website│  │   │  │ s3-website│  │        │
│  │  │  (blue)   │  │   │  │ (yellow)  │  │   │  │  (green)  │  │        │
│  │  └─────┬─────┘  │   │  └─────┬─────┘  │   │  └─────┬─────┘  │        │
│  │        │        │   │        │        │   │        │        │        │
│  │  ┌─────▼─────┐  │   │  ┌─────▼─────┐  │   │  ┌─────▼─────┐  │        │
│  │  │    cdn    │  │   │  │    cdn    │  │   │  │    cdn    │  │        │
│  │  └───────────┘  │   │  └───────────┘  │   │  └───────────┘  │        │
│  └─────────────────┘   └─────────────────┘   └─────────────────┘        │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘

Three environments. Two reusable modules. One codebase.
```

---

## Exercise Overview

| Exercise | Time | Focus | You'll Learn |
|----------|------|-------|--------------|
| **01: Your First Module** | 75 min | Build an S3 website module from scratch | Module structure, variables, outputs, locals, `templatefile()` |
| **02: The CDN Module** | 45 min | Create a CloudFront module that consumes S3 outputs | Module composition, output → input wiring |
| **03: Multi-Environment** | 60 min | Deploy dev/staging/prod with different configs | Multi-environment patterns, `for_each` on modules |

---

## Concepts You'll Master

### Exercise 1: Your First Module

| Concept | What It Is | Why It Matters |
|---------|-----------|----------------|
| **Module structure** | A folder with `main.tf`, `variables.tf`, `outputs.tf` | Standard pattern everyone recognizes |
| **Input variables** | Data that flows INTO a module | Makes modules configurable |
| **Variable validation** | Rules that inputs must follow | Catches errors early |
| **Outputs** | Data that flows OUT of a module | Lets other code use your module's resources |
| **Locals** | Computed values inside a module | DRY principle, single source of truth |
| **Enforced vs optional** | Some config has no variable (always on) | Security/compliance patterns |
| **`templatefile()`** | Generate file content from variables | Dynamic content without string concatenation |

### Exercise 2: The CDN Module

| Concept | What It Is | Why It Matters |
|---------|-----------|----------------|
| **Module composition** | One module's outputs feed another's inputs | Building complex infra from simple pieces |
| **Implicit dependencies** | Terraform figures out creation order | No manual ordering needed |
| **Interface design** | What inputs/outputs a module exposes | Good interfaces = reusable modules |

### Exercise 3: Multi-Environment Deployment

| Concept | What It Is | Why It Matters |
|---------|-----------|----------------|
| **Module reuse** | Same module, different variables | Build once, deploy many |
| **Environment configuration** | Per-environment variable values | Dev ≠ staging ≠ prod |
| **`for_each` on modules** | Create multiple module instances from a map | Eliminates repetition |

---

## File Structure You'll Create

```
exercises/modules/
├── exercise-01-first-module/
│   └── solution/
│       ├── main.tf                    # Calls the module
│       ├── variables.tf               # Root variables
│       ├── outputs.tf                 # Exposes module outputs
│       ├── providers.tf               # AWS provider config
│       ├── templates/
│       │   └── index.html.tftpl       # HTML template
│       └── modules/
│           └── s3-website/
│               ├── main.tf            # S3 resources
│               ├── variables.tf       # Module inputs
│               └── outputs.tf         # Module outputs
│
├── exercise-02-cdn-module/
│   └── solution/
│       └── modules/
│           ├── s3-website/            # From exercise 01
│           └── cdn/                   # NEW: CloudFront module
│               ├── main.tf
│               ├── variables.tf
│               └── outputs.tf
│
└── exercise-03-multi-environment/
    └── solution/
        ├── main.tf                    # 3 environments
        ├── main-foreach.tf            # Same thing with for_each
        └── modules/
            ├── s3-website/
            └── cdn/
```

---

## Prerequisites Checklist

Before starting, ensure you can:

- [ ] Create an S3 bucket with Terraform
- [ ] Configure S3 static website hosting
- [ ] Define variables with types and defaults
- [ ] Create outputs
- [ ] Run `terraform init`, `plan`, `apply`, `destroy`

If any of these feel shaky, complete the `exercises/s3/` series first.

---

## AWS Resources You'll Create

| Resource | Count | Purpose | Cost |
|----------|-------|---------|------|
| S3 Buckets | 3 | Website hosting per environment | ~$0.00 (minimal storage) |
| S3 Objects | 3 | index.html per bucket | ~$0.00 |
| CloudFront Distributions | 3 | CDN per environment | ~$0.00 (free tier) |

**Total estimated cost:** < $0.10/hour while deployed

⚠️ **Remember to `terraform destroy` when done!** CloudFront distributions take 10-15 minutes to delete.

---

## Let's Begin

Start with [Exercise 01: Your First Module](./exercise-01-first-module/README.md)

---

## Quick Reference: Module Syntax

```hcl
# Defining a module (inside modules/s3-website/)
# ------------------------------------------------

# modules/s3-website/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

# modules/s3-website/main.tf
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

# modules/s3-website/outputs.tf
output "bucket_arn" {
  description = "ARN of the created bucket"
  value       = aws_s3_bucket.this.arn
}

# Using a module (from root main.tf)
# ------------------------------------------------

module "website" {
  source      = "./modules/s3-website"
  bucket_name = "my-website-bucket"
}

# Accessing module outputs
output "website_arn" {
  value = module.website.bucket_arn
}
```
