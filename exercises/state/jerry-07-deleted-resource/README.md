# Jerry-07: Deleted Resource

**Difficulty:** Intermediate
**Exam Objectives:** 6d, 7b
**Jerry Track:** State Management Chaos

## The Slack Message from Jerry

```
@you Jerry Thompson 10:23 AM

Hey, I cleaned up that old logs bucket that wasn't being used anymore.
Just deleted it from the AWS console to save on costs.

We weren't using it, right? It was just sitting there empty.

Anyway, heading into meetings all day. Let me know if you need anything!
```

**5 minutes later...**

```
terraform plan

Terraform will perform the following actions:

  # aws_s3_bucket.old_logs will be created
  + resource "aws_s3_bucket" "old_logs" {
      + arn                         = (known after apply)
      + bucket                      = "old-logs-a1b2c3d4"
      + bucket_domain_name          = (known after apply)
      ...
    }

Plan: 1 to add, 0 to change, 0 to destroy.
```

Wait... create? But Jerry just deleted it!

Oh no. The bucket is gone from AWS, but it's **still in Terraform state**. Now Terraform wants to recreate it.

## What Happened?

Jerry deleted an S3 bucket directly through the AWS Console (or CLI), but he didn't update the Terraform state to reflect this change. Now there's a **state-reality mismatch**:

- **Terraform state says:** "I'm managing a bucket called `old_logs`"
- **AWS reality says:** "No such bucket exists"
- **Terraform's reaction:** "I better create that bucket that's missing!"

This is the opposite of drift. Instead of AWS having extra resources, AWS is missing resources that Terraform expects to exist.

## Your Mission

1. **Set up the scenario:**
   ```bash
   cd setup/
   ./.validator/simulate-jerry.sh
   ```
   This creates infrastructure and then simulates Jerry deleting a bucket.

2. **Investigate the situation:**
   ```bash
   terraform plan
   ```
   Notice Terraform wants to CREATE the bucket (it should exist but was deleted).

3. **Check the state:**
   ```bash
   terraform state list
   terraform state show aws_s3_bucket.old_logs
   ```
   The bucket is in state, but does it exist in AWS?

4. **Decide on the correct action:**
   - **Option A:** Let Terraform recreate the bucket (if you need it)
   - **Option B:** Remove it from state (if Jerry was right to delete it)

5. **Implement your decision and verify:**
   ```bash
   terraform plan  # Should show no changes
   ```

## Learning Objectives

By completing this exercise, you will:

- Understand the difference between state and reality
- Learn when to use `terraform state rm` vs `terraform apply`
- Practice investigating resource existence in both state and AWS
- Understand the implications of manual deletions
- Learn to make informed decisions about state cleanup
- Understand the dangers of out-of-band changes

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform 1.5+ installed
- Understanding of Terraform state
- Completed basic state exercises

## Validation

Run the validator to check your solution:

```bash
../.validator/validate.sh
```

The validator accepts EITHER solution:
- State cleaned up (bucket removed from state)
- Bucket recreated (matches state)

Both are valid depending on your decision!

## Hints

<details>
<summary>Hint 1: How to check if the bucket really exists</summary>

Use the AWS CLI to verify:

```bash
# Get bucket name from state
BUCKET_NAME=$(terraform state show aws_s3_bucket.old_logs | grep "bucket " | awk '{print $3}' | tr -d '"')

# Check if it exists in AWS
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null && echo "EXISTS" || echo "DELETED"
```

You can also check the AWS Console or use:
```bash
aws s3 ls | grep old-logs
```
</details>

<details>
<summary>Hint 2: Understanding what terraform plan is telling you</summary>

When you see:
```
# aws_s3_bucket.old_logs will be created
  + resource "aws_s3_bucket" "old_logs" {
```

The `+` means CREATE. Terraform is saying:
- "I expect this resource to exist (it's in my state)"
- "But it doesn't exist in AWS"
- "So I'll create it"

This is Terraform trying to make reality match state.
</details>

<details>
<summary>Hint 3: The two valid approaches</summary>

**Approach A: Remove from State** (Jerry was right to delete it)
```bash
terraform state rm aws_s3_bucket.old_logs
terraform plan  # Should show no changes
```

**Approach B: Let Terraform Recreate** (we actually need this bucket)
```bash
terraform apply
# Bucket will be recreated
terraform plan  # Should show no changes
```

Both are valid! It depends on whether the bucket should exist or not.
</details>

<details>
<summary>Hint 4: How to decide which approach to use</summary>

Ask yourself:
1. **Was Jerry right to delete it?**
   - If yes → Remove from state
   - If no → Let Terraform recreate it

2. **Is this resource still in our infrastructure code?**
   - If yes and we need it → Recreate
   - If no and we don't need it → Remove from state AND remove from .tf files

3. **What was the resource used for?**
   - Old/unused → Remove from state
   - Active/needed → Recreate

In this scenario, the bucket was called "old_logs" and Jerry said it "wasn't being used" - that's your hint!
</details>

<details>
<summary>Hint 5: Complete solution for Option A (Remove from state)</summary>

```bash
# 1. Verify the bucket is really gone
BUCKET_NAME=$(terraform state show aws_s3_bucket.old_logs | grep "bucket " | awk '{print $3}' | tr -d '"')
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null && echo "EXISTS" || echo "DELETED"

# 2. Remove from state
terraform state rm aws_s3_bucket.old_logs

# 3. Verify state is clean
terraform state list
# Should NOT show aws_s3_bucket.old_logs

# 4. Verify plan is clean
terraform plan
# Should show: No changes

# 5. (Optional but recommended) Remove from code too
# Edit main.tf and remove the aws_s3_bucket.old_logs resource block
```

