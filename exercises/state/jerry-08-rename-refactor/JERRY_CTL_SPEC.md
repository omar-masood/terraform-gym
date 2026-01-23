# Jerry-ctl Command Specification: Move Scenario (Rename)

## Overview

This document specifies the expected behavior of the `jerry move --scenario rename` command for exercise jerry-08-rename-refactor.

## Command Syntax

```bash
jerry move --scenario rename
```

## Purpose

Simulates Jerry "improving" resource names in Terraform configuration files without properly updating the state file, creating a dangerous situation where `terraform plan` shows destroy/create operations for resources that should only be renamed.

## Prerequisites

Before running this command:
1. Student must be in the `student-work` directory
2. Terraform must be initialized (`.terraform/` directory exists)
3. Infrastructure must be deployed (`terraform apply` has been run)
4. State must contain the original resource addresses:
   - `aws_s3_bucket.bucket1`
   - `aws_s3_bucket.bucket2`
   - `random_id.suffix1`
   - `random_id.suffix2`
   - Plus dependent resources (versioning, encryption, public access blocks)

## Command Behavior

### 1. Validation Phase

**Check working directory:**
- Verify `main.tf` exists
- Verify `.terraform/` directory exists
- Verify state file exists (local or remote)

**Check state:**
- Run `terraform state list`
- Verify original resources exist:
  - `aws_s3_bucket.bucket1`
  - `aws_s3_bucket.bucket2`

**Exit with error if:**
- Not in correct directory
- Terraform not initialized
- Original resources not found in state

### 2. Backup Phase

**Create backups:**
- Copy `main.tf` → `main.tf.backup`
- Create `.jerry/` directory if it doesn't exist

### 3. Refactor Phase

**Resource renames in `main.tf`:**

| Original | Renamed |
|----------|---------|
| `resource "random_id" "suffix1"` | `resource "random_id" "app_suffix"` |
| `resource "random_id" "suffix2"` | `resource "random_id" "uploads_suffix"` |
| `resource "aws_s3_bucket" "bucket1"` | `resource "aws_s3_bucket" "application_data"` |
| `resource "aws_s3_bucket" "bucket2"` | `resource "aws_s3_bucket" "user_uploads"` |

**Reference updates:**

All references to renamed resources must also be updated:
- `random_id.suffix1` → `random_id.app_suffix`
- `random_id.suffix2` → `random_id.uploads_suffix`
- `aws_s3_bucket.bucket1` → `aws_s3_bucket.application_data`
- `aws_s3_bucket.bucket2` → `aws_s3_bucket.user_uploads`

**Dependent resource renames:**

All dependent resources must follow the naming pattern:
- `aws_s3_bucket_versioning.bucket1` → `aws_s3_bucket_versioning.application_data`
- `aws_s3_bucket_versioning.bucket2` → `aws_s3_bucket_versioning.user_uploads`
- `aws_s3_bucket_server_side_encryption_configuration.bucket1` → `...application_data`
- `aws_s3_bucket_server_side_encryption_configuration.bucket2` → `...user_uploads`
- `aws_s3_bucket_public_access_block.bucket1` → `...application_data`
- `aws_s3_bucket_public_access_block.bucket2` → `...user_uploads`

**Comment updates:**
- Update inline comments to reflect new naming
- Remove or update any "Jerry will rename" comments

### 4. State Handling

**CRITICAL: Do NOT update state**

The command must NOT run any of these:
- `terraform state mv`
- `terraform apply`
- Any state modification commands

The state file must remain with original addresses, creating the mismatch scenario.

### 5. Manifest Creation

Create `.jerry/manifest.json`:

```json
{
    "version": "1.0",
    "exercise": "jerry-08-rename-refactor",
    "created_at": "2025-12-16T10:30:00Z",
    "scenarios": [
        {
            "type": "move",
            "status": "active",
            "created_at": "2025-12-16T10:30:00Z",
            "details": {
                "scenario": "rename",
                "renames": [
                    {
                        "from": "aws_s3_bucket.bucket1",
                        "to": "aws_s3_bucket.application_data"
                    },
                    {
                        "from": "aws_s3_bucket.bucket2",
                        "to": "aws_s3_bucket.user_uploads"
                    },
                    {
                        "from": "random_id.suffix1",
                        "to": "random_id.app_suffix"
                    },
                    {
                        "from": "random_id.suffix2",
                        "to": "random_id.uploads_suffix"
                    }
                ],
                "backup_file": "main.tf.backup"
            }
        }
    ],
    "hints_used": 0,
    "start_time": "2025-12-16T10:30:00Z"
}
```

### 6. Output Phase

**Display to student:**

