# Jerry-05: Config Drift

**Difficulty:** Intermediate
**Terraform Exam Objectives:** 6d (Resource drift), 3d (Execution plan), 3g (Understand destructive changes)

## The Situation

You arrive Monday morning to find this Slack message from Jerry:

> **Jerry** 9:47 PM
> Hey team! 👋 I noticed our S3 bucket was getting expensive with all that versioning enabled. Also the encryption was slowing down uploads. I went ahead and disabled both via the AWS Console to optimize for cost and performance. Bucket is running MUCH faster now! 💰⚡
> You're welcome! 😎

You have a bad feeling about this...

## What Just Happened?

Unlike [Jerry-04 (Tag Drift)](../jerry-04-tag-drift), where Jerry only modified metadata tags, **this time Jerry changed actual configuration settings** that affect:

- **Data protection** (versioning keeps previous versions of objects)
- **Security** (encryption protects data at rest)
- **Compliance** (many regulations REQUIRE encryption)

### The Key Difference

| Aspect | Tag Drift (Jerry-04) | Config Drift (Jerry-05) |
|--------|---------------------|------------------------|
| **Risk Level** | Low | **🚨 HIGH** |
| **Data Impact** | None | Potential data loss |
| **Compliance** | Unlikely affected | May violate requirements |
| **Reversible** | Fully | **Partially** (versions gone) |
| **Both Options Valid?** | Yes | **No** - Usually must re-enable |

## Learning Objectives

By completing this exercise, you will:

