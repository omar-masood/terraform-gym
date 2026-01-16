# Exercise 03: Multi-Environment Deployment

**Time:** 60 minutes  
**Difficulty:** Intermediate  
**Cost:** ~$0.00 (within free tier)

---

## Objective

Deploy **three complete environments** (dev, staging, prod) using your reusable modules. First, you'll do it with explicit module calls to see the pattern clearly. Then, you'll refactor using `for_each` to eliminate repetition.

---

## Learning Objectives

By the end of this exercise, you will be able to:

1. ✅ Deploy the same module composition multiple times with different configurations
2. ✅ Organize environment-specific configuration using `locals`
3. ✅ Use `for_each` with modules to eliminate repetitive code
4. ✅ Access outputs from modules created with `for_each`
5. ✅ Understand when to use explicit calls vs. `for_each`

---

## Prerequisites

- Completed Exercise 01 and 02
- Have working `s3-website` and `cdn` modules

---

## The Final Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Root Module                                        │
│                                                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────┐  │
│  │        DEV          │  │      STAGING        │  │        PROD         │  │
│  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │  │
│  │  │  s3-website   │  │  │  │  s3-website   │  │  │  │  s3-website   │  │  │
│  │  │    (blue)     │  │  │  │   (yellow)    │  │  │  │   (green)     │  │  │
│  │  └───────┬───────┘  │  │  └───────┬───────┘  │  │  └───────┬───────┘  │  │
│  │          │          │  │          │          │  │          │          │  │
│  │  ┌───────▼───────┐  │  │  ┌───────▼───────┐  │  │  ┌───────▼───────┐  │  │
│  │  │      cdn      │  │  │  │      cdn      │  │  │  │      cdn      │  │  │
│  │  └───────────────┘  │  │  └───────────────┘  │  │  └───────────────┘  │  │
│  └─────────────────────┘  └─────────────────────┘  └─────────────────────┘  │
│                                                                              │
│  Each environment has:                                                       │
│  • Its own S3 bucket with unique content/colors                             │
│  • Its own CloudFront distribution                                          │
│  • Different versioning settings (prod = enabled)                           │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Starting Point

The `skeleton/` directory contains:
- Complete `s3-website` and `cdn` modules from Exercise 02
- Root module with TODOs for you to complete

```
skeleton/
├── main.tf              # TODO: Add all three environments
├── variables.tf         # Root variables
├── outputs.tf           # TODO: Add outputs for all environments
├── providers.tf         # AWS provider
└── modules/
    ├── s3-website/      # Complete from Exercise 01
    └── cdn/             # Complete from Exercise 02
```

---

## Phase 1: Set Up Your Workspace (5 minutes)

```bash
cd exercises/modules/exercise-03-multi-environment

# Copy skeleton to workspace
cp -r skeleton/ workspace/
cd workspace/

# Review the structure
ls -la modules/
```

---

## Phase 2: Define Environment Configurations (10 minutes)

Before creating module calls, define what makes each environment different.

### Step 2.1: Create Environment Config with Locals

**Edit `main.tf`** to add the environment configurations at the top:

```hcl
# =============================================================================
# ENVIRONMENT CONFIGURATION
# =============================================================================
# Define what makes each environment unique. This is the SINGLE SOURCE OF TRUTH
# for environment-specific settings.
# =============================================================================

locals {
  environments = {
    dev = {
      site_content = {
        heading          = "Development Preview"
        message          = "Internal testing environment for the development team."
        background_color = "#e3f2fd"  # Light blue
        badge_color      = "#1976d2"  # Blue
      }
      enable_versioning = false  # Don't need versioning in dev
    }

    staging = {
      site_content = {
        heading          = "Staging Review"
        message          = "Pre-production environment for stakeholder review."
        background_color = "#fff8e1"  # Light yellow/amber
        badge_color      = "#f57c00"  # Orange
      }
      enable_versioning = false  # Optional for staging
    }

    prod = {
      site_content = {
        heading          = "Welcome to Acme Corp"
        message          = "Official company website. Handle with care!"
        background_color = "#e8f5e9"  # Light green
        badge_color      = "#388e3c"  # Green
      }
      enable_versioning = true  # ALWAYS version production!
    }
  }
}
```

