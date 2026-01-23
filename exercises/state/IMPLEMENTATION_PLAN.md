# State Track Implementation Plan

## Current Status Summary

### Foundation Track

| Exercise | README | Skeleton | Solution | Validator | Status |
|----------|:------:|:--------:|:--------:|:---------:|--------|
| 01: Remote Backend | ✅ | ❓ | ❓ | ❓ | **Needs Review** |
| 02: State Commands | ✅ | ❓ | ❓ | ❓ | **Needs Review** |
| 03: Import Resources | ✅ | ❓ | ❓ | ❓ | **Needs Review** |
| 04: State Locking | ❌ | ✅ | ✅ | ✅ | **Needs README** |
| Challenge: State Surgery | ✅ | ✅ | ✅ | ✅ | **Complete** |

### Jerry Track

| Exercise | README | jerry.yaml | Setup TF | Status |
|----------|:------:|:----------:|:--------:|--------|
| Jerry 01: Stale Lock | ✅ | ✅ | ✅ | **Complete** |
| Jerry 02: Remote Lock | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 03: Email Recovery | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 04: Tag Drift | ✅ | ✅ | ❓ | **Mostly Complete** |
| Jerry 05: Config Drift | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 06: Import Rescue | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 07: Deleted Resource | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 08: Rename Refactor | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 09: Module Refactor | ❌ | ❌ | ❌ | **Not Started** |
| Jerry 10: Chaos Day | ❌ | ❌ | ❌ | **Not Started** |

---

## Jerry Exercise Detailed Specifications

### Jerry 01: Stale Lock ✅ COMPLETE
**Status:** README, jerry.yaml, and setup structure exist

**Scenario:**
- Backend: LOCAL state
- Jerry ran `terraform apply` on his laptop, went to lunch
- Creates `.terraform.tfstate.lock.info` file

**Jerry-ctl Command:**
```bash
jerry lock --backend local --age 2h
```

**Student Fix:**
```bash
terraform force-unlock <LOCK_ID>
```

**Exam Objectives:** 6b (state locking), 7b (CLI inspection)

---

### Jerry 02: Remote Lock 🔲 TODO
**Scenario:**
- Backend: S3 with native locking
- Jerry's CI pipeline crashed mid-apply
- Creates `<key>.tflock` in S3 bucket

**Why Different from Jerry-01:**
- Tests S3 backend lock handling
- More realistic team scenario
- Different unlock process

**Setup Infrastructure:**
```hcl
# S3 bucket already exists from Foundation 01
# State stored in S3 with use_lockfile = true
resource "aws_s3_bucket" "app_data" {
  bucket = "app-data-${random_id.suffix.hex}"
  tags = {
    Name = "Application Data"
    Environment = "Learning"
  }
}
```

**Jerry-ctl Command:**
```bash
jerry lock --backend s3 --age 4h --who "github-actions@ci-runner"
```

**What Jerry Does:**
1. Creates `terraform.tfstate.tflock` file in S3 state bucket
2. Lock file contains JSON with lock ID, timestamp, operation

**Student Must:**
1. Identify lock is in S3 (not local)
2. Find lock file: `aws s3 ls s3://state-bucket/path/`
3. Either: `terraform force-unlock <ID>` or manually delete `.tflock` file
4. Verify with `terraform plan`

**Exam Objectives:** 6b, 6c (remote state), 7b

---

### Jerry 03: Email Recovery 🔲 TODO
**Scenario:**
- Jerry was working locally, no remote backend configured
- His laptop died, but he emailed himself the state file
- Now he's asking you to help recover

**Why This Exercise:**
- Teaches state file structure
- Shows dangers of local state
- Practices `terraform state push`
- Reinforces need for remote backends

**The Setup:**
1. Student gets a `jerry-backup.tfstate` file (provided in exercise)
2. Student gets `main.tf` that matches the state
3. Infrastructure EXISTS in AWS (created by jerry-ctl)
4. No state file in working directory

**Jerry-ctl Command:**
```bash
jerry email-recovery --state-file jerry-backup.tfstate
```

**What Jerry Does:**
1. Creates S3 bucket via AWS CLI (matches state file)
2. Provides `jerry-backup.tfstate` file in exercise directory
3. Does NOT create local state in working directory

**Student Must:**
1. Examine the emailed state file
2. Match it to existing infrastructure
3. Initialize Terraform (creates empty state)
4. Either:
   - `terraform state push jerry-backup.tfstate` (if local backend)
   - Configure backend, then handle migration