After removing from state, you should also remove the resource from your `.tf` files so it doesn't get recreated later.
</details>

<details>
<summary>Hint 6: Complete solution for Option B (Recreate bucket)</summary>

```bash
# 1. Verify the bucket is really gone
BUCKET_NAME=$(terraform state show aws_s3_bucket.old_logs | grep "bucket " | awk '{print $3}' | tr -d '"')
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null && echo "EXISTS" || echo "DELETED"

# 2. Let Terraform recreate it
terraform apply
# Review the plan, type 'yes' to proceed

# 3. Verify the bucket exists now
aws s3api head-bucket --bucket "$BUCKET_NAME" && echo "Bucket recreated!"

# 4. Verify plan is clean
terraform plan
# Should show: No changes
```

Choose this option if the bucket is actually needed and Jerry made a mistake deleting it.
</details>

<details>
<summary>Hint 7: What about other resources?</summary>

In real scenarios, buckets might have related resources:
- `aws_s3_bucket_versioning`
- `aws_s3_bucket_public_access_block`
- `aws_s3_bucket_policy`

If you remove the bucket from state, you might also need to remove these:

```bash
terraform state rm aws_s3_bucket.old_logs
terraform state rm aws_s3_bucket_versioning.old_logs
terraform state rm aws_s3_bucket_public_access_block.old_logs
```

Or use wildcards (be careful!):
```bash
terraform state list | grep old_logs | xargs -n1 terraform state rm
```
</details>

## Discussion Questions

1. **Why didn't Terraform know the bucket was deleted?**
   - Terraform only knows what's in state
   - It doesn't continuously monitor AWS
   - Deletions outside Terraform are invisible until next plan/apply

2. **When should you recreate vs remove from state?**
   - **Recreate if:**
     - Resource is needed for application to work
     - Deletion was a mistake
     - Losing the resource would cause issues
   - **Remove if:**
     - Resource is genuinely unused
     - Cost/security reason to keep it deleted
     - Part of intentional decommissioning

3. **What if the bucket had important data?**
   - This is why manual deletions are dangerous!
   - If data is lost, you can't get it back
   - S3 versioning or backups might save you
   - Prevention: Use deletion protection, lifecycle rules

4. **How to prevent this scenario?**
   - **Terraform should be the single source of truth**
   - Use S3 bucket deletion protection:
     ```hcl
     lifecycle {
       prevent_destroy = true
     }
     ```
   - Use AWS Organizations SCPs to restrict deletions
   - Require all infrastructure changes through Terraform
   - Use RBAC to limit who can delete in console

5. **What's the difference between this and `terraform refresh`?**
   - `terraform refresh` updates state to match reality
   - In Terraform 0.15+, this happens automatically during plan
   - The issue here is deciding WHAT to do about the mismatch

## Real-World Connection

This scenario happens frequently in real organizations:

**Common Causes:**
- Team member doesn't know resource is Terraform-managed
- "Quick fix" in console during incident
- Cleanup without checking state
- Cost optimization efforts
- Decommissioning old projects

**Real Examples:**
- Deleting "unused" security groups that break Terraform
- Removing IAM roles that applications depend on
- Dropping databases to save costs (oops, that was prod!)
- Cleaning up S3 buckets before checking state

**The Golden Rule:**
> If it's in Terraform, change it through Terraform. If you change it manually, update state to reflect reality.

## Success Criteria

You've successfully completed this exercise when:

- [ ] You understand why Terraform wants to create a deleted resource
- [ ] You've investigated the state vs reality mismatch
- [ ] You've made an informed decision (recreate or remove)
- [ ] You've implemented your decision correctly
- [ ] `terraform plan` shows "No changes"
- [ ] You understand when to use each approach
- [ ] The validator passes

## Going Further

1. **Test both approaches:**
   - Try Option A (remove from state)
   - Reset the exercise
   - Try Option B (let Terraform recreate)
   - Compare the outcomes

2. **Practice with multiple resources:**
   - What if Jerry deleted 3 buckets?
   - How would you handle cleanup efficiently?

3. **Add deletion protection:**
   ```hcl
   resource "aws_s3_bucket" "protected" {
     bucket = "important-data"

     lifecycle {
       prevent_destroy = true
     }
   }
   ```
   Try deleting this with Terraform - it will refuse!

4. **Simulate data loss scenario:**
   - What if the bucket had objects?
   - How would versioning help?
   - What about bucket policies, ACLs?

5. **Practice terraform state rm variants:**
   ```bash
   # Remove single resource
   terraform state rm aws_s3_bucket.old_logs

   # Remove with module path
   terraform state rm module.storage.aws_s3_bucket.logs

   # List first, then remove
   terraform state list | grep old
   ```

## Files in This Exercise

```
jerry-07-deleted-resource/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl configuration
├── setup/
│   ├── providers.tf             # AWS provider configuration
│   ├── backend.tf               # S3 backend configuration
│   ├── main.tf                  # Infrastructure including the bucket Jerry deleted
│   ├── variables.tf             # Variables
│   └── outputs.tf               # Outputs
├── .validator/
│   ├── simulate-jerry.sh        # Creates infra, then "Jerry deletes" bucket
│   ├── validate.sh              # Validates solution (accepts both approaches)
│   └── reset.sh                 # Cleanup for retry
└── solution/
    └── SOLUTION.md              # Detailed solution for both approaches
```

## Next Steps

After completing this exercise:
- Proceed to **jerry-08-rename-refactor** to learn about `terraform state mv`
- Review the **state commands best practices** guide
- Practice with `terraform state rm` on other resources
- Learn about `prevent_destroy` lifecycle rules

---

**Remember:** Deleting resources manually is dangerous! Always use Terraform to make infrastructure changes. If you must delete manually, update the state to reflect reality.