**💡 Key Insight:** By defining environment configs in `locals`, you have:
- Single source of truth for environment differences
- Easy to see what varies between environments
- Simple to add new environments later

---

## Phase 3: Explicit Module Calls (20 minutes)

First, let's create each environment with explicit module calls. This makes the pattern crystal clear.

### Step 3.1: Create Dev Environment

**Add to `main.tf`:**

```hcl
# =============================================================================
# DEV ENVIRONMENT
# =============================================================================

module "dev_website" {
  source = "./modules/s3-website"

  bucket_name       = "acme-dev-${var.unique_suffix}"
  environment       = "dev"
  site_content      = local.environments.dev.site_content
  enable_versioning = local.environments.dev.enable_versioning

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "dev"
  }
}

module "dev_cdn" {
  source = "./modules/cdn"

  origin_domain = module.dev_website.website_endpoint
  environment   = "dev"

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "dev"
  }
}
```

### Step 3.2: Create Staging Environment

**Add to `main.tf`:**

```hcl
# =============================================================================
# STAGING ENVIRONMENT
# =============================================================================

module "staging_website" {
  source = "./modules/s3-website"

  bucket_name       = "acme-staging-${var.unique_suffix}"
  environment       = "staging"
  site_content      = local.environments.staging.site_content
  enable_versioning = local.environments.staging.enable_versioning

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "staging"
  }
}

module "staging_cdn" {
  source = "./modules/cdn"

  origin_domain = module.staging_website.website_endpoint
  environment   = "staging"

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "staging"
  }
}
```

### Step 3.3: Create Prod Environment

**Add to `main.tf`:**

```hcl
# =============================================================================
# PROD ENVIRONMENT
# =============================================================================

module "prod_website" {
  source = "./modules/s3-website"

  bucket_name       = "acme-prod-${var.unique_suffix}"
  environment       = "prod"
  site_content      = local.environments.prod.site_content
  enable_versioning = local.environments.prod.enable_versioning

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "prod"
  }
}

module "prod_cdn" {
  source = "./modules/cdn"

  origin_domain = module.prod_website.website_endpoint
  environment   = "prod"

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = "prod"
  }
}
```

### Step 3.4: Add Outputs

**Edit `outputs.tf`:**

```hcl
# =============================================================================
# OUTPUTS - All Environments
# =============================================================================

# -----------------------------------------------------------------------------
# Dev Environment
# -----------------------------------------------------------------------------
output "dev_cdn_url" {
  description = "Dev environment CDN URL"
  value       = module.dev_cdn.cdn_url
}

output "dev_bucket" {
  description = "Dev environment S3 bucket"
  value       = module.dev_website.bucket_id
}

# -----------------------------------------------------------------------------
# Staging Environment
# -----------------------------------------------------------------------------
output "staging_cdn_url" {
  description = "Staging environment CDN URL"
  value       = module.staging_cdn.cdn_url
}

output "staging_bucket" {
  description = "Staging environment S3 bucket"
  value       = module.staging_website.bucket_id
}

# -----------------------------------------------------------------------------
# Prod Environment
# -----------------------------------------------------------------------------
output "prod_cdn_url" {
  description = "Prod environment CDN URL"
  value       = module.prod_cdn.cdn_url
}

output "prod_bucket" {
  description = "Prod environment S3 bucket"
  value       = module.prod_website.bucket_id
}

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
output "all_cdn_urls" {
  description = "All CDN URLs by environment"
  value = {
    dev     = module.dev_cdn.cdn_url
    staging = module.staging_cdn.cdn_url
    prod    = module.prod_cdn.cdn_url
  }
}
```