```
🔧 Jerry is about to 'improve' your resource names...

✓ Checking infrastructure deployed... OK
✓ Backing up original main.tf... OK

Jerry is 'improving' the resource names for clarity...

✅ Done! Jerry renamed the resources.

What Jerry changed:

  Resource Name Changes:
    aws_s3_bucket.bucket1           → aws_s3_bucket.application_data
    aws_s3_bucket.bucket2           → aws_s3_bucket.user_uploads
    random_id.suffix1               → random_id.app_suffix
    random_id.suffix2               → random_id.uploads_suffix

  Plus all dependent resources (versioning, encryption, public access blocks)

Current state addresses (Jerry didn't update these!):
  aws_s3_bucket.bucket1
  aws_s3_bucket.bucket2
  aws_s3_bucket_versioning.bucket1
  aws_s3_bucket_versioning.bucket2
  ... (more resources)

⚠️  WARNING: STATE DOES NOT MATCH CODE!

  The state file still has the OLD resource names,
  but main.tf now has NEW resource names.

Now run 'terraform plan' to see the DANGER...

  Terraform will want to:
    - DESTROY aws_s3_bucket.bucket1 (and bucket2)
    - CREATE aws_s3_bucket.application_data (and user_uploads)

  This would DELETE all data in the buckets!

Your mission:
  Fix the state addressing WITHOUT destroying resources.
  Use either:
    - terraform state mv (imperative approach)
    - moved blocks (declarative approach)

Manifest created at .jerry/manifest.json
Original main.tf backed up to main.tf.backup
```

## Expected Student Behavior

After running this command, students should:

1. **Investigate:** Run `terraform plan` and see the destroy/create plan
2. **Analyze:** Recognize this is a rename, not a replacement (same bucket names)
3. **Compare:** Use `diff main.tf.backup main.tf` to see what changed
4. **Check state:** Run `terraform state list` to see current addresses
5. **Fix:** Use one of two approaches:

   **Option A: terraform state mv**
   ```bash
   terraform state mv aws_s3_bucket.bucket1 aws_s3_bucket.application_data
   terraform state mv aws_s3_bucket.bucket2 aws_s3_bucket.user_uploads
   # ... plus all dependent resources
   ```

   **Option B: moved blocks**
   ```hcl
   moved {
     from = aws_s3_bucket.bucket1
     to   = aws_s3_bucket.application_data
   }
   # ... additional moved blocks
   ```

6. **Verify:** Run `terraform plan` and confirm no changes

## Validation

The `jerry validate` command should check:

1. ✅ Terraform plan shows no changes (exit code 0)
2. ✅ State contains new addresses (application_data, user_uploads)
3. ✅ State does NOT contain old addresses (bucket1, bucket2)
4. ✅ Buckets still exist in AWS (not destroyed)
5. ✅ Resource count matches expected (no resources lost)

## Error Handling

**If infrastructure doesn't exist:**
```
Error: Infrastructure not deployed
Run 'terraform init' and 'terraform apply' first
```

**If resources already renamed in state:**
```
Warning: Resources already migrated
State contains new addresses. Exercise may have been completed or reset.
Use 'jerry reset' to restore original state.
```

**If main.tf already has new names:**
```
Warning: Code already refactored
main.tf contains new resource names. Scenario may already be active.
```

## Reset Behavior

The `jerry reset` command should:
1. Restore `main.tf` from `main.tf.backup`
2. Optionally reset state addresses back to original names
3. Remove `.jerry/` directory
4. Remove `main.tf.backup` file

## Integration with jerry.yaml

This behavior is configured in `jerry.yaml`:

```yaml
scenarios:
  - type: move
    config:
      scenario: rename
      renames:
        - from: aws_s3_bucket.bucket1
          to: aws_s3_bucket.application_data
        # ... additional renames
      backup_original: true
      backup_file: main.tf.backup
```

## Implementation Notes

### File Modification Strategy

Use safe file replacement:
1. Read `main.tf` into memory
2. Apply all rename transformations
3. Write to temporary file
4. Validate syntax (optional: `terraform validate`)
5. Atomic rename temp → `main.tf`

### Pattern Matching

Must handle:
- Resource definitions: `resource "TYPE" "NAME"`
- Resource references: `TYPE.NAME`
- String references: `"NAME"` (in certain contexts)
- Comments with resource names

Use word boundary matching to avoid partial matches:
- ✅ `bucket1` → `application_data`
- ❌ `my_bucket1` should NOT change

### Testing

Manual test checklist:
1. ✅ Renames resource definitions correctly
2. ✅ Updates all references
3. ✅ Updates dependent resources
4. ✅ Preserves formatting and comments
5. ✅ Creates valid Terraform syntax
6. ✅ Does NOT modify state
7. ✅ Creates backup successfully
8. ✅ Creates manifest with correct metadata

## Related Commands

- `jerry move --scenario module` - Jerry-09 (similar but moves to module)
- `jerry validate` - Validates student's solution
- `jerry reset` - Resets exercise to initial state
- `jerry status` - Shows current exercise status
- `jerry hints` - Provides progressive hints

## Dependencies

- Terraform CLI (for state operations validation)
- AWS CLI (for bucket existence checks in validation)
- jq (for manifest JSON creation/parsing)

## Exit Codes

- `0` - Success
- `1` - Invalid environment (not initialized, wrong directory)
- `2` - Resources not found (infrastructure not deployed)
- `3` - File operation error (backup failed, write failed)

---

**Document Version:** 1.0
**Last Updated:** 2025-12-16
**Related Exercise:** jerry-08-rename-refactor
**Implementation Priority:** Phase 3 (Refactoring Scenarios)