1. **Detect configuration drift** more serious than cosmetic changes
2. **Assess the risk** of different types of drift
3. **Understand irreversible changes** (deleted versions don't come back)
4. **Think critically before applying** - not all drift should be accepted
5. **Document your reasoning** for security-impacting decisions

## Prerequisites

- Completed [Jerry-01](../jerry-01-stale-lock) through [Jerry-04](../jerry-04-tag-drift)
- Understanding of S3 bucket security features
- AWS CLI configured with appropriate credentials

## Setup

1. **Navigate to the exercise directory:**
   ```bash
   cd exercises/state/jerry-05-config-drift/setup
   ```

2. **Copy the example variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit `terraform.tfvars` with your information:**
   ```bash
   student_name = "your-name"
   ```

4. **Initialize and apply the initial infrastructure:**
   ```bash
   terraform init
   terraform apply
   ```

   This creates an S3 bucket with:
   - ✅ Versioning enabled (protects against accidental deletes)
   - ✅ Server-side encryption (AES256)
   - ✅ Public access blocked
   - ✅ Proper tagging

5. **Verify the bucket is properly configured:**
   ```bash
   # Get the bucket name from outputs
   terraform output bucket_name

   # Check versioning status
   aws s3api get-bucket-versioning --bucket $(terraform output -raw bucket_name)

   # Check encryption
   aws s3api get-bucket-encryption --bucket $(terraform output -raw bucket_name)
   ```

## Simulating Jerry's "Optimization"

**⚠️ WARNING:** This simulates a realistic but dangerous scenario.

Run the simulation script to replicate what Jerry did:

```bash
cd ../.validator
./simulate-jerry.sh
```

This script will:
- Suspend versioning on the bucket (existing versions remain but new uploads won't be versioned)
- Remove server-side encryption configuration
- Print Jerry's justification

## Your Mission

### Step 1: Detect the Drift

```bash
cd ../setup
terraform plan
```

**🛑 STOP AND READ THE PLAN CAREFULLY**

Ask yourself:
- What resources are showing changes?
- What's the difference between "update in-place" vs "create"?
- Why does encryption show as "create" instead of "update"?

### Step 2: Assess the Risk

Before doing ANYTHING, answer these critical questions:

1. **What data protection did we lose?**
   - What happens to objects uploaded while versioning was suspended?
   - Can we recover deleted object versions? (Hint: No!)

2. **What are the compliance implications?**
   - Does your organization require encryption at rest?
   - What regulations might this violate? (HIPAA, PCI-DSS, SOC2, etc.)

3. **What's the real cost/performance impact?**
   - Is Jerry's reasoning valid?
   - What's the actual overhead of versioning and encryption?

4. **Was Jerry's process appropriate?**
   - Should infrastructure changes go through the AWS Console?
   - What's the correct process for cost optimization?

### Step 3: Choose Your Response

Unlike Jerry-04 where both options were equally valid, **this time there's usually a RIGHT answer**.

#### Option A: Re-enable Security Features (RECOMMENDED)

**When to choose this:**
- Compliance requires encryption ✅
- Data protection is important ✅
- Security is not negotiable ✅
- Cost/performance concerns are unsubstantiated ✅

**Action:**
```bash
terraform apply
```

**Consequences:**
- ✅ Restores encryption and versioning
- ✅ Future objects are protected
- ❌ **Cannot recover versions deleted while suspended**
- ✅ Meets compliance requirements

#### Option B: Accept Reduced Security

**When to choose this:**
- You have documented cost analysis showing significant savings
- Compliance doesn't require these features
- Risk has been formally assessed and accepted
- **You have written approval from security/compliance team**

**⚠️ THIS OPTION REQUIRES JUSTIFICATION**

**Action:**
```bash
# Update Terraform to match current state
# (See solution/main-option-b.tf)
```

**Consequences:**
- ❌ No versioning (can't recover deleted/overwritten objects)
- ❌ No encryption at rest
- ⚠️ May violate compliance requirements
- ⚠️ May violate security policies

### Step 4: Document Your Decision

Create a file `DECISION.md` explaining:

```markdown
# Configuration Drift Resolution Decision

## Detected Drift
- [List what changed]

## Risk Assessment
- [What are the implications?]

## Decision
- [ ] Option A: Re-enable security features
- [ ] Option B: Accept reduced security

## Justification
- [Why did you choose this option?]
- [What risks are you accepting or mitigating?]

## Follow-up Actions
- [What needs to happen next?]
- [Who needs to be notified?]
```

### Step 5: Execute Your Decision

Only after documenting your reasoning:

```bash
# If Option A (re-enable):
terraform apply

# If Option B (accept changes):
# Update your Terraform configuration to match reality
# See solution/main-option-b.tf for reference
```

### Step 6: Verify Your Fix

```bash
# Check no more drift exists
terraform plan

# Should output: "No changes. Your infrastructure matches the configuration."
```

## The Irreversible Part

**Critical Understanding:**

If Jerry had:
1. Suspended versioning
2. Then **deleted object versions** (via lifecycle policy or manually)
3. Then you re-enabled versioning

Those deleted versions are **GONE FOREVER**. Re-enabling versioning doesn't bring them back.

This is why configuration drift is scarier than tag drift.

## Validation

Run the validator to check your resolution:

```bash
cd ../.validator
./validate.sh
```

The validator checks:
- Drift is resolved (plan shows no changes)
- Current configuration matches Terraform
- You've documented your decision

## Discussion Questions

1. **Why is configuration drift more dangerous than tag drift?**

2. **What's the difference between versioning "Enabled", "Suspended", and "Never Enabled"?**

3. **Can you think of a legitimate reason to disable encryption on an S3 bucket?**

4. **How would you prevent this in a production environment?**
   - IAM policies?
   - AWS Config rules?
   - Change management processes?

5. **What should happen to Jerry?**
   - Just education?
   - Process changes?
   - Removal of console access?

## Real-World Scenarios

This exact situation happens frequently:

- **Developer disables WAF rule** because it's blocking their test traffic
- **DBA turns off backup** to speed up a migration
- **DevOps disables monitoring** during high-load event
- **Engineer opens security group** for "quick debugging"

All with good intentions. All with potentially serious consequences.

## Key Takeaways

1. **Not all drift is equal** - Configuration > Tags in severity
2. **Understand before applying** - Read the plan, assess the risk
3. **Some changes are irreversible** - Deleted data doesn't come back
4. **Security defaults exist for reasons** - Don't disable casually
5. **Process matters** - Infrastructure changes need review

## What's Next?

- **Jerry-06: Import Rescue** - When someone creates infrastructure without Terraform

## Hints

<details>
<summary>Hint 1: What's different in the plan output?</summary>

Look at the verbs:
- `will be updated in-place` - Resource exists, changing attributes
- `will be created` - Resource doesn't exist in AWS

Why would encryption need to be "created" if it existed before?

Because Jerry **deleted the configuration entirely**, not just changed it.
</details>

<details>
<summary>Hint 2: What does "Suspended" versioning mean?</summary>

S3 versioning has three states:
- **Enabled** - All new objects get version IDs
- **Suspended** - New objects don't get versions, but existing versions remain
- **Never Enabled** - Versioning was never turned on

Jerry suspended it, so:
- ✅ Existing object versions still exist
- ❌ Objects uploaded while suspended have no versions
- ⚠️ If Jerry deleted versions, they're gone
</details>

<details>
<summary>Hint 3: How to check current bucket config</summary>

```bash
BUCKET=$(terraform output -raw bucket_name)

# Check versioning
aws s3api get-bucket-versioning --bucket $BUCKET

# Check encryption
aws s3api get-bucket-encryption --bucket $BUCKET

# List all bucket configurations
aws s3api get-bucket-location --bucket $BUCKET
aws s3api get-public-access-block --bucket $BUCKET
aws s3api get-bucket-tagging --bucket $BUCKET
```
</details>

<details>
<summary>Hint 4: What are the implications?</summary>

**Security Implications:**
- Unencrypted data at rest
- No protection against accidental deletes/overwrites
- Potential compliance violations

**Operational Implications:**
- Cannot roll back to previous object versions
- Disaster recovery is harder
- Auditability is reduced

**Cost Implications:**
- Versioning does increase storage costs (you store multiple versions)
- Encryption has negligible performance impact
- But cost shouldn't override security requirements
</details>

<details>
<summary>Hint 5: Option A - Re-enable security features</summary>

Simply run:
```bash
terraform apply
```

Terraform will:
1. Update versioning configuration to "Enabled"
2. Recreate the encryption configuration

This is the right choice for most scenarios.

**Document in your DECISION.md:**
- Why security is non-negotiable
- What compliance requirements mandate this
- Follow-up: Review IAM policies to prevent console changes
</details>

<details>
<summary>Hint 6: Option B - Accept reduced security</summary>

**⚠️ ONLY choose this if you have explicit approval and documented justification.**

You would need to:

1. Remove encryption resource from Terraform:
   ```hcl
   # Comment out or delete:
   # resource "aws_s3_bucket_server_side_encryption_configuration" "important_data" {
   #   ...
   # }
   ```

2. Change versioning to suspended:
   ```hcl
   resource "aws_s3_bucket_versioning" "important_data" {
     bucket = aws_s3_bucket.important_data.id
     versioning_configuration {
       status = "Suspended"  # Changed from "Enabled"
     }
   }
   ```

3. Document in DECISION.md:
   - Written approval from security team
   - Risk acceptance from compliance
   - Business justification
   - Compensating controls

See `solution/main-option-b.tf` for reference.
</details>

<details>
<summary>Hint 7: Verify your fix</summary>

```bash
# Plan should show no changes
terraform plan

# Check actual AWS configuration
BUCKET=$(terraform output -raw bucket_name)
aws s3api get-bucket-versioning --bucket $BUCKET
aws s3api get-bucket-encryption --bucket $BUCKET

# Run validator
cd ../.validator && ./validate.sh
```
</details>

## Notes

- This exercise uses local state by default. In production, use remote state with locking.
- The simulate-jerry.sh script requires AWS CLI access to your bucket.
- Cost optimization is important, but security shouldn't be sacrificed without proper assessment.
- When in doubt, choose security first, then investigate cost concerns properly.

## Common Mistakes

1. **Running `terraform apply -auto-approve` without reading the plan**
   - Always read the plan carefully
   - Understand what's changing and why

2. **Assuming Jerry's reasoning is valid**
   - "Expensive" - compared to what? What's the actual cost?
   - "Slowing things down" - by how much? Do you have metrics?

3. **Accepting reduced security without justification**
   - Security isn't optional in most scenarios
   - Compliance requirements aren't suggestions

4. **Not documenting the decision**
   - Future you (or your teammates) need to understand why
   - Auditors will ask for justification

## Need Help?

- Review the hints above
- Check the solution directory (but try first!)
- Refer to [Terraform S3 Bucket Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket)
- Consult [AWS S3 Security Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