### Step 3.5: Deploy and Test

```bash
terraform init
terraform validate
terraform plan -var="unique_suffix=yourname"

# Deploy all three environments (this takes ~10-15 min for CloudFront)
terraform apply -var="unique_suffix=yourname"
```

### Step 3.6: Verify All Environments

```bash
# Get all URLs
terraform output all_cdn_urls

# Test each one
curl $(terraform output -raw dev_cdn_url)
curl $(terraform output -raw staging_cdn_url)
curl $(terraform output -raw prod_cdn_url)
```

You should see three different colored pages! 🎉

---

## Phase 4: Refactor with `for_each` (20 minutes)

The explicit approach works, but look at how much repetition there is! Let's refactor using `for_each`.

### Understanding `for_each` on Modules

`for_each` creates multiple instances of a module from a map or set:

```hcl
# Instead of:
module "dev_website" { ... }
module "staging_website" { ... }
module "prod_website" { ... }

# We can write:
module "website" {
  for_each = local.environments
  source   = "./modules/s3-website"
  # each.key   = "dev", "staging", or "prod"
  # each.value = the config object for that environment
}
```

### Step 4.1: Create a New File for the `for_each` Version

**Create `main-foreach.tf`:**

```hcl
# =============================================================================
# MULTI-ENVIRONMENT DEPLOYMENT WITH for_each
# =============================================================================
# This is a refactored version that eliminates repetition.
# Compare this to main.tf to see the difference!
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Website Module - One call creates ALL environments
# -----------------------------------------------------------------------------
module "websites" {
  source   = "./modules/s3-website"
  for_each = local.environments

  bucket_name       = "acme-${each.key}-${var.unique_suffix}"
  environment       = each.key
  site_content      = each.value.site_content
  enable_versioning = each.value.enable_versioning

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = each.key
  }
}

# -----------------------------------------------------------------------------
# CDN Module - One call creates ALL distributions
# -----------------------------------------------------------------------------
module "cdns" {
  source   = "./modules/cdn"
  for_each = local.environments

  # Reference the corresponding website module instance
  origin_domain = module.websites[each.key].website_endpoint
  environment   = each.key

  tags = {
    Team        = "marketing"
    Project     = "campaign-preview"
    Environment = each.key
  }
}
```

**⚠️ Important:** You can't have both versions active at once! To test `for_each`:
1. Rename `main.tf` to `main-explicit.tf.disabled`
2. Rename `main-foreach.tf` to `main.tf`
3. Update outputs (see below)

### Step 4.2: Update Outputs for `for_each`

When using `for_each`, accessing module outputs is slightly different:

**Create `outputs-foreach.tf`:**

```hcl
# =============================================================================
# OUTPUTS FOR for_each VERSION
# =============================================================================

# Individual outputs still work
output "dev_cdn_url_fe" {
  description = "Dev CDN URL (for_each version)"
  value       = module.cdns["dev"].cdn_url
}

output "staging_cdn_url_fe" {
  description = "Staging CDN URL (for_each version)"
  value       = module.cdns["staging"].cdn_url
}

output "prod_cdn_url_fe" {
  description = "Prod CDN URL (for_each version)"
  value       = module.cdns["prod"].cdn_url
}

# But we can also create dynamic outputs!
output "all_cdn_urls_fe" {
  description = "All CDN URLs (for_each version)"
  value = {
    for env, cdn in module.cdns : env => cdn.cdn_url
  }
}

output "all_buckets_fe" {
  description = "All S3 buckets (for_each version)"
  value = {
    for env, website in module.websites : env => website.bucket_id
  }
}
```

### Step 4.3: Understanding the Syntax

Let's break down the key patterns:

**Creating module instances:**
```hcl
module "websites" {
  for_each = local.environments  # Creates 3 instances
  source   = "./modules/s3-website"
  
  # each.key = "dev", "staging", or "prod"
  # each.value = { site_content = {...}, enable_versioning = true/false }
  
  bucket_name = "acme-${each.key}-${var.unique_suffix}"
  environment = each.key
}
```