5. Verify with `terraform plan` (no changes)

**Files to Provide:**
```
jerry-03-email-recovery/
├── README.md
├── jerry.yaml
├── setup/
│   ├── main.tf           # Matches the state file
│   └── variables.tf
└── jerry-backup.tfstate  # "Emailed" from Jerry
```

**Exam Objectives:** 6a (local backend), 6d (state management), 7b

---

### Jerry 04: Tag Drift ✅ MOSTLY COMPLETE
**Status:** README and jerry.yaml exist, need to verify setup TF

**Scenario:**
- S3 backend configured
- Jerry changed tags in AWS Console
- Terraform wants to revert his changes

**Jerry-ctl Command:**
```bash
jerry drift --scenario tags --resource aws_s3_bucket.data
```

**What Jerry Changes:**
```yaml
changes:
  add:
    CostCenter: "JERRY-FIXME"
  modify:
    Environment: "Production"  # Was "Learning"
  remove:
    - ManagedBy
```

**Student Options:**
1. `terraform apply` (revert to Terraform)
2. Update `main.tf` to match Jerry's changes

**Exam Objectives:** 6d (resource drift), 3d (review plan)

---

### Jerry 05: Config Drift 🔲 TODO
**Scenario:**
- Jerry disabled versioning on an S3 bucket via Console
- "The bucket was too full, versioning was wasting space"
- More dangerous than tag drift!

**Why Different from Jerry-04:**
- Configuration changes (not just metadata)
- Potentially destructive if blindly applied
- Requires understanding implications

**Setup Infrastructure:**
```hcl
resource "aws_s3_bucket" "important_data" {
  bucket = "important-data-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_versioning" "important_data" {
  bucket = aws_s3_bucket.important_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "important_data" {
  bucket = aws_s3_bucket.important_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

**Jerry-ctl Command:**
```bash
jerry drift --scenario config --resource aws_s3_bucket_versioning.important_data
```

**What Jerry Changes:**
1. Disables versioning via AWS CLI/Console
2. Possibly also changes encryption settings

**Student Must:**
1. Detect the drift via `terraform plan`
2. Understand this is MORE than cosmetic
3. Decide: re-enable versioning OR update Terraform
4. Consider: are there objects that lost version history?

**Discussion Points:**
- Why is config drift more dangerous than tag drift?
- What data could be lost?
- How to prevent this in production?

**Exam Objectives:** 6d, 3d

---

### Jerry 06: Import Rescue 🔲 TODO
**Scenario:**
- Jerry created an S3 bucket via AWS CLI "for testing"
- Now it has production data and needs to be in Terraform
- "Can you just add it to our code?"

**Why This Exercise:**
- Realistic brownfield scenario
- Tests import workflow end-to-end
- Both legacy and modern import methods

**Jerry-ctl Command:**
```bash
jerry build --scenario bucket --name-prefix jerry-prod-
```

**What Jerry Creates:**
```bash
# Via AWS SDK/CLI:
aws s3 mb s3://jerry-prod-data-abc123
aws s3api put-bucket-tagging --bucket jerry-prod-data-abc123 \
  --tagging 'TagSet=[{Key=CreatedBy,Value=jerry},{Key=Purpose,Value=testing}]'
