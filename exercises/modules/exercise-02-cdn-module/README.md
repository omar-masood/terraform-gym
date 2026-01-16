# Exercise 02: The CDN Module

**Time:** 45 minutes  
**Difficulty:** Intermediate  
**Cost:** ~$0.00 (CloudFront free tier)

---

## Objective

Create a **CloudFront CDN module** that consumes outputs from your S3 website module. This teaches **module composition**—how modules work together by passing data between them.

---

## Learning Objectives

By the end of this exercise, you will be able to:

1. ✅ Create a module that depends on external inputs
2. ✅ Configure CloudFront distribution basics (origin, default cache behavior)
3. ✅ Wire module outputs as inputs to another module
4. ✅ Understand implicit dependencies between composed modules

---

## Prerequisites

- Completed Exercise 01 (have a working s3-website module)
- Understand module inputs and outputs

---

## The Scenario

Your S3 static website works great, but Marketing has concerns:

> "The site is slow when I access it from our London office. Also, our security team wants HTTPS everywhere."

Direct S3 website URLs have limitations:
- **No HTTPS** - S3 website endpoints are HTTP only
- **No edge caching** - Every request goes to the bucket's region
- **No geographic distribution** - Slow for users far from the bucket

**CloudFront solves all of these.** It provides a global CDN with HTTPS support and edge caching.

---

## Architecture: Module Composition

```
┌─────────────────────────────────────────────────────────────┐
│                      Root Module                            │
│                                                             │
│   module "website" {          module "cdn" {                │
│     source = "./s3-website"     source = "./cdn"            │
│     bucket_name = "..."         origin_domain = module      │
│     environment = "dev"           .website.website_endpoint │
│   }                             environment = "dev"         │
│         │                     }                             │
│         │                           │                       │
│         └───── outputs ─────────────┘                       │
│                                                             │
│   The CDN module needs data from the S3 module.             │
│   We wire them together in the root module.                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Key Insight:** The root module is the "orchestrator" that:
1. Creates the S3 website (module "website")
2. Passes S3 outputs to CloudFront (module "cdn")
3. Terraform figures out the creation order automatically

---

## Starting Point

The `skeleton/` directory contains:
- Your completed s3-website module from Exercise 01
- An empty `cdn/` module directory to build
- A root module that calls both

```
skeleton/
├── main.tf                    # Root module (partially complete)
├── variables.tf               # Root variables
├── outputs.tf                 # Root outputs (partially complete)
├── providers.tf               # AWS provider
└── modules/
    ├── s3-website/            # Complete from Exercise 01
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── templates/
    │       └── index.html.tftpl
    └── cdn/                   # Empty - you'll build this!
        ├── main.tf            # TODO
        ├── variables.tf       # TODO
        └── outputs.tf         # TODO
```

---

## Phase 1: Set Up Your Workspace (5 minutes)

```bash
cd exercises/modules/exercise-02-cdn-module

# Copy skeleton to workspace
cp -r skeleton/ workspace/
cd workspace/

# Review the structure
ls -la modules/cdn/
```

You should see empty (or minimal) files in the `cdn/` module directory.

---

## Phase 2: Design the CDN Module Interface (10 minutes)

Before writing code, think about:
1. **What inputs does CloudFront need?** (What changes between environments?)
2. **What outputs should it expose?** (What will callers need?)

### Step 2.1: Define CDN Module Variables

**Edit `modules/cdn/variables.tf`:**

```hcl
# =============================================================================
# CDN MODULE - INPUT VARIABLES
# =============================================================================

