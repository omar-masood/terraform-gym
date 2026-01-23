# 📦 Jerry 06: Import Rescue

**Time:** 30-40 minutes | **Difficulty:** ⭐⭐⭐ Advanced

## The Situation

> "Hey! I created an S3 bucket for some quick testing in the console.
> It's called jerry-prod-data-something... can you just add it to our Terraform?
> There's actual production data in it now (oops), so don't delete it!
> I'm on vacation for 2 weeks. Thanks! 🏖️"
>
> — Jerry's Slack message, 3 weeks ago

Jerry created an S3 bucket manually via the AWS Console "just for testing." Now it has production data and needs to be managed by Terraform. You'll need to import the existing bucket without disrupting it.

## Your Mission

1. **Discover** what Jerry created (bucket name, configuration)
2. **Write** Terraform configuration that matches the existing bucket
3. **Import** the bucket using BOTH methods:
   - Legacy: `terraform import` command
   - Modern: `import` blocks (Terraform 1.5+)
4. **Handle** the split resource problem (bucket + versioning)
5. **Verify** with `terraform plan` showing no changes

## Prerequisites

- AWS credentials configured
- Terraform 1.9.0+ installed
- Understanding of Terraform state
- Familiarity with AWS S3

## Setup

```bash
# Navigate to this exercise
cd exercises/state/jerry-06-import-rescue

# Create your workspace
mkdir -p student-work
cp -r setup/* student-work/
cd student-work

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your student name

# Initialize Terraform
terraform init
```

### Let Jerry Create the Bucket

**Option 1: Using jerry-ctl** (if installed)
```bash
jerry create --scenario manual-bucket
```

**Option 2: Using simulation script** (always available)
```bash
# From student-work directory
../.validator/simulate-jerry.sh
```

Both options will create a real S3 bucket via AWS CLI, simulating Jerry's manual creation.

## The Discovery Phase

**IMPORTANT:** You need to figure out what Jerry created before you can write Terraform config!

### Step 1: Find the Bucket

```bash
# List all S3 buckets and look for Jerry's
aws s3 ls | grep jerry

# Or search more specifically
aws s3api list-buckets --query 'Buckets[?contains(Name, `jerry`)].Name'
```

The bucket will match the pattern: `jerry-prod-data-XXXXXX`

### Step 2: Inspect the Configuration

Once you find the bucket name, examine its configuration:

```bash
# Set the bucket name (replace with actual name)
BUCKET_NAME="jerry-prod-data-abc123"

# Check tags
aws s3api get-bucket-tagging --bucket $BUCKET_NAME

# Check versioning
aws s3api get-bucket-versioning --bucket $BUCKET_NAME

# Check encryption
aws s3api get-bucket-encryption --bucket $BUCKET_NAME

# Check public access block
aws s3api get-public-access-block --bucket $BUCKET_NAME
```

### Step 3: Document What You Find

Take notes on:
- Bucket name
- Tags (Jerry added some!)
- Versioning status (enabled or disabled?)
- Encryption settings
- Public access block settings

## The Import Challenge

### Understanding S3 Resource Split

In the AWS provider, S3 buckets are split across multiple resources:

```hcl
aws_s3_bucket                                    # The bucket itself
aws_s3_bucket_versioning                         # Versioning configuration
aws_s3_bucket_server_side_encryption_configuration # Encryption
aws_s3_bucket_public_access_block                # Public access settings
```

**Critical:** If Jerry enabled versioning, you must import BOTH:
- The bucket
- The versioning configuration

### Method 1: Legacy Import (Pre-1.5)

This is the traditional approach and still widely used:

```bash
# 1. Write the Terraform config in main.tf (you need to do this first!)

# 2. Import the bucket
terraform import aws_s3_bucket.jerry_bucket jerry-prod-data-abc123

# 3. Import the versioning (if enabled)
terraform import aws_s3_bucket_versioning.jerry_bucket jerry-prod-data-abc123

# 4. Verify
terraform plan  # Should show "No changes"
```

### Method 2: Modern Import Blocks (1.5+)

This is the new declarative approach:

```hcl
# Add to main.tf
import {
  to = aws_s3_bucket.jerry_bucket
  id = "jerry-prod-data-abc123"
}

import {
  to = aws_s3_bucket_versioning.jerry_bucket
  id = "jerry-prod-data-abc123"
}
```

Then:
```bash
# Generate the config (optional but helpful!)
terraform plan -generate-config-out=generated.tf

# Or apply the import
terraform apply

# Verify
terraform plan  # Should show "No changes"
```

## What You'll See

