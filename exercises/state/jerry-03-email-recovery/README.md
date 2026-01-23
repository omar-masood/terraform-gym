# Jerry-03: Email Recovery

**Difficulty:** Intermediate
**Exam Objectives:** 6a, 6c, 6d, 7b
**Jerry Track:** State Management Chaos

## The Email from Jerry

```
From: jerry@company.com
To: you@company.com
Subject: FW: My Terraform Backup - URGENT HELP NEEDED
Date: Today, 6:47 AM

Hey,

My laptop's hard drive just died. Like, completely dead. Won't even boot.

I was working on some production S3 infrastructure from my laptop using
Terraform with local state (I know, I know... you told me to use the remote
backend but I was "just testing" and then it became production and I never
got around to migrating it).

The good news: I emailed myself a backup of the terraform.tfstate file last
week! I've attached it to this email.

The bad news: That's the ONLY copy of the state file. It's not in git (state
files shouldn't be committed, right?). The infrastructure is definitely still
running in AWS because I can see the bucket in the console.

Can you help me recover this? I'm out sick today and won't be able to help.
Just need to get the state back so we can manage this infrastructure again.

The Terraform config files are in our git repo in the setup/ folder.

Thanks!
Jerry

P.S. - I promise I'll set up a remote backend after this is fixed. This was
too stressful.
```

**Attachment:** `jerry-backup.tfstate`

## What Happened?

Jerry was managing AWS infrastructure with Terraform on his laptop using **local state** (no remote backend). His laptop's hard drive failed catastrophically. The AWS resources still exist, but the state file that tells Terraform about them is gone.

Fortunately, Jerry had emailed himself a copy of his `terraform.tfstate` file as a "backup." Now you need to recover the state so the team can manage this infrastructure again.

## Your Mission