variable "origin_domain" {
  description = "Domain name of the origin (S3 website endpoint)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "price_class" {
  description = "CloudFront price class (PriceClass_100, PriceClass_200, PriceClass_All)"
  type        = string
  default     = "PriceClass_100"  # US, Canada, Europe only - cheapest

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "Price class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
```

**📖 Documentation Hunt:**  
- What do the different price classes include?  
- Check: [CloudFront Pricing](https://aws.amazon.com/cloudfront/pricing/)

---

## Phase 3: Create the CloudFront Distribution (20 minutes)

### Step 3.1: Create the Main CDN Resources

**Edit `modules/cdn/main.tf`:**

```hcl
# =============================================================================
# CLOUDFRONT CDN MODULE
# =============================================================================
# This module creates a CloudFront distribution that serves content from
# an S3 website origin. It provides HTTPS, caching, and global distribution.
# =============================================================================

# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "cdn"
  }

  all_tags = merge(local.default_tags, var.tags)
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.environment} website CDN"
  default_root_object = "index.html"
  price_class         = var.price_class

  # ---------------------------------------------------------------------------
  # Origin Configuration
  # ---------------------------------------------------------------------------
  # This tells CloudFront where to fetch content from.
  # We're using the S3 website endpoint as a custom origin (not S3 origin).
  # ---------------------------------------------------------------------------
  origin {
    domain_name = var.origin_domain
    origin_id   = "S3-Website-${var.environment}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"  # S3 website endpoints are HTTP only
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # ---------------------------------------------------------------------------
  # Default Cache Behavior
  # ---------------------------------------------------------------------------
  # This defines how CloudFront handles requests by default.
  # ---------------------------------------------------------------------------
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Website-${var.environment}"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"  # Force HTTPS!
    min_ttl                = 0
    default_ttl            = 3600   # 1 hour
    max_ttl                = 86400  # 24 hours
    compress               = true   # Enable gzip compression
  }

  # ---------------------------------------------------------------------------
  # Restrictions
  # ---------------------------------------------------------------------------
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # ---------------------------------------------------------------------------
  # SSL Certificate
  # ---------------------------------------------------------------------------
  # Using CloudFront's default certificate for *.cloudfront.net domains.
  # For custom domains, you'd use ACM certificates here.
  # ---------------------------------------------------------------------------
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.all_tags
}
```

**💡 Key Insights:**

1. **Custom Origin vs S3 Origin:** We use `custom_origin_config` because S3 website endpoints behave like web servers, not S3 API endpoints. This also allows public access without OAI/OAC complexity.

2. **`viewer_protocol_policy = "redirect-to-https"`:** This forces HTTPS on the viewer side, even though we use HTTP to talk to S3.

3. **Price Class:** `PriceClass_100` is cheapest (only US, Canada, Europe edge locations).

---

## Phase 4: Add CDN Module Outputs (5 minutes)

### Step 4.1: Define What the CDN Module Exposes

**Edit `modules/cdn/outputs.tf`:**

```hcl
# =============================================================================
# CDN MODULE - OUTPUTS
# =============================================================================

output "distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cdn_url" {
  description = "The HTTPS URL of the CDN"
  value       = "https://${aws_cloudfront_distribution.this.domain_name}"
}
```

---

## Phase 5: Wire the Modules Together (10 minutes)

Now comes the composition! We connect the S3 module's outputs to the CDN module's inputs.

### Step 5.1: Update Root main.tf

**Edit `main.tf` in your workspace root:**

```hcl
# =============================================================================
# ROOT MODULE - Exercise 02 Solution
# =============================================================================
# This demonstrates MODULE COMPOSITION - modules working together.
# The CDN module depends on outputs from the S3 website module.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Website Module
# -----------------------------------------------------------------------------
module "website" {
  source = "./modules/s3-website"

  bucket_name = "acme-marketing-dev-${var.unique_suffix}"
  environment = "dev"

  site_content = {
    heading          = "Development Preview"
    message          = "This is the internal development environment. Now with CloudFront CDN!"
    background_color = "#e3f2fd"
    badge_color      = "#1976d2"
  }

  tags = {
    Team    = "marketing"
    Project = "campaign-preview"
  }
}

# -----------------------------------------------------------------------------
# CloudFront CDN Module
# -----------------------------------------------------------------------------
# Notice how we pass the S3 module's output as input to this module!
# This creates an implicit dependency: CDN waits for S3 to be created.
# -----------------------------------------------------------------------------
module "cdn" {
  source = "./modules/cdn"

  # THE KEY WIRING: S3 output → CDN input
  origin_domain = module.website.website_endpoint
  environment   = "dev"

  tags = {
    Team    = "marketing"
    Project = "campaign-preview"
  }
}
```

**💡 Key Insight:** The line `origin_domain = module.website.website_endpoint` is where composition happens. Terraform sees this reference and knows:
1. The S3 module must be created first (has the `website_endpoint` output)
2. Then the CDN module can be created (uses that output as input)

### Step 5.2: Update Root Outputs

**Edit `outputs.tf`:**

```hcl
# =============================================================================
# ROOT MODULE - OUTPUTS
# =============================================================================

