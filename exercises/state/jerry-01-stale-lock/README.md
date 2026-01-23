# 🔒 Jerry 01: The Stale Lock

**Time:** 15-20 minutes | **Difficulty:** ⭐ Beginner

## The Situation

> Jerry was working on his laptop, started a `terraform apply`, then went to lunch.
> His laptop is locked and he's unreachable. You need to deploy a hotfix NOW.

Every time you run `terraform plan`, you get a lock error. Jerry's half-finished apply is blocking everyone.

## Your Mission

1. Understand why the state is locked
2. Find the lock information
3. Safely unlock the state
4. Verify you can proceed with normal operations

## Prerequisites

- Completed Foundation 01 (Remote Backend) OR understand local state
- `jerry` CLI installed (included in devcontainer)

## Setup

```bash
# Navigate to this exercise
cd exercises/state/jerry-01-stale-lock

# Copy setup files to your workspace
cp -r setup/* student-work/
cd student-work

# Initialize Terraform
terraform init

# Let Jerry create the problem
jerry lock --backend local
```

## What You'll See

```
$ terraform plan

╷
│ Error: Error acquiring the state lock
│ 
│ Error message: resource temporarily unavailable
│ Lock Info:
│   ID:        a1b2c3d4-e5f6-7890-abcd-ef1234567890
│   Path:      terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       jerry@jerrys-macbook
│   Version:   1.9.0
│   Created:   2025-01-15 10:30:00.000000000 +0000 UTC
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

- [ ] Explain why Terraform uses state locking
- [ ] Identify lock information from error messages
- [ ] Safely use `terraform force-unlock`
- [ ] Know when force-unlock is appropriate

## Key Concepts

### Why State Locking?

State locking prevents concurrent operations that could corrupt state:
- Two people running `apply` simultaneously
- CI/CD pipeline and developer both modifying
- Multiple terminals running Terraform

### Local vs Remote Locks

| Backend | Lock Location |
|---------|---------------|
| Local | `.terraform.tfstate.lock.info` file |
| S3 (1.9+) | `<key>.tflock` in S3 bucket |
| S3 + DynamoDB | DynamoDB table entry |

### When is Force-Unlock Safe?

**Safe to force-unlock:**
- Process crashed or was killed
- Network disconnection
- Developer went home without unlocking
- CI runner terminated unexpectedly

**NOT safe (investigate first):**
- Another apply is actively running
- You're not sure what's happening
- Lock was created very recently

## Hints

<details>
<summary>Hint 1: Where's the lock?</summary>

For local backends, the lock is a file in your working directory. Look for files starting with `.terraform`.

</details>

<details>
<summary>Hint 2: What command unlocks state?</summary>

```bash
terraform force-unlock --help
```

</details>

<details>
<summary>Hint 3: What do you need?</summary>

You need the Lock ID from the error message. It's the UUID shown after "ID:".

</details>

<details>
<summary>Hint 4: The command</summary>

```bash
terraform force-unlock <LOCK_ID>
```

You'll be asked to confirm. Type `yes`.

</details>

<details>
<summary>Hint 5: Complete solution</summary>

```bash
# Find the lock ID from the error (or look at the file)
cat .terraform.tfstate.lock.info

# Force unlock
terraform force-unlock a1b2c3d4-e5f6-7890-abcd-ef1234567890

# Confirm with: yes

# Verify it worked
terraform plan
```

</details>

## Validation

```bash
# Check your fix
jerry validate
```

### Success Criteria

- [ ] Lock file removed
- [ ] `terraform plan` succeeds
- [ ] No state corruption

## Key Takeaways

1. **State locking prevents disasters** - Don't disable it, learn to manage it
2. **Read the error message** - It contains the Lock ID you need
3. **Force-unlock is safe** when you know why the lock exists
4. **Local locks are files** - `.terraform.tfstate.lock.info`

## Clean Up

```bash
# Reset for another try
jerry reset

# Or completely clean up
cd ..
rm -rf student-work
```

## What's Next?

- **Jerry 02**: Same problem, but with S3 backend (team scenario)
- **Foundation 04**: Deep dive into locking mechanisms

---

## Files in This Exercise

```
jerry-01-stale-lock/
├── README.md           # This file
├── jerry.yaml          # Jerry configuration
├── setup/
│   ├── main.tf         # Simple S3 bucket
│   ├── variables.tf    # Variables
│   └── outputs.tf      # Outputs
└── student-work/       # Your workspace (created by copying setup/)
```

## Exam Objectives Covered

- **6b**: State locking
- **7b**: CLI state inspection
