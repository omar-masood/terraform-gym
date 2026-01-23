# 🔄 Jerry 08: The Rename Refactor

**Time:** 25-30 minutes | **Difficulty:** ⭐⭐⭐ Advanced

## The Situation

> Jerry decided your resource names weren't descriptive enough.
> He spent an hour "improving" them: `bucket1` became `application_data`, `bucket2` became `user_uploads`.
> "Much better!" he said, committing the changes.
> Now Terraform wants to **destroy and recreate** both S3 buckets, deleting all data inside.

This is a **dangerous** situation. The buckets contain production data, but Terraform doesn't know Jerry just renamed them - it thinks you're replacing old buckets with new ones.

## Your Mission

1. Recognize that this is a **rename**, not a replacement
2. Understand why Terraform wants to destroy resources
3. Use state operations to fix the addressing without recreating resources
4. Achieve a clean `terraform plan` with zero changes
5. Verify no data was lost

## Prerequisites

- Completed Jerry-07 (Deleted Resource) or Foundation 02 (State Commands)
- Understanding of Terraform state addressing
- AWS credentials configured

## Setup

```bash
# Navigate to this exercise
cd exercises/state/jerry-08-rename-refactor

# Create your workspace
mkdir -p student-work
cp -r setup/* student-work/
cd student-work

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your student name

# Initialize and apply the ORIGINAL infrastructure
terraform init
terraform apply -auto-approve

# Note the bucket names - they contain real data
terraform output
```

### Let Jerry "Improve" the Code

**Option 1: Using jerry-ctl** (if installed)
```bash
jerry move --scenario rename
```

**Option 2: Using simulation script** (always available)
```bash
# From student-work directory
../.validator/simulate-jerry.sh
```

Both options will:
1. Back up the original `main.tf` as `main.tf.backup`
2. Rename resources in `main.tf` from generic names to descriptive names
3. **NOT** update the state file (this is the problem!)

## What You'll See

After Jerry's "improvement", run `terraform plan`:

```
$ terraform plan

Terraform will perform the following actions:

  # aws_s3_bucket.bucket1 will be destroyed
  # (because aws_s3_bucket.bucket1 is not in configuration)
  - resource "aws_s3_bucket" "bucket1" {
      - bucket = "app-bucket1-abc123" -> null
      - tags   = { ... }
      # (10 more attributes)
    }

  # aws_s3_bucket.bucket2 will be destroyed
  # (because aws_s3_bucket.bucket2 is not in configuration)
  - resource "aws_s3_bucket" "bucket2" {
      - bucket = "app-bucket2-def456" -> null
      - tags   = { ... }
      # (10 more attributes)
    }

  # aws_s3_bucket.application_data will be created
  + resource "aws_s3_bucket" "application_data" {
      + bucket = "app-bucket1-abc123"
      + tags   = { ... }
      # (10 more attributes)
    }

  # aws_s3_bucket.user_uploads will be created
  + resource "aws_s3_bucket" "user_uploads" {
      + bucket = "app-bucket2-def456"
      + tags   = { ... }
      # (10 more attributes)
    }

Plan: 2 to add, 0 to change, 2 to destroy.
```

**DANGER:** If you run `terraform apply` now, you'll delete production data!

## The Critical Problem

The bucket **names** are the same (`app-bucket1-abc123`), but the Terraform **resource addresses** changed:
- `aws_s3_bucket.bucket1` → `aws_s3_bucket.application_data`
- `aws_s3_bucket.bucket2` → `aws_s3_bucket.user_uploads`

Terraform sees:
1. Old addresses in state → "These must be deleted"
2. New addresses in code → "These must be created"

It doesn't know they're the same buckets!

## How to Fix It

You have **two modern solutions**:

### Option A: Using `terraform state mv` (Imperative)

Move each resource in the state to match the new code:

```bash
# Move bucket1 to its new name
terraform state mv aws_s3_bucket.bucket1 aws_s3_bucket.application_data

# Move bucket2 to its new name
terraform state mv aws_s3_bucket.bucket2 aws_s3_bucket.user_uploads

# Verify no changes needed
terraform plan
```

**Pros:**
- Immediate fix
- Easy to understand
- Works for any Terraform version

**Cons:**
- Manual process
- Not tracked in code
- Team members don't know you did this

### Option B: Using `moved` blocks (Declarative - Terraform 1.1+)

Add migration instructions to your `main.tf`:

```hcl
# Tell Terraform about the renames
moved {
  from = aws_s3_bucket.bucket1
  to   = aws_s3_bucket.application_data
}

moved {
  from = aws_s3_bucket.bucket2
  to   = aws_s3_bucket.user_uploads
}

# Your renamed resources
resource "aws_s3_bucket" "application_data" {
  # ... existing config
}

resource "aws_s3_bucket" "user_uploads" {
  # ... existing config
}
```

Then run:
```bash
terraform plan  # Shows Terraform understands the move
terraform apply # Applies the state migration
```

**Pros:**
- Documented in code
- Team can see what happened
- Repeatable (works on other environments)
- Can be code-reviewed

**Cons:**
- Requires Terraform 1.1+
- Adds temporary code (remove after migration)

## Learning Objectives

After completing this exercise, you'll be able to:

- [ ] Recognize a resource rename vs. replacement in plan output
- [ ] Explain why renaming breaks state association
- [ ] Use `terraform state mv` to fix resource addressing
- [ ] Write `moved` blocks for declarative migrations
- [ ] Choose the right approach for your situation

## Key Concepts

### State Addressing

Terraform tracks resources by their **full address**:
```
<resource_type>.<resource_name>
```

Examples:
- `aws_s3_bucket.bucket1` ← In state
- `aws_s3_bucket.application_data` ← In code

