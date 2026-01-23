# 🔒 Jerry 02: The Remote Lock

**Time:** 20-25 minutes | **Difficulty:** ⭐⭐ Intermediate

## The Situation

> Jerry's CI/CD pipeline was running `terraform apply` when the GitHub Actions runner got terminated unexpectedly.
> Now the entire team is blocked - nobody can run Terraform commands. Every attempt fails with a lock error.

The state is stored in S3 (shared team backend), and there's a stale lock preventing all operations. You need to clear it so the team can get back to work.

## Your Mission

1. Understand why the state is locked (and why it's different from Jerry-01)
2. Locate the lock in S3
3. Identify two different methods to unlock
4. Choose and execute the appropriate unlock method
5. Verify the team can proceed with normal operations

## Prerequisites

- Completed Jerry 01 (Stale Lock) OR understand state locking basics
- AWS credentials configured with S3 access
- An S3 bucket for state storage (can use one from Week 00 or create new)
- Terraform 1.9.0+ installed

## Setup

```bash
# Navigate to this exercise
cd exercises/state/jerry-02-remote-lock

# Create your workspace
mkdir -p student-work
cp -r setup/* student-work/
cd student-work

# Configure your variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with:
# - student_name (your name)
# - state_bucket (your S3 state bucket name)

# Initialize Terraform
terraform init

# Apply the base infrastructure
terraform apply -auto-approve

# Verify it worked
terraform output bucket_name
```

### Let Jerry Create the Lock

**Option 1: Using jerry-ctl** (if installed)
```bash
jerry lock --backend s3
```

**Option 2: Using simulation script** (always available)
```bash
# From student-work directory
../.validator/simulate-jerry.sh
```

Both options will create a stale `.tflock` file in S3, simulating a crashed CI/CD pipeline.

## What You'll See

After Jerry creates the lock, run `terraform plan`:

```
$ terraform plan

╷
│ Error: Error acquiring the state lock
│
│ Error message: ConditionalCheckFailedException: Lock file already exists
│ Lock Info:
│   ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
│   Path:      gym/state/jerry-02/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       github-actions@ci-runner-12345
│   Version:   1.9.0
│   Created:   2025-01-15 10:30:00.000000 +0000 UTC
│   Info:
│
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

## Learning Objectives

After completing this exercise, you'll be able to:

- [ ] Explain the difference between local and S3 backend locks
- [ ] Locate lock files in S3
- [ ] Use `terraform force-unlock` with remote backends
- [ ] Manually remove lock files from S3 (emergency method)
- [ ] Decide which unlock method is appropriate for different scenarios

## Key Concepts

### S3 Native Locking (Terraform 1.9+)

Terraform 1.9 introduced native locking for S3 backends:
- **Old way**: Separate DynamoDB table for locks (still supported)
- **New way**: `use_lockfile = true` - locks stored in S3 itself
- **Lock file**: `<key>.tflock` created alongside state file
- **Simpler**: No extra AWS resources needed

### Lock File Structure

The `.tflock` file contains JSON:
```json
{
  "ID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "github-actions@ci-runner-12345",
  "Version": "1.9.0",
  "Created": "2025-01-15T14:30:00.000000Z",
  "Path": "gym/state/jerry-02/terraform.tfstate"
}
```

### Jerry-01 vs Jerry-02

| Aspect | Jerry-01 (Local) | Jerry-02 (S3) |
|--------|------------------|---------------|
| **Backend** | Local | S3 with native locking |
| **Lock Location** | `.terraform.tfstate.lock.info` (working directory) | `<key>.tflock` in S3 bucket |
| **Scenario** | Solo developer's laptop | Team with shared state |
| **Who Locked** | Jerry's laptop | CI/CD pipeline |
| **Typical Cause** | Process killed, laptop closed | CI runner terminated, network issue |

### Two Unlock Methods

#### Method A: terraform force-unlock (Recommended)

```bash
terraform force-unlock <LOCK_ID>
```

**Pros:**
- Official Terraform command
- Works across all backend types
- Validates the lock ID matches
- Safer (asks for confirmation)

**Cons:**
- Requires Terraform installed
- Requires valid backend credentials

#### Method B: Manual S3 Deletion (Emergency)

```bash
aws s3 rm s3://bucket-name/path/to/terraform.tfstate.tflock
```

**Pros:**
- Works when Terraform is unavailable
- Faster in emergencies
- Only needs AWS CLI

**Cons:**
- Bypasses Terraform's safety checks
- Need to construct exact S3 path
- More dangerous if lock is actually valid

### When is Force-Unlock Safe?

**Safe to force-unlock:**
- CI/CD runner terminated/crashed
- Network disconnection during apply
- Process was killed (not still running)
- Lock is several hours old
- You've confirmed no active operations

**NOT safe (investigate first):**
- Another apply is actively running
- Lock was created very recently (< 5 minutes)
- You're not sure what created the lock
- Multiple team members working simultaneously

## Hints

<details>
<summary>Hint 1: Where's the lock file?</summary>

The lock is in S3, not your working directory. It's at:
```
s3://YOUR-STATE-BUCKET/gym/state/jerry-02-remote-lock/terraform.tfstate.tflock
```

To see it:
```bash
aws s3 ls s3://$(grep bucket backend.tf | awk '{print $3}' | tr -d '"')/gym/state/jerry-02-remote-lock/
```

</details>

<details>
<summary>Hint 2: What's the Lock ID?</summary>

The Lock ID is in the error message after "ID:". It's a UUID like:
```
a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

You can also see it by downloading the lock file:
```bash
BUCKET=$(grep bucket backend.tf | awk '{print $3}' | tr -d '"')
aws s3 cp s3://$BUCKET/gym/state/jerry-02-remote-lock/terraform.tfstate.tflock - | jq .
```

</details>

<details>
<summary>Hint 3: Method A - Using force-unlock</summary>

```bash
# Get the lock ID from the error message
terraform force-unlock <LOCK_ID>

# Confirm with: yes

# Verify it worked
terraform plan
```

This is the recommended approach for normal situations.

</details>

<details>
<summary>Hint 4: Method B - Manual S3 deletion</summary>

```bash
# Get your backend bucket name
BUCKET=$(grep bucket backend.tf | awk '{print $3}' | tr -d '"')

# Remove the lock file
aws s3 rm s3://$BUCKET/gym/state/jerry-02-remote-lock/terraform.tfstate.tflock

# Verify it's gone
aws s3 ls s3://$BUCKET/gym/state/jerry-02-remote-lock/

# Verify Terraform works
terraform plan
```

Use this when:
- You don't have Terraform available
- Emergency situation requiring immediate unlock
- `force-unlock` command fails

</details>

<details>
<summary>Hint 5: Verify the lock is stale</summary>

Before unlocking, check when it was created:
```bash
BUCKET=$(grep bucket backend.tf | awk '{print $3}' | tr -d '"')
aws s3 cp s3://$BUCKET/gym/state/jerry-02-remote-lock/terraform.tfstate.tflock - | jq '.Created'
```

If it's hours old and you know the pipeline crashed, it's safe to unlock.

</details>

## Validation

```bash
# Option 1: Using jerry-ctl (if installed)
jerry validate

# Option 2: Using validation script
../.validator/validate.sh
```

### Success Criteria

- [ ] Lock file removed from S3
- [ ] `terraform plan` succeeds without lock errors
- [ ] You can explain both unlock methods
- [ ] You know when to use each method

## Discussion Questions

1. **Why does S3 native locking exist?**
   - Simpler than DynamoDB approach
   - One less service to manage
   - Lower cost (no DynamoDB table)
   - Easier to inspect (just an S3 object)

2. **When would you use manual deletion over force-unlock?**
   - Terraform binary not available (emergency access)
   - Backend configuration is broken
   - Need to unlock from a different location
   - `force-unlock` command is failing

3. **How to prevent CI/CD pipeline locks?**
   - Use pipeline timeouts
   - Implement proper error handling
   - Monitor for stuck jobs
   - Consider Terraform Cloud/Enterprise for better lock management
   - Use `-lock-timeout` flag in CI
   - Never use `-lock=false` in automation

4. **What's the risk of manual deletion?**
   - Might delete a valid lock (if operation is actually running)
   - Could cause state corruption if two operations run simultaneously
   - No verification that lock ID matches

## Key Takeaways

1. **S3 native locking is simpler** - No DynamoDB needed with Terraform 1.9+
2. **Lock files are visible** - Just S3 objects you can inspect
3. **Two unlock methods exist** - Each has appropriate use cases
4. **Remote locks are team-wide** - Unlike local locks, they block everyone
5. **CI/CD needs attention** - Pipeline failures often cause stale locks
6. **Verify before unlocking** - Check lock age and who created it

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

# Then recreate the lock
../.validator/simulate-jerry.sh
```

## What's Next?

- **Jerry 03**: State file corruption (when things go really wrong)
- **Foundation 02**: Deep dive into S3 backend configuration
- **Jerry 04**: Tag drift (manual console changes)

---

## Files in This Exercise

```
jerry-02-remote-lock/
├── README.md                    # This file
├── jerry.yaml                   # Jerry-ctl configuration
├── setup/
│   ├── providers.tf             # Terraform & AWS provider config
│   ├── backend.tf               # S3 backend with use_lockfile = true
│   ├── main.tf                  # Simple S3 bucket resource
│   ├── variables.tf             # Input variables
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Example variable values
│   └── .gitignore               # Ignore state and lock files
├── .validator/
│   ├── validate.sh              # Validation script
│   ├── simulate-jerry.sh        # Creates lock file in S3
│   └── reset.sh                 # Reset exercise
├── solution/
│   └── SOLUTION.md              # Detailed solution walkthrough
└── student-work/                # Your workspace (created during setup)
```

## Exam Objectives Covered

| Objective | Description |
|-----------|-------------|
| **6b** | State locking mechanisms |
| **6c** | Configure and use remote state (S3 backend) |
| **7b** | CLI state inspection and management |
