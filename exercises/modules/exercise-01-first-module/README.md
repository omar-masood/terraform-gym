# Exercise 01: Your First Module

**Time:** 75 minutes  
**Difficulty:** Intermediate  
**Cost:** ~$0.00 (S3 static website, minimal storage)

---

## Objective

Transform a hardcoded S3 static website into a **reusable Terraform module**. You'll experience the pain of copy-paste infrastructure, then solve it with modules.

---

## Learning Objectives

By the end of this exercise, you will be able to:

1. ✅ Explain why copy-paste infrastructure fails at scale
2. ✅ Create the standard module file structure (`main.tf`, `variables.tf`, `outputs.tf`)
3. ✅ Define input variables with `type`, `description`, `default`, and `validation`
4. ✅ Define outputs to expose values from a module
5. ✅ Call a module using `source` and pass variable values
6. ✅ Use `locals` to compute derived values (DRY principle)
7. ✅ Distinguish between enforced config (encryption) and optional config (versioning)
8. ✅ Use `templatefile()` to generate dynamic file content

---

## Prerequisites

- Completed S3 exercises (or comfortable creating S3 buckets)
- Understand variables and outputs
- Comfortable with `terraform init`, `plan`, `apply`, `destroy`

---

## Starting Point

The `skeleton/` directory contains a **fully working, hardcoded** S3 static website:

```
skeleton/
├── main.tf          # Hardcoded S3 bucket + website config + HTML
├── outputs.tf       # Website URL output
├── providers.tf     # AWS provider
└── index.html       # Static HTML file
```

Deploy it first to see it working, then refactor it into a module.

---

## Phase 1: Deploy the Hardcoded Website (10 minutes)

### Step 1.1: Set Up Your Workspace

```bash
# Navigate to the exercise
cd exercises/modules/exercise-01-first-module

# Copy skeleton to your working directory
cp -r skeleton/ workspace/
cd workspace/

# Look at what you're starting with
cat main.tf
```

**⏸️ PAUSE:** Read through `main.tf`. Notice how everything is hardcoded—bucket name, tags, HTML content. This works, but it's not reusable.

### Step 1.2: Deploy the Website

```bash
# Initialize Terraform
terraform init

# See what will be created
terraform plan

# Deploy it
terraform apply
```

### Step 1.3: Verify It Works

```bash
# Get the website URL
terraform output website_url

# Visit the URL in your browser (or curl it)
curl $(terraform output -raw website_url)
```

You should see a simple HTML page. **It works!** 🎉

---

## Phase 2: Feel the Pain (5 minutes)

### The Problem

Marketing comes back with a new request:

> "This dev site is great! Now we need a staging version for stakeholder review."

**Your options:**

1. **Copy-paste** `main.tf`, change the bucket name and tags
2. **Build a module** that you can call twice with different configs

Let's think about what happens with copy-paste:

| Scenario | Copy-Paste Approach | Module Approach |
|----------|--------------------|-----------------| 
| Add staging environment | Copy all 100 lines, change 5 values | Add 5-line module call |
| Security requires encryption | Edit 3 files, hope you don't miss one | Edit 1 module, all environments updated |
| New team needs same setup | Copy everything again, 4 files now | Add another module call |
| Bug fix needed | Fix in 4 places | Fix in 1 place |

**The copy-paste approach doesn't scale.** Let's build a module instead.

---

## Phase 3: Create the Module Structure (10 minutes)

### Step 3.1: Create the Module Directory

Modules are just directories with `.tf` files. By convention, we put them in a `modules/` folder:

```bash
# From your workspace directory
mkdir -p modules/s3-website
```

### Step 3.2: Create the Module Files

Every module needs three files:

```bash
# Create the standard module files
touch modules/s3-website/main.tf
touch modules/s3-website/variables.tf
touch modules/s3-website/outputs.tf
```

Your structure should now look like:

```
workspace/
├── main.tf              # Root module (will call our module)
├── outputs.tf           # Root outputs
├── providers.tf         # AWS provider
├── index.html           # Will become a template
└── modules/
    └── s3-website/
        ├── main.tf      # Module resources (empty)
        ├── variables.tf # Module inputs (empty)
        └── outputs.tf   # Module outputs (empty)
```