If these don't match, Terraform thinks they're different resources!

### When Does This Happen?

Resource renames occur during:
- Code refactoring for clarity
- Standardizing naming conventions
- Merging duplicate resources
- Reorganizing module structure

### State Operations are Safe

Moving resources in state **does not** touch AWS:
```bash
terraform state mv aws_s3_bucket.bucket1 aws_s3_bucket.application_data
```

This command:
- ✅ Updates state addressing
- ✅ Preserves all resource attributes
- ❌ Does NOT modify AWS infrastructure
- ❌ Does NOT cause downtime

### The Plan is Your Safety Net

**Always** run `terraform plan` after state operations:
```bash
terraform plan
```

Success looks like:
```
No changes. Your infrastructure matches the configuration.
```

## Hints

<details>
<summary>Hint 1: How can you tell it's a rename?</summary>

Look at the bucket names in the plan:
- Resources being destroyed: `bucket = "app-bucket1-abc123"`
- Resources being created: `bucket = "app-bucket1-abc123"`

**Same bucket name = rename, not replacement!**

</details>

<details>
<summary>Hint 2: What changed in the code?</summary>

Compare `main.tf.backup` (original) with `main.tf` (Jerry's version):

```bash
diff main.tf.backup main.tf
```

You'll see only the resource names changed, not the bucket names.

</details>

<details>
<summary>Hint 3: What's in the state?</summary>

List resources in state:
```bash
terraform state list
```

You'll see:
```
aws_s3_bucket.bucket1
aws_s3_bucket.bucket2
random_id.suffix1
random_id.suffix2
```

But your code has:
```
aws_s3_bucket.application_data
aws_s3_bucket.user_uploads
```

The addresses don't match!

</details>

<details>
<summary>Hint 4: Using state mv</summary>

```bash
# Move first bucket
terraform state mv aws_s3_bucket.bucket1 aws_s3_bucket.application_data

# Move second bucket
terraform state mv aws_s3_bucket.bucket2 aws_s3_bucket.user_uploads

# Also move the random_id resources if they were renamed
terraform state mv random_id.suffix1 random_id.app_suffix
terraform state mv random_id.suffix2 random_id.uploads_suffix

# Verify
terraform plan
```

</details>

<details>
<summary>Hint 5: Using moved blocks</summary>

Add this to your `main.tf` (before the resource definitions):

```hcl
# State migration blocks
moved {
  from = aws_s3_bucket.bucket1
  to   = aws_s3_bucket.application_data
}

moved {
  from = aws_s3_bucket.bucket2
  to   = aws_s3_bucket.user_uploads
}

moved {
  from = random_id.suffix1
  to   = random_id.app_suffix
}

moved {
  from = random_id.suffix2
  to   = random_id.uploads_suffix
}
```

Then:
```bash
terraform plan   # Should show no infrastructure changes, only state moves
terraform apply  # Applies the state migration
```

After successful migration, you can remove the `moved` blocks.

</details>

## Validation

```bash
# Option 1: Using jerry-ctl (if installed)
jerry validate

# Option 2: Using validation script
../.validator/validate.sh
```

### Success Criteria

- [ ] `terraform plan` shows no changes
- [ ] Buckets still exist in AWS (not destroyed)
- [ ] State addresses match code addresses
- [ ] No data was lost

## Discussion Questions

1. **Why didn't Terraform detect the rename automatically?**
   - Terraform tracks by resource address, not bucket name
   - Two different addresses = two different resources (to Terraform)
   - The physical resource name is just another attribute

2. **When should you use `state mv` vs `moved` blocks?**
   - `state mv`: Quick fixes, local development, one-off migrations
   - `moved` blocks: Team environments, multi-environment deployments, audit trail

3. **What if you renamed 50 resources?**
   - Write a script to generate `moved` blocks
   - Use `terraform state list` to find old names
   - Use tools like `terraformer` or `tfmigrate`

4. **Can this happen with other changes?**
   - Yes! Moving resources between modules (Jerry-09)
   - Changing count/for_each indexes
   - Splitting resources into multiple instances

## Key Takeaways

1. **Resource address ≠ resource name** - They're different concepts
2. **Plan before apply** - Could have prevented this disaster
3. **State operations are safe** - They only update metadata
4. **Moved blocks are better** - When working with teams
5. **Refactoring requires state care** - Code changes aren't enough

## Real-World Story

This exact scenario happened at a major tech company in 2023:
- Developer renamed 30+ resources for clarity
- Didn't update state
- CI/CD pipeline auto-approved the plan
- 15 production databases were destroyed
- 6 hours of downtime
- Data restored from backups (fortunately they had them)

**The lesson:** Always review destructive plans carefully, even during "simple" refactoring.

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
# If you want to try again without destroying
../.validator/reset.sh

# Then recreate Jerry's mess
../.validator/simulate-jerry.sh
```

## What's Next?

- **Jerry 09**: Module refactor (same problem, but with modules!)
- **Jerry 10**: Chaos day (multiple problems combined)

---

## Files in This Exercise

```
jerry-08-rename-refactor/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl configuration
├── setup/
│   ├── providers.tf             # Terraform & AWS provider config
│   ├── backend.tf               # S3 backend configuration
│   ├── main.tf                  # ORIGINAL: bucket1, bucket2
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Example variable values
│   └── .gitignore               # Ignore state files
├── .validator/
│   ├── validate.sh              # Validation script
│   ├── simulate-jerry.sh        # Renames resources (jerry-ctl alternative)
│   └── reset.sh                 # Reset exercise
└── student-work/                # Your workspace (created during setup)
```

## Exam Objectives Covered

| Objective | Description |
|-----------|-------------|
| **6d** | Resource drift and Terraform state management |
| **7b** | CLI workflow and state inspection/modification |