**Before writing any Terraform:**
```
$ terraform plan
No changes. Infrastructure is up-to-date.
```
(Because there's no config to compare against!)

**After writing config but before import:**
```
$ terraform plan
Terraform will perform the following actions:

  # aws_s3_bucket.jerry_bucket will be created
  + resource "aws_s3_bucket" "jerry_bucket" {
      + bucket = "jerry-prod-data-abc123"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**After successful import:**
```
$ terraform plan
No changes. Your infrastructure matches the configuration.
```

## Common Gotchas

### Gotcha #1: Forgetting Versioning

If you import the bucket but forget versioning:
```
$ terraform plan

  # aws_s3_bucket_versioning.jerry_bucket will be created
  + resource "aws_s3_bucket_versioning" "jerry_bucket" {
      + bucket = "jerry-prod-data-abc123"
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

**Fix:** Import the versioning resource too!

### Gotcha #2: Config Mismatch

If your config doesn't match AWS reality:
```
$ terraform plan

  # aws_s3_bucket.jerry_bucket will be updated in-place
  ~ resource "aws_s3_bucket" "jerry_bucket" {
      ~ tags = {
          - "CreatedBy" = "jerry" -> null
        }
    }
```

**Fix:** Update your config to match AWS exactly!

### Gotcha #3: Missing Resources

If you forget a resource that Jerry configured:
- Check for encryption settings
- Check for public access block
- Check for lifecycle rules

## Bonus Challenge (Optional)

Jerry's bucket is missing some security best practices:
- No encryption configured
- No public access block

After successfully importing, consider:
1. Adding encryption configuration
2. Adding public access block

**Note:** These WILL show as changes in `terraform plan` - and that's OK! You're improving the infrastructure. The difference is:
- Import should show NO changes (matching what exists)
- Improvements will show changes (making it better)

## Learning Objectives

After completing this exercise, you'll be able to:

- [ ] Discover existing AWS resources using CLI
- [ ] Write Terraform config that matches existing infrastructure
- [ ] Import resources using legacy `terraform import` command
- [ ] Import resources using modern `import` blocks
- [ ] Handle split resources (bucket + versioning)
- [ ] Verify successful import with `terraform plan`

## Key Concepts

### Why Import?

Real-world scenarios where you need import:
- **Brownfield environments** - Infrastructure created before Terraform
- **Acquisitions** - Inheriting another team's infrastructure
- **Migration** - Moving from CloudFormation or other tools
- **Shadow IT** - Cleaning up manually created resources (like Jerry!)

### Legacy vs Modern Import

| Aspect | Legacy (`terraform import`) | Modern (`import` blocks) |
|--------|----------------------------|--------------------------|
| **When** | Pre-1.5 (still works in 1.9+) | Terraform 1.5+ |
| **Style** | Imperative (command-line) | Declarative (in code) |
| **Repeatable** | No (one-time command) | Yes (in version control) |
| **Visible** | Only in state | Shows in plan |
| **Generate Config** | No | Yes (`-generate-config-out`) |

### Import Process

```
1. Discover    →  Find what exists in AWS
2. Write       →  Create matching Terraform config
3. Import      →  Link state to existing resource
4. Verify      →  terraform plan shows no changes
5. Manage      →  Now you can modify with Terraform
```

## Hints

<details>
<summary>Hint 1: How to find Jerry's bucket</summary>

```bash
# List all buckets and filter for jerry
aws s3 ls | grep jerry

# The bucket name was saved by simulate-jerry.sh
cat ../.jerry/bucket-name.txt
```

</details>

<details>
<summary>Hint 2: How to see bucket configuration</summary>

```bash
# Replace with your actual bucket name
BUCKET="jerry-prod-data-abc123"

# See all tags
aws s3api get-bucket-tagging --bucket $BUCKET

# See versioning status
aws s3api get-bucket-versioning --bucket $BUCKET

# The output will guide your Terraform config
```

</details>

<details>
<summary>Hint 3: What Terraform resources you need</summary>

Based on what Jerry created, you'll need:

```hcl
resource "aws_s3_bucket" "jerry_bucket" {
  bucket = "jerry-prod-data-XXXXXX"  # Use actual name

  tags = {
    # Match Jerry's tags exactly!
  }
}

resource "aws_s3_bucket_versioning" "jerry_bucket" {
  bucket = aws_s3_bucket.jerry_bucket.id

  versioning_configuration {
    status = "Enabled"  # Jerry enabled this
  }
}
```

</details>

<details>
<summary>Hint 4: Legacy import command syntax</summary>

```bash
# Import the bucket (replace with actual name)
terraform import aws_s3_bucket.jerry_bucket jerry-prod-data-abc123

# Import the versioning
terraform import aws_s3_bucket_versioning.jerry_bucket jerry-prod-data-abc123

# Verify
terraform plan
```

The pattern is: `terraform import <resource_type>.<resource_name> <resource_id>`

</details>

<details>
<summary>Hint 5: Modern import blocks syntax</summary>

Add to your `main.tf`:

```hcl
import {
  to = aws_s3_bucket.jerry_bucket
  id = "jerry-prod-data-abc123"
}

import {
  to = aws_s3_bucket_versioning.jerry_bucket
  id = "jerry-prod-data-abc123"
}
```

Then run:
```bash
terraform plan  # Shows the import will happen
terraform apply # Executes the import
```

</details>

<details>
<summary>Hint 6: Don't forget Jerry's tags!</summary>

Jerry added these tags:
```hcl
tags = {
  CreatedBy  = "jerry"
  Purpose    = "testing"
  Department = "engineering"
}
```

Your config must match these EXACTLY or `terraform plan` will show changes.

</details>

<details>
<summary>Hint 7: Complete solution (see solution/)</summary>

Check `solution/SOLUTION.md` for the complete walkthrough of both methods.

Two solution files:
- `solution/main-legacy.tf` - Using terraform import command
- `solution/main-import-blocks.tf` - Using import blocks

</details>

## Validation

```bash
# Option 1: Using jerry-ctl (if installed)
jerry validate

# Option 2: Using validation script
../.validator/validate.sh
```

### Success Criteria

- [ ] Bucket is imported into Terraform state
- [ ] Versioning resource is imported (if enabled)
- [ ] `terraform plan` shows "No changes"
- [ ] You can explain both import methods

## Discussion Questions

1. **When would you use legacy import vs import blocks?**
   - Legacy: Quick one-off imports, older Terraform versions
   - Modern: Repeatable imports, team collaboration, version control

2. **Why is S3 split across multiple resources?**
   - AWS provider evolution (avoiding breaking changes)
   - Separation of concerns (each resource manages one aspect)
   - Flexibility (enable/disable features independently)

3. **What happens if you import without matching config?**
   - Import succeeds (resource in state)
   - Plan shows drift (config doesn't match state)
   - Apply would modify the resource (dangerous!)

4. **How to prevent "Jerry scenarios" in real life?**
   - IAM policies restricting console access
   - CI/CD pipelines for all changes
   - Detective controls (AWS Config, CloudTrail)
   - Team training and culture

## Key Takeaways

1. **Import is a rescue operation** - Use it to adopt existing infrastructure
2. **Discovery is critical** - You must know what exists before writing config
3. **Config must match exactly** - Import doesn't modify resources
4. **Split resources are common** - Many AWS resources split into multiple Terraform resources
5. **Two valid methods** - Legacy and modern both have their place
6. **Verify with plan** - Always check that plan shows no changes after import

## Clean Up

```bash
# Destroy the infrastructure
terraform destroy -auto-approve

# Clean up workspace
cd ..
rm -rf student-work
```

### Reset for Another Try

```bash
# Delete Jerry's bucket and try again
../.validator/reset.sh

# Recreate Jerry's bucket
../.validator/simulate-jerry.sh

# Try the other import method!
```

## What's Next?

- **Jerry 07**: Moved resources (refactoring with moved blocks)
- **Jerry 08**: State surgery (manual state editing - advanced!)

---

## Files in This Exercise

```
jerry-06-import-rescue/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl configuration
├── setup/
│   ├── providers.tf             # Terraform & AWS provider config
│   ├── backend.tf               # Backend configuration (local)
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Outputs for imported bucket
│   ├── terraform.tfvars.example # Example variable values
│   ├── .gitignore               # Ignore state files
│   └── main.tf                  # EMPTY - you write this!
├── .validator/
│   ├── simulate-jerry.sh        # Creates bucket via AWS CLI
│   ├── validate.sh              # Validation script
│   └── reset.sh                 # Deletes Jerry's bucket
└── solution/
    ├── SOLUTION.md              # Full walkthrough
    ├── main-legacy.tf           # Solution using terraform import
    └── main-import-blocks.tf    # Solution using import blocks
```

## Exam Objectives Covered

| Objective | Description |
|-----------|-------------|
| **7a** | Import existing resources into Terraform |
| **7b** | Use terraform state and CLI commands |
| **4a** | Demonstrate use of variables and outputs |
| **3d** | Generate and review an execution plan |