**Referencing module instances:**
```hcl
# Specific instance
module.websites["dev"].bucket_id

# All instances (for outputs)
{ for env, website in module.websites : env => website.bucket_id }
```

**Cross-referencing between for_each modules:**
```hcl
module "cdns" {
  for_each = local.environments
  
  # Reference the CORRESPONDING website instance
  origin_domain = module.websites[each.key].website_endpoint
}
```

---

## Phase 5: Compare the Approaches (5 minutes)

### Explicit Calls

```hcl
# main.tf - Explicit version
module "dev_website" { ... }      # 15 lines
module "dev_cdn" { ... }          # 12 lines
module "staging_website" { ... }  # 15 lines
module "staging_cdn" { ... }      # 12 lines
module "prod_website" { ... }     # 15 lines
module "prod_cdn" { ... }         # 12 lines
# Total: ~80 lines
```

### `for_each`

```hcl
# main-foreach.tf - for_each version
module "websites" { ... }  # 15 lines (creates ALL 3)
module "cdns" { ... }      # 12 lines (creates ALL 3)
# Total: ~27 lines
```

### When to Use Each

| Use Explicit Calls When... | Use `for_each` When... |
|---------------------------|------------------------|
| Environments have very different configs | Environments are mostly similar |
| You need fine-grained control | You want consistency |
| Learning/teaching the pattern | Reducing repetition |
| Small number of instances | Many instances (3+) |
| Environments change independently | Environments change together |

---

## Phase 6: Clean Up

```bash
terraform destroy -var="unique_suffix=yourname"
```

⏱️ **Note:** CloudFront distributions take 10-15 minutes to delete.

---

## Success Criteria

- ✅ Three environments deployed (dev, staging, prod)
- ✅ Each environment has unique colors/content
- ✅ Prod has versioning enabled
- ✅ All CloudFront URLs work with HTTPS
- ✅ Understand both explicit and `for_each` patterns
- ✅ Can explain when to use each approach

---

## What You Learned

| Concept | How You Applied It |
|---------|-------------------|
| **Environment configs in locals** | Single source of truth for differences |
| **Explicit module calls** | Clear pattern, easy to understand |
| **`for_each` on modules** | Eliminate repetition |
| **`each.key` and `each.value`** | Access map key and value in for_each |
| **Cross-module references with for_each** | `module.websites[each.key].output` |
| **Dynamic outputs** | `{ for k, v in module.x : k => v.output }` |

---

## Common Mistakes

❌ **Using `count` instead of `for_each` for named environments**
- `count` creates `module.website[0]`, `module.website[1]`
- `for_each` creates `module.website["dev"]`, `module.website["prod"]`
- Named keys are much clearer!

❌ **Forgetting brackets when referencing for_each instances**
- Wrong: `module.websites.bucket_id`
- Right: `module.websites["dev"].bucket_id`

❌ **Circular dependencies in for_each**
- If module A references module B, and B references A, Terraform fails
- Design your module interfaces to flow one direction

---

## Challenge Extension: Add a Fourth Environment

Try adding a `qa` environment:

1. Add it to `local.environments` with purple colors
2. Watch it automatically appear if using `for_each`
3. Or add explicit module calls if using the explicit approach

This demonstrates the scalability difference between the two approaches!

---

## Summary

You've completed the module series! You now know how to:

1. **Build modules** - Package resources for reuse
2. **Compose modules** - Wire outputs to inputs
3. **Deploy multi-environment** - Same modules, different configs
4. **Use `for_each`** - Eliminate repetition at scale

This is real-world Terraform. The same patterns apply whether you're deploying websites, databases, Kubernetes clusters, or entire cloud environments.

---

## Next Steps

- Try the state management exercises in `exercises/state/`
- Apply these patterns to your own projects
- Explore the Terraform Registry for community modules

Congratulations! 🎉