```

**Student Must:**
1. Discover what Jerry created
   ```bash
   aws s3 ls | grep jerry
   aws s3api get-bucket-tagging --bucket jerry-prod-data-abc123
   ```
2. Write Terraform config to match
3. Import using BOTH methods:
   - Legacy: `terraform import aws_s3_bucket.jerry_bucket jerry-prod-data-abc123`
   - Modern: `import` block
4. Verify with `terraform plan`

**Bonus Challenge:**
- Jerry also enabled versioning - need to import that too!

**Exam Objectives:** 7a (import), 7b

---

### Jerry 07: Deleted Resource 🔲 TODO
**Scenario:**
- Jerry deleted an S3 bucket that "wasn't being used"
- It's still in Terraform state
- `terraform plan` wants to recreate it

**Jerry-ctl Command:**
```bash
jerry delete --resource aws_s3_bucket.old_logs
```

**What Jerry Does:**
1. Deletes S3 bucket via AWS CLI
2. Leaves Terraform state unchanged

**Student Must:**
1. Run `terraform plan` - see it wants to CREATE
2. Decide:
   - **Option A:** Let Terraform recreate (`terraform apply`)
   - **Option B:** Remove from state (`terraform state rm`)
3. Verify clean state

**Discussion:**
- When to recreate vs remove?
- What if the bucket had data?
- How to prevent accidental deletions?

**Exam Objectives:** 6d, 7b

---

### Jerry 08: Rename Refactor 🔲 TODO
**Scenario:**
- Jerry renamed resources in `.tf` files for "better naming"
- He didn't migrate state
- Terraform wants to destroy and recreate everything

**Setup:**
```hcl
# Original (in state)
resource "aws_s3_bucket" "bucket1" { ... }
resource "aws_s3_bucket" "bucket2" { ... }
```

**Jerry-ctl Command:**
```bash
jerry move --scenario rename
```

**What Jerry Does:**
1. Backs up original `.tf` files
2. Renames resources in `.tf` files:
   ```hcl
   # After Jerry's "improvement"
   resource "aws_s3_bucket" "application_data" { ... }  # was bucket1
   resource "aws_s3_bucket" "user_uploads" { ... }      # was bucket2
   ```
3. Does NOT update state

**Student Must:**
1. Run `terraform plan` - see destroy/create plan
2. Recognize this is a RENAME, not replacement
3. Use `terraform state mv`:
   ```bash
   terraform state mv aws_s3_bucket.bucket1 aws_s3_bucket.application_data
   terraform state mv aws_s3_bucket.bucket2 aws_s3_bucket.user_uploads
   ```
4. OR use `moved` blocks (Terraform 1.1+):
   ```hcl
   moved {
     from = aws_s3_bucket.bucket1
     to   = aws_s3_bucket.application_data
   }
   ```
5. Verify `terraform plan` shows no changes

**Exam Objectives:** 6d, 7b

---

### Jerry 09: Module Refactor 🔲 TODO
**Scenario:**
- Jerry moved resources into a module
- Same problem as Jerry-08, but with module addressing
- More complex state moves required

**Setup:**
```hcl
# Original (flat structure, in state)
resource "aws_s3_bucket" "app" { ... }
resource "aws_s3_bucket_versioning" "app" { ... }
```

**Jerry-ctl Command:**
```bash
jerry move --scenario module
```

**What Jerry Does:**
1. Creates `modules/s3-bucket/` directory with module code
2. Changes root `main.tf` to:
   ```hcl
   module "app_bucket" {
     source = "./modules/s3-bucket"
     name   = "app-data"
   }
   ```
3. Does NOT update state

**Student Must:**
1. Understand module addressing: `module.app_bucket.aws_s3_bucket.this`
2. Move multiple related resources:
   ```bash
   terraform state mv aws_s3_bucket.app module.app_bucket.aws_s3_bucket.this
   terraform state mv aws_s3_bucket_versioning.app module.app_bucket.aws_s3_bucket_versioning.this
   ```
3. OR use `moved` blocks with module paths
4. Verify clean plan

**Exam Objectives:** 5b (module scope), 6d, 7b

---

### Jerry 10: Chaos Day 🔲 TODO
**Scenario:**
- Jerry had a VERY bad day
- Multiple issues combined
- Student doesn't know what's wrong

**Jerry-ctl Command:**
```bash
jerry chaos --difficulty hard --seed 12345
```

**What Jerry Does (Random Combination):**
1. Creates stale lock (maybe)
2. Creates drift on some resources (maybe)
3. Creates unmanaged resources (maybe)
4. Deletes managed resources (maybe)
5. Renames things in code (maybe)

**Student Must:**
1. Investigate: `terraform plan`, `jerry status`
2. Identify ALL issues
3. Fix them in correct order (locks first!)
4. Achieve clean `terraform plan`

**Difficulty Levels:**
| Level | Issues | Types |
|-------|--------|-------|
| easy | 1 | lock OR tags |
| medium | 1-2 | any except module |
| hard | 2-3 | any |
| nightmare | 3 | hardest ones, overlapping |

**Exam Objectives:** All state objectives (6a-6d, 7a-7b)

---

## Jerry-ctl Implementation Priority

Based on exercise needs, implement commands in this order:

### Phase 1 (MVP for Exercises)
1. `jerry lock --backend local` - For Jerry-01
2. `jerry lock --backend s3` - For Jerry-02
3. `jerry drift --scenario tags` - For Jerry-04
4. `jerry validate` - For all exercises

### Phase 2 (Core Scenarios)
5. `jerry drift --scenario config` - For Jerry-05
6. `jerry build --scenario bucket` - For Jerry-06
7. `jerry delete` - For Jerry-07

### Phase 3 (Refactoring)
8. `jerry move --scenario rename` - For Jerry-08
9. `jerry move --scenario module` - For Jerry-09

### Phase 4 (Advanced)
10. `jerry email-recovery` - For Jerry-03 (special case)
11. `jerry chaos` - For Jerry-10

---

## State File Scenarios

Different exercises need different state setups:

| Exercise | Backend | State Location | Pre-existing Infra |
|----------|---------|----------------|-------------------|
| Jerry-01 | Local | Working dir | Yes (Terraform) |
| Jerry-02 | S3 | S3 bucket | Yes (Terraform) |
| Jerry-03 | Local | EMAIL (provided file) | Yes (AWS CLI) |
| Jerry-04 | S3 | S3 bucket | Yes (Terraform) |
| Jerry-05 | S3 | S3 bucket | Yes (Terraform) |
| Jerry-06 | S3 | S3 bucket | MIXED (TF + AWS CLI) |
| Jerry-07 | S3 | S3 bucket | Partial (deleted) |
| Jerry-08 | S3 | S3 bucket | Yes (Terraform) |
| Jerry-09 | S3 | S3 bucket | Yes (Terraform) |
| Jerry-10 | S3 | S3 bucket | Random |

---

## Exam Objective Coverage Matrix

| Objective | Description | Foundation | Jerry |
|-----------|-------------|:----------:|:-----:|
| **6a** | Local backend | Ex-01 | J-01, J-03 |
| **6b** | State locking | Ex-04 | J-01, J-02 |
| **6c** | Remote state (S3) | Ex-01 | J-02, J-04+ |
| **6d** | Resource drift & state mgmt | Ex-02 | J-04, J-05, J-07, J-08, J-09 |
| **7a** | Import resources | Ex-03 | J-06 |
| **7b** | CLI state inspection | Ex-02 | All |

---

## Implementation Checklist

### Immediate (Complete Jerry Track MVP)
- [ ] Create Jerry-02 (remote lock)
- [ ] Create Jerry-05 (config drift)
- [ ] Create Jerry-06 (import rescue)
- [ ] Create Jerry-07 (deleted resource)
- [ ] Verify Jerry-04 setup files exist

### Next (Refactoring Exercises)
- [ ] Create Jerry-08 (rename refactor)
- [ ] Create Jerry-09 (module refactor)

### Then (Special Cases)
- [ ] Create Jerry-03 (email recovery)
- [ ] Create Jerry-10 (chaos day)

### Foundation Track Cleanup
- [ ] Review/complete Ex-01, Ex-02, Ex-03 skeletons
- [ ] Write Ex-04 README

### Jerry-ctl Implementation
- [ ] Phase 1 commands (lock, drift tags, validate)
- [ ] Phase 2 commands (drift config, build, delete)
- [ ] Phase 3 commands (move scenarios)
- [ ] Phase 4 commands (email-recovery, chaos)

---

## File Structure Template

Each Jerry exercise should have:

```
jerry-XX-name/
├── README.md              # Exercise instructions
├── jerry.yaml             # Jerry-ctl configuration
├── setup/
│   ├── main.tf            # Base infrastructure
│   ├── backend.tf         # Backend configuration (if S3)
│   ├── variables.tf       # Variables
│   ├── outputs.tf         # Outputs
│   └── terraform.tfvars   # Default values
└── .validator/
    └── validate.sh        # Calls jerry validate
```

For Jerry-03 (email recovery), also include:
```
└── jerry-backup.tfstate   # The "emailed" state file
```

---

## Notes

### Why Two Tracks?

**Foundation Track:** Structured learning, step-by-step instructions, teaches concepts in isolation.

**Jerry Track:** Applied learning, realistic scenarios, teaches problem-solving and investigation skills.

Students who do both will:
1. Understand the concepts (Foundation)
2. Know how to apply them under pressure (Jerry)
3. Be prepared for real-world incidents

### Jerry-03 is Unique

The "email recovery" exercise is special because:
- State file is PROVIDED (not created by jerry-ctl)
- Tests understanding of state file structure
- Shows why remote backends matter
- Most realistic "disaster" scenario

### Chaos Day is the Final Exam

Jerry-10 combines everything. Students who can solve random chaos are ready for production Terraform work.