# S3 Website outputs (still useful for debugging)
output "s3_website_url" {
  description = "Direct S3 website URL (HTTP only, for debugging)"
  value       = module.website.website_url
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.website.bucket_id
}

# CDN outputs (what users should actually use)
output "cdn_url" {
  description = "CloudFront CDN URL (HTTPS) - USE THIS!"
  value       = module.cdn.cdn_url
}

output "distribution_id" {
  description = "CloudFront distribution ID (for cache invalidation)"
  value       = module.cdn.distribution_id
}
```

---

## Phase 6: Deploy and Test (10 minutes)

### Step 6.1: Initialize and Validate

```bash
terraform init
terraform validate
terraform plan -var="unique_suffix=yourname"
```

**Expected:** You should see:
- 7 S3 resources (bucket, website config, public access, policy, encryption, versioning, object)
- 1 CloudFront distribution

### Step 6.2: Deploy

```bash
terraform apply -var="unique_suffix=yourname"
```

⏱️ **Note:** CloudFront distributions take 5-15 minutes to deploy globally. Be patient!

### Step 6.3: Test Both URLs

```bash
# Get the URLs
terraform output

# Test the S3 URL (HTTP)
curl $(terraform output -raw s3_website_url)

# Test the CDN URL (HTTPS)
curl $(terraform output -raw cdn_url)
```

Both should return the same HTML content, but the CDN URL uses HTTPS! 🎉

### Step 6.4: Verify HTTPS Redirect

```bash
# Try HTTP on CloudFront - should redirect to HTTPS
curl -I "http://$(terraform output -raw cdn_url | sed 's|https://||')"
```

You should see a 301 redirect to HTTPS.

---

## Phase 7: Clean Up

```bash
terraform destroy -var="unique_suffix=yourname"
```

⏱️ **Note:** CloudFront distributions take 10-15 minutes to delete. Be patient!

---

## What You Learned

| Concept | How You Applied It |
|---------|-------------------|
| **Module composition** | CDN module consumes S3 module's outputs |
| **Output → Input wiring** | `origin_domain = module.website.website_endpoint` |
| **Implicit dependencies** | Terraform creates S3 before CDN automatically |
| **Interface design** | CDN module has focused inputs (just what it needs) |

---

## The Composition Pattern

```hcl
# Module A produces outputs
module "website" {
  source = "./modules/s3-website"
  # ...
}

# Module B consumes A's outputs
module "cdn" {
  source = "./modules/cdn"
  origin_domain = module.website.website_endpoint  # <-- The wiring!
}
```

This pattern is **everywhere** in production Terraform:
- VPC module outputs → EC2 module inputs (subnet IDs)
- Database module outputs → Application module inputs (connection strings)
- Certificate module outputs → Load balancer module inputs (certificate ARN)

---

## Success Criteria

- ✅ CDN module exists with `main.tf`, `variables.tf`, `outputs.tf`
- ✅ CDN module accepts `origin_domain` as input
- ✅ Root module wires S3 output to CDN input
- ✅ Both URLs return the same content
- ✅ CDN URL uses HTTPS
- ✅ `terraform validate` passes

---

## Common Mistakes

❌ **Using S3 bucket ARN/ID instead of website endpoint**
- CloudFront needs the website endpoint domain, not the bucket identifier
- Wrong: `module.website.bucket_id`
- Right: `module.website.website_endpoint`

❌ **Using `s3_origin_config` instead of `custom_origin_config`**
- S3 website endpoints act like web servers, not S3 API endpoints
- Use `custom_origin_config` with `http-only` protocol

❌ **Forgetting the protocol in outputs**
- `website_endpoint` is just the domain (no `http://` or `https://`)
- Your CDN output should include the protocol: `"https://${...domain_name}"`

---

## Next Steps

You now have two composable modules:
- `s3-website` - Creates an S3 static website
- `cdn` - Creates a CloudFront distribution

In **Exercise 03**, you'll deploy all three environments (dev, staging, prod) using these modules—first with explicit module calls, then refactored to use `for_each`.

➡️ Continue to [Exercise 03: Multi-Environment Deployment](../exercise-03-multi-environment/README.md)