**💡 Key Insight:** A module is nothing special—it's just a folder with Terraform files. The "magic" happens when you call it with a `module` block.

---

## Phase 4: Move Resources and Add Your First Variable (15 minutes)

### Step 4.1: Define the First Variable

The bucket name is the most obvious thing that changes between environments. Let's make it a variable.

**Edit `modules/s3-website/variables.tf`:**

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket for the static website"
  type        = string

  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be between 3 and 63 characters."
  }
}
```

**📖 Documentation Hunt:** What other validations could you add for S3 bucket names?  
Hint: Check [S3 bucket naming rules](https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucketnamingrules.html)

### Step 4.2: Move the S3 Resources to the Module

**Edit `modules/s3-website/main.tf`:**

```hcl
# =============================================================================
# S3 STATIC WEBSITE MODULE
# =============================================================================
# This module creates an S3 bucket configured for static website hosting.
# =============================================================================

# -----------------------------------------------------------------------------
# S3 Bucket
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = {
    Name      = var.bucket_name
    ManagedBy = "terraform"
  }
}

# -----------------------------------------------------------------------------
# Website Configuration
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# -----------------------------------------------------------------------------
# Public Access Settings
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------------------------------------------------------
# Bucket Policy - Allow Public Read
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id

  # Must wait for public access block to be configured
  depends_on = [aws_s3_bucket_public_access_block.this]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.this.arn}/*"
      }
    ]
  })
}
```

**💡 Key Insight:** Notice we use `var.bucket_name` instead of a hardcoded string. This is how data flows INTO the module.

### Step 4.3: Update the Root Module to Call Your Module

**Replace the contents of your root `main.tf`:**

```hcl
# =============================================================================
# ROOT MODULE
# =============================================================================
# This is where we call our reusable modules
# =============================================================================

module "dev_website" {
  source = "./modules/s3-website"

  bucket_name = "acme-marketing-dev-YOURNAME"  # Replace YOURNAME!
}
```

### Step 4.4: Test the Module Call

```bash
# Re-initialize to pick up the new module
terraform init

# Validate the syntax
terraform validate

# See the plan
terraform plan
```

**⚠️ Expected:** You'll see Terraform wants to create new resources. The module works! But we lost the website content (index.html) and the outputs. Let's add those next.

---

## Phase 5: Add Outputs (10 minutes)

Outputs are how data flows OUT of a module. Other parts of your Terraform code (or humans running `terraform output`) can use these values.

### Step 5.1: Define Module Outputs

**Edit `modules/s3-website/outputs.tf`:**

```hcl
output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "website_endpoint" {
  description = "The website endpoint URL"
  value       = aws_s3_bucket_website_configuration.this.website_endpoint
}

output "website_url" {
  description = "The full website URL (with http://)"
  value       = "http://${aws_s3_bucket_website_configuration.this.website_endpoint}"
}
```

### Step 5.2: Expose Module Outputs from Root

**Update your root `outputs.tf`:**

```hcl
output "website_url" {
  description = "URL of the dev website"
  value       = module.dev_website.website_url
}

output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.dev_website.bucket_id
}
```

**💡 Key Insight:** Notice the syntax: `module.<MODULE_NAME>.<OUTPUT_NAME>`. This is how you access a module's outputs.

### Step 5.3: Verify Outputs Work

```bash
terraform validate
terraform plan
```

You should see the outputs listed in the plan.

---

## Phase 6: Parameterize with Environment and Locals (10 minutes)

Right now, we only have `bucket_name`. But every environment needs different tags, and we don't want callers to specify every single tag manually.

### Step 6.1: Add Environment Variable

**Add to `modules/s3-website/variables.tf`:**

```hcl
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

### Step 6.2: Use Locals for Computed Values

Locals let us compute values once and use them everywhere. This keeps our code DRY (Don't Repeat Yourself).

**Add to the top of `modules/s3-website/main.tf`** (before the resources):

```hcl
# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------
locals {
  # Default tags that every resource should have
  default_tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "s3-website"
  }

  # Merge default tags with any additional tags passed in
  # User-provided tags override defaults if there's a conflict
  all_tags = merge(local.default_tags, var.tags)
}
```

### Step 6.3: Update Resources to Use Local Tags

**Update the `aws_s3_bucket` resource:**

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = local.all_tags
}
```

### Step 6.4: Update the Module Call

**Update your root `main.tf`:**

```hcl
module "dev_website" {
  source = "./modules/s3-website"

  bucket_name = "acme-marketing-dev-YOURNAME"  # Replace YOURNAME!
  environment = "dev"

  tags = {
    Team    = "marketing"
    Project = "campaign-preview"
  }
}
```

### Step 6.5: Verify

```bash
terraform validate
terraform plan
```

Check that the tags in the plan include both the defaults AND your custom tags.

---

## Phase 7: Enforce Compliance (10 minutes)

Security mandates: **All S3 buckets must have encryption enabled.** This isn't optional—there's no variable for it.

But versioning? That's nice to have for prod, but maybe overkill for dev. Make it optional with a sensible default.

### Step 7.1: Add Encryption (Enforced - No Variable)

**Add to `modules/s3-website/main.tf`:**

```hcl
# -----------------------------------------------------------------------------
# Server-Side Encryption (ENFORCED - Always On)
# -----------------------------------------------------------------------------
# Security requirement: All buckets must have encryption enabled.
# This is not configurable because compliance is not optional.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**💡 Key Insight:** No variable for encryption. It's always on. This is how you enforce compliance through code—remove the option to be non-compliant.

### Step 7.2: Add Versioning (Optional - Has Variable)

**Add to `modules/s3-website/variables.tf`:**

```hcl
variable "enable_versioning" {
  description = "Enable versioning on the bucket (recommended for prod)"
  type        = bool
  default     = false
}
```

**Add to `modules/s3-website/main.tf`:**

```hcl
# -----------------------------------------------------------------------------
# Versioning (Optional - Configurable)
# -----------------------------------------------------------------------------
# Versioning is recommended for production but optional for dev/staging.
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}
```

### Step 7.3: Test Both Patterns

```bash
terraform validate
terraform plan
```

Notice in the plan:
- Encryption is **always** configured (no variable controls it)
- Versioning status depends on the `enable_versioning` variable (defaulted to `false`)

---

## Phase 8: Dynamic Content with `templatefile()` (10 minutes)

Right now, we have no website content. Let's use `templatefile()` to generate HTML dynamically based on variables.

### Step 8.1: Create the Template Directory and File

```bash
mkdir -p templates
```

**Create `templates/index.html.tftpl`:**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${heading} | Acme Corp</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: ${background_color};
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: white;
      padding: 3rem;
      border-radius: 12px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.1);
      text-align: center;
      max-width: 500px;
    }
    .badge {
      display: inline-block;
      background: ${badge_color};
      color: white;
      padding: 0.5rem 1rem;
      border-radius: 20px;
      font-size: 0.875rem;
      font-weight: 600;
      text-transform: uppercase;
      margin-bottom: 1.5rem;
    }
    h1 {
      color: #1a1a1a;
      margin-bottom: 1rem;
      font-size: 2rem;
    }
    p {
      color: #666;
      line-height: 1.6;
    }
    .footer {
      margin-top: 2rem;
      padding-top: 1.5rem;
      border-top: 1px solid #eee;
      font-size: 0.75rem;
      color: #999;
    }
  </style>
</head>
<body>
  <div class="card">
    <span class="badge">${environment}</span>
    <h1>${heading}</h1>
    <p>${message}</p>
    <div class="footer">
      Deployed with Terraform | Acme Corp
    </div>
  </div>
</body>
</html>
```

### Step 8.2: Add Site Config Variable

**Add to `modules/s3-website/variables.tf`:**

```hcl
variable "site_content" {
  description = "Content configuration for the website"
  type = object({
    heading          = string
    message          = string
    background_color = string
    badge_color      = string
  })

  default = {
    heading          = "Welcome"
    message          = "This site is under construction."
    background_color = "#f5f5f5"
    badge_color      = "#666666"
  }
}
```

### Step 8.3: Add S3 Object Resource for HTML

**Add to `modules/s3-website/main.tf`:**

```hcl
# -----------------------------------------------------------------------------
# Website Content
# -----------------------------------------------------------------------------
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.this.id
  key          = "index.html"
  content_type = "text/html"

  content = templatefile("${path.module}/templates/index.html.tftpl", {
    environment      = var.environment
    heading          = var.site_content.heading
    message          = var.site_content.message
    background_color = var.site_content.background_color
    badge_color      = var.site_content.badge_color
  })

  # Ensure bucket policy is in place before uploading
  depends_on = [aws_s3_bucket_policy.this]
}
```

### Step 8.4: Create Template in Module Directory

The `${path.module}` reference looks for the template relative to the module, so we need the template inside the module:

```bash
mkdir -p modules/s3-website/templates
cp templates/index.html.tftpl modules/s3-website/templates/
```

### Step 8.5: Update Module Call with Site Content

**Update your root `main.tf`:**

```hcl
module "dev_website" {
  source = "./modules/s3-website"

  bucket_name = "acme-marketing-dev-YOURNAME"  # Replace YOURNAME!
  environment = "dev"

  site_content = {
    heading          = "Development Preview"
    message          = "This is the internal development environment for testing new designs."
    background_color = "#e3f2fd"
    badge_color      = "#1976d2"
  }

  tags = {
    Team    = "marketing"
    Project = "campaign-preview"
  }
}
```

### Step 8.6: Deploy and Verify

```bash
terraform validate
terraform plan
terraform apply

# Visit the site!
curl $(terraform output -raw website_url)
```

You should see a styled HTML page with a blue theme and "Development Preview" heading!

---

## Phase 9: Clean Up and Review (5 minutes)

### Step 9.1: Destroy Resources

```bash
terraform destroy
```

### Step 9.2: Review What You Built

Your final module structure:

```
modules/s3-website/
├── main.tf           # 7 resources: bucket, website config, public access,
│                     #              policy, encryption, versioning, content
├── variables.tf      # 5 variables: bucket_name, environment, tags,
│                     #              enable_versioning, site_content
├── outputs.tf        # 4 outputs: bucket_id, bucket_arn, website_endpoint,
│                     #            website_url
└── templates/
    └── index.html.tftpl   # Dynamic HTML template
```

### What You Learned

| Concept | How You Used It |
|---------|-----------------|
| Module structure | Created `modules/s3-website/` with standard files |
| Input variables | `bucket_name`, `environment`, `site_content` |
| Variable validation | Bucket name length, environment allowed values |
| Outputs | Exposed `website_url` for other code to use |
| Locals | Computed `all_tags` by merging defaults with custom |
| Enforced config | Encryption always on (no variable) |
| Optional config | Versioning controlled by `enable_versioning` variable |
| `templatefile()` | Generated HTML from variables |

---

## Success Criteria

Your solution should:

- ✅ Have a working module in `modules/s3-website/`
- ✅ Module creates S3 bucket with website hosting
- ✅ Module has at least 3 input variables
- ✅ Module has at least 2 outputs
- ✅ Encryption is always enabled (no variable)
- ✅ Versioning is configurable via variable
- ✅ HTML content is generated from `templatefile()`
- ✅ `terraform validate` passes
- ✅ Website loads in browser with correct styling

---

## Common Mistakes

❌ **Forgetting `terraform init` after creating a module**
- Terraform needs to discover new modules
- Always re-run `init` after adding/moving modules

❌ **Wrong template path**
- `${path.module}` = directory where the module lives
- `${path.root}` = directory where you run terraform
- Use `path.module` for files inside your module

❌ **Missing `depends_on` for bucket policy**
- S3 objects can't be public until the policy is applied
- The `depends_on` ensures correct ordering

❌ **Hardcoding values that should be variables**
- If you copy-paste it between environments, it should be a variable

---

## Next Steps

You have a reusable S3 website module. But direct S3 URLs are:
- Slow from other regions
- HTTP only (no HTTPS)
- Not cacheable

In **Exercise 02**, you'll create a CloudFront CDN module that consumes your S3 module's outputs—learning **module composition**.

➡️ Continue to [Exercise 02: The CDN Module](../exercise-02-cdn-module/README.md)
