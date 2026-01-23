# 🏷️ Jerry 04: The Tag Drift

**Time:** 20-25 minutes | **Difficulty:** ⭐⭐ Intermediate

## The Situation

> Jerry noticed a bucket wasn't showing up correctly in AWS Cost Explorer.
> He "quickly" added some tags in the AWS Console to fix it.
> "I'll update the Terraform later" he said. That was 3 weeks ago.

Now your Terraform code and AWS reality don't match. When you run `terraform plan`, it wants to change tags that Jerry added.

## Your Mission

1. Detect the drift between Terraform and AWS
2. Understand what changed
3. Decide how to resolve the drift
4. Implement your resolution
5. Achieve a clean `terraform plan`

## Prerequisites

- AWS credentials configured
- Terraform 1.9.0+ installed
- Understanding of Terraform plan output

## Setup

```bash
# Navigate to this exercise
cd exercises/state/jerry-04-tag-drift

# Create your workspace
mkdir -p student-work
cp -r setup/* student-work/
cd student-work

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your student name

# Initialize Terraform
terraform init

# Apply the base infrastructure
terraform apply -auto-approve

# Verify it worked
terraform output bucket_name
```

### Let Jerry Create the Drift

**Option 1: Using jerry-ctl** (if installed)
```bash
jerry drift --scenario tags
```

**Option 2: Using simulation script** (always available)
```bash
# From student-work directory
../.validator/simulate-jerry.sh
```

Both options will modify the S3 bucket tags directly in AWS, creating drift.

## What You'll See

After Jerry messes with the tags, run `terraform plan`:

```
$ terraform plan

aws_s3_bucket.data: Refreshing state...

Terraform will perform the following actions:

  # aws_s3_bucket.data will be updated in-place
  ~ resource "aws_s3_bucket" "data" {
        id     = "company-data-student-abc123"
      ~ tags   = {
          - "CostCenter"  = "JERRY-FIXME" -> null
          ~ "Environment" = "Production" -> "Learning"
          + "ManagedBy"   = "Terraform"
        }
        # (other attributes unchanged)
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

## The Critical Decision

You have **two valid options**:

### Option A: Enforce Terraform (Revert Jerry's Changes)
```bash
terraform apply
```
- Removes Jerry's `CostCenter` tag
- Reverts `Environment` back to "Learning"
- Restores `ManagedBy = "Terraform"`
- **Good when:** Terraform is the source of truth

### Option B: Update Terraform (Accept Jerry's Changes)
Edit your `main.tf` to match what Jerry did:
```hcl
tags = {
  Name        = "Company Data Bucket"
  Environment = "Production"       # Accept Jerry's change
  CostCenter  = "JERRY-FIXME"      # Keep Jerry's addition
  # ManagedBy removed - accepting Jerry's deletion
}
```
Then verify:
```bash
terraform plan  # Should show no changes
```
- **Good when:** Jerry's changes are actually correct

## Learning Objectives

After completing this exercise, you'll be able to:

- [ ] Detect drift using `terraform plan`
- [ ] Read and interpret drift in plan output
- [ ] Evaluate resolution strategies
- [ ] Explain when to choose each approach

## Key Concepts

### What is Drift?

Drift occurs when actual infrastructure differs from Terraform's configuration:
- Manual console changes
- CLI modifications
- Other tools/scripts
- AWS auto-modifications

### Detecting Drift

```bash
# Standard plan (detects drift)
terraform plan

# Refresh-only mode (see drift without proposing changes)
terraform plan -refresh-only
```

### Reading Plan Output

```
~ "Environment" = "Production" -> "Learning"
                   ^^^^^^^^^^^    ^^^^^^^^^^
                   CURRENT (AWS)  TERRAFORM WANTS
```

- `~` = modify in place
- `-` = remove (exists in AWS, not in Terraform)
- `+` = add (in Terraform, missing from AWS)

### Checking AWS Directly

```bash
# See actual tags in AWS
aws s3api get-bucket-tagging --bucket $(terraform output -raw bucket_name)
```

## Hints

<details>
<summary>Hint 1: What does the plan tell you?</summary>

Look at the `tags` block in the plan output. The arrows (`->`) show:
- Left side: Current value in AWS
- Right side: What Terraform wants to set

</details>

<details>
<summary>Hint 2: How to see what's actually in AWS?</summary>

```bash
# Get the bucket name
BUCKET=$(terraform output -raw bucket_name)

# See the current tags
aws s3api get-bucket-tagging --bucket $BUCKET
```

</details>

<details>
<summary>Hint 3: Option A - Revert to Terraform</summary>

Just run `terraform apply` to enforce your Terraform configuration.

Terraform will:
- Remove `CostCenter` tag
- Change `Environment` back to "Learning"
- Add back `ManagedBy = "Terraform"`

</details>

<details>
<summary>Hint 4: Option B - Accept Jerry's changes</summary>

Edit your `main.tf` to match what's actually in AWS:

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "company-data-${var.student_name}-${random_id.suffix.hex}"

  tags = {
    Name        = "Company Data Bucket"
    Environment = "Production"       # Was "Learning"
    CostCenter  = "JERRY-FIXME"      # Added by Jerry
    # ManagedBy removed (Jerry deleted it)
  }
}
```

</details>

<details>
<summary>Hint 5: How to verify success</summary>

After either option, run:
```bash
terraform plan
```

Success looks like:
```
No changes. Your infrastructure matches the configuration.
```

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
- [ ] You can explain WHY you chose your approach

## Discussion Questions

1. **When would Option A be better?**
   - Security-sensitive resources
   - Compliance requirements
   - Terraform is the organizational standard
   - Jerry's changes were mistakes

2. **When would Option B be better?**
   - Jerry's changes are actually improvements
   - Changes reflect business decisions
   - Immediate apply would cause issues
   - Need to preserve Jerry's work

3. **How to prevent drift?**
   - Restrict console access (least privilege)
   - CI/CD gates for all changes
   - Automated drift detection (scheduled plans)
   - Team education and processes

## Key Takeaways

1. **Drift happens** - Even with good intentions
2. **Plan detects drift** - Always run plan before apply
3. **Two valid approaches** - Neither is always "right"
4. **Think before applying** - Understand consequences
5. **Prevention > detection** - Process and permissions matter

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

# Then recreate the drift
../.validator/simulate-jerry.sh
```

## What's Next?

- **Jerry 05**: Config drift (more dangerous than tags!)
- **Jerry 06**: Import a resource Jerry created manually

---

## Files in This Exercise

```
jerry-04-tag-drift/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl configuration
├── setup/
│   ├── providers.tf             # Terraform & AWS provider config
│   ├── backend.tf               # Backend configuration (local default)
│   ├── main.tf                  # S3 bucket with original tags
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Example variable values
│   └── .gitignore               # Ignore state files
├── .validator/
│   ├── validate.sh              # Validation script
│   ├── simulate-jerry.sh        # Creates drift (jerry-ctl alternative)
│   └── reset.sh                 # Reset exercise
└── student-work/                # Your workspace (created during setup)
```

## Exam Objectives Covered

| Objective | Description |
|-----------|-------------|
| **6d** | Resource drift and Terraform state |
| **3d** | Generate and review an execution plan |