1. **Understand the situation:**
   - AWS resources exist (created by Jerry's Terraform)
   - State file is lost (laptop died)
   - You have Jerry's emailed state backup (`jerry-backup.tfstate`)
   - Terraform configuration is in git (`setup/` folder)

2. **Set up the scenario:**
   ```bash
   cd setup/
   ./.validator/simulate-jerry.sh
   ```
   This creates the AWS resources that Jerry originally built (simulating the existing infrastructure).

3. **Examine Jerry's state backup:**
   - Look at the structure of `jerry-backup.tfstate`
   - Understand what resources it tracks
   - Note the bucket name and resource IDs

4. **Attempt to run Terraform:**
   ```bash
   terraform init
   terraform plan
   ```
   What happens? Why?

5. **Recover the state file** using one of these methods:
   - **Method A:** `terraform state push` (quick recovery)
   - **Method B:** Migrate to S3 backend (proper fix)
   - **Method C:** `terraform import` (if state is corrupted)

6. **Verify recovery:**
   ```bash
   terraform plan
   ```
   Should show "No changes" - infrastructure matches state.

7. **Prevent future disasters:**
   - Configure a proper remote backend (S3)
   - Enable state file versioning
   - Document the recovery process

## Learning Objectives

By completing this exercise, you will:

- Understand the critical role of state files in Terraform
- Learn state file structure and contents
- Practice state recovery using `terraform state push`
- Understand why local state is dangerous in real environments
- Learn to migrate from local to remote backends
- Gain experience with `terraform import` as a fallback
- Understand state file metadata (serial, lineage, version)

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform 1.5+ installed
- Completed basic Terraform exercises
- Understanding of S3 buckets

## Validation

Run the validator to check your solution:

```bash
../.validator/validate.sh
```

The validator checks:
- State file has been recovered (not empty)
- State tracks the correct resources
- `terraform plan` shows no changes
- Resources in state match AWS reality

## Hints

<details>
<summary>Hint 1: What happens with no state?</summary>

When you run `terraform plan` with no state file (or empty state), Terraform thinks no resources exist. It will want to create everything from scratch, even though the resources already exist in AWS.

Run `terraform state list` to see what's in your state file (hint: nothing initially).
</details>

<details>
<summary>Hint 2: Examining the state file</summary>

Look at `jerry-backup.tfstate`:
```bash
cat jerry-backup.tfstate | jq .
```

Key sections:
- `version`: State file format version
- `serial`: State file serial number (increments with changes)
- `lineage`: Unique ID for this state file's history
- `resources`: Array of managed resources
- `outputs`: Output values

This is Terraform's "memory" of what it manages.
</details>

<details>
<summary>Hint 3: Verifying AWS resources exist</summary>

Check that Jerry's infrastructure is really there:
```bash
# Get bucket name from state file
BUCKET_NAME=$(cat jerry-backup.tfstate | jq -r '.resources[] | select(.type=="aws_s3_bucket") | .instances[0].attributes.bucket')

# Check if it exists in AWS
aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null && echo "Bucket exists!" || echo "Bucket not found"

# Or use the helper script
../.validator/verify-aws-resources.sh
```
</details>

<details>
<summary>Hint 4: The terraform state push command</summary>

`terraform state push` allows you to replace the current state with a state file:

```bash
terraform state push <filename>
```

This is useful for:
- Disaster recovery (like this scenario)
- Migrating state between backends
- Restoring from backups

**Warning:** This overwrites your current state. Make sure the file is correct!
</details>

<details>
<summary>Hint 5: Step-by-step Method A (State Push)</summary>

Quick recovery using `terraform state push`:

```bash
# 1. Initialize Terraform (creates empty local state)
terraform init

# 2. Verify state is currently empty
terraform state list  # Should be empty

# 3. Push Jerry's backup state
terraform state push ../jerry-backup.tfstate

# 4. Verify state now has resources
terraform state list

# 5. Confirm plan is clean
terraform plan  # Should show "No changes"
```

Done! State recovered.
</details>

<details>
<summary>Hint 6: Migrating to S3 backend after recovery</summary>

After recovering the state, migrate to S3 to prevent future disasters:

```bash
# 1. First recover state using Method A (state push)

# 2. Create S3 backend configuration
cat > backend.tf << 'EOF'
terraform {
  backend "s3" {
    bucket = "my-terraform-state-bucket"  # Change this
    key    = "jerry-recovery/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF

# 3. Create the S3 bucket (if it doesn't exist)
aws s3 mb s3://my-terraform-state-bucket
aws s3api put-bucket-versioning \
  --bucket my-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# 4. Reinitialize and migrate state
terraform init -migrate-state

# 5. Verify
terraform plan
```

Now your state is safely in S3 with versioning enabled!
</details>

<details>
<summary>Hint 7: Alternative - Import if state push fails</summary>

If the state file is corrupted or incompatible, you can rebuild state using import:

```bash
# 1. Initialize with empty state
terraform init

# 2. Get bucket name from AWS or jerry-backup.tfstate
BUCKET_NAME="jerry-important-data-xxxxx"

# 3. Import the bucket
terraform import aws_s3_bucket.important_data "$BUCKET_NAME"

# 4. Import the versioning configuration
terraform import aws_s3_bucket_versioning.important_data "$BUCKET_NAME"

# 5. Verify
terraform plan
```

This recreates state from scratch by querying AWS.
</details>

## Discussion Questions

1. **Why is local state dangerous in production?**
   - What are the risks?
   - What happens if multiple people use local state?

2. **What if Jerry's state file was a week old?**
   - How would you detect drift?
   - What command would help reconcile differences?

3. **What information does a state file contain?**
   - Why does Terraform need this information?
   - Could you reconstruct it manually?

4. **How would you prevent this scenario in real life?**
   - What backend would you use?
   - What additional safeguards would you implement?

5. **What's the difference between state and configuration?**
   - Configuration (.tf files) = what you WANT
   - State (.tfstate files) = what you HAVE
   - Why do you need both?

## Real-World Connection

This scenario happens more often than you'd think:

- Contractors/consultants leave with state files on their laptops
- Developers testing "locally" that becomes production
- Legacy projects without proper backend configuration
- Laptop theft, hardware failure, or accidental deletion
- Team members working in silos without collaboration

**Prevention is better than recovery:**
- Always use remote backends (S3, Terraform Cloud, etc.)
- Enable versioning on state storage
- Never work from production on a laptop
- Automate state backups (though remote backends are better)
- Use proper access controls and locking

## Success Criteria

You've successfully completed this exercise when:

- [ ] You understand why Terraform can't see the existing infrastructure initially
- [ ] You've examined the state file structure and understand its contents
- [ ] You've verified the AWS resources exist and match the state file
- [ ] You've recovered the state using at least one method
- [ ] `terraform plan` shows "No changes"
- [ ] `terraform state list` shows both resources
- [ ] You understand how to prevent this scenario
- [ ] The validator passes

## Going Further

1. **Experiment with state commands:**
   ```bash
   terraform state list
   terraform state show aws_s3_bucket.important_data
   terraform show
   ```

2. **Compare state file versions:**
   - Make a small change (add a tag)
   - Run `terraform apply`
   - Compare old vs new state files
   - Notice what changed (serial number, attributes)

3. **Test import from scratch:**
   - Delete your state file
   - Use `terraform import` for all resources
   - Compare imported state to Jerry's original

4. **Set up S3 backend with locking:**
   - Add DynamoDB table for state locking
   - Configure backend with both bucket and table
   - Test concurrent access protection

## Files in This Exercise

```
jerry-03-email-recovery/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl config (for consistency)
├── jerry-backup.tfstate         # Jerry's emailed state file backup
├── setup/
│   ├── providers.tf             # AWS provider configuration
│   ├── backend.tf               # Local backend (initially)
│   ├── main.tf                  # Infrastructure configuration
│   ├── variables.tf             # Variables
│   ├── outputs.tf               # Outputs
│   └── .gitignore               # Ignore state files
├── .validator/
│   ├── validate.sh              # Validates solution
│   ├── simulate-jerry.sh        # Creates AWS resources to match state
│   ├── reset.sh                 # Cleanup for retry
│   └── verify-aws-resources.sh  # Checks resources exist in AWS
└── solution/
    ├── SOLUTION.md              # Complete solution guide
    ├── backend-s3.tf            # Example S3 backend config
    └── import-blocks.tf         # Example import blocks
```

## Next Steps

After completing this exercise:
- Proceed to **jerry-04-tag-drift** to learn about detecting configuration drift
- Review the **state management best practices** guide
- Practice migrating local state to Terraform Cloud
- Learn about `terraform state rm` and `terraform state mv` commands

---

**Remember:** State files are Terraform's memory. Without state, Terraform doesn't know what infrastructure it manages. Always use remote backends with versioning for production workloads!
