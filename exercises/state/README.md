# State Management Exercise Series

Master Terraform state management through two complementary tracks:
- **Foundation Track** - Learn state concepts step-by-step
- **Jerry Track** - Apply your skills by fixing chaos 🔧

## 🎯 Two Ways to Learn

### Foundation Track (Traditional)
Step-by-step exercises that teach state concepts. Follow instructions to build skills.

| Exercise | Focus | Time | Difficulty |
|----------|-------|------|------------|
| [01: Remote Backend](exercise-01-remote-backend/) | S3 backend setup | 25 min | ⭐ |
| [02: State Commands](exercise-02-state-commands/) | list, show, mv, rm | 25 min | ⭐⭐ |
| [03: Import Resources](exercise-03-import-resources/) | terraform import | 25 min | ⭐⭐ |
| [04: State Locking](exercise-04-state-locking/) | Locks & unlocking | 25 min | ⭐⭐⭐ |
| [Challenge: State Surgery](challenge-state-surgery/) | Advanced operations | 90 min | ⭐⭐⭐ |

### Jerry Track (Chaos Engineering) 🔧
Fix realistic problems caused by "Jerry" - your chaotic teammate. Requires `jerry` CLI.

| Exercise | What Jerry Did | Time | Difficulty |
|----------|---------------|------|------------|
| [Jerry 01: Stale Lock](jerry-01-stale-lock/) | Abandoned an apply | 15 min | ⭐ |
| [Jerry 02: Remote Lock](jerry-02-remote-lock/) | Crashed CI pipeline | 20 min | ⭐ |
| [Jerry 03: Email Recovery](jerry-03-email-recovery/) | Emailed his state file | 25 min | ⭐⭐ |
| [Jerry 04: Tag Drift](jerry-04-tag-drift/) | Console tag changes | 20 min | ⭐⭐ |
| [Jerry 05: Config Drift](jerry-05-config-drift/) | Console config changes | 25 min | ⭐⭐ |
| [Jerry 06: Built a Bucket](jerry-06-import-rescue/) | Manual resource creation | 30 min | ⭐⭐ |
| [Jerry 07: Deleted Something](jerry-07-deleted-resource/) | "Cleaned up" resources | 20 min | ⭐⭐ |
| [Jerry 08: Refactored Code](jerry-08-rename-refactor/) | Renamed without migrate | 25 min | ⭐⭐⭐ |
| [Jerry 09: Module Move](jerry-09-module-refactor/) | Moved to modules | 30 min | ⭐⭐⭐ |
| [Jerry 10: Chaos Day](jerry-10-chaos/) | All of the above | 45 min | ⭐⭐⭐ |

---

## 📖 Recommended Learning Path

### New to State Management?
```
Foundation 01 → Foundation 02 → Foundation 03 → Foundation 04
     ↓
Jerry 01 → Jerry 04 → Jerry 06 → Jerry 07
     ↓
Foundation Challenge OR Jerry 10
```

### Quick Review?
```
Jerry 01 (locks) → Jerry 06 (import) → Jerry 08 (rename) → Jerry 10 (chaos)
```

### Exam Prep?
```
All Foundation exercises → Jerry 10 (Chaos Day)
```

---

## 🔧 Jerry Track Setup

The Jerry exercises use a special CLI tool to create realistic problems:

```bash
# Install jerry-ctl (included in devcontainer)
jerry --version

# Jerry creates chaos, you fix it
jerry lock    # Creates a stale state lock
jerry drift   # Modifies resources outside Terraform
jerry build   # Creates resources needing import
jerry chaos   # Random combination
```

See [jerry-ctl documentation](https://github.com/shart-cloud/jerry-ctl) for details.

---

## 📊 Exam Objective Coverage

| Objective | Foundation | Jerry |
|-----------|------------|-------|
| **6a** Local backend | Ex 01 | J-01, J-03 |
| **6b** State locking | Ex 04 | J-01, J-02 |
| **6c** Remote state | Ex 01 | J-02, J-04+ |
| **6d** Resource drift | Ex 02 | J-04, J-05, J-07, J-08 |
| **7a** Import resources | Ex 03 | J-06 |
| **7b** CLI inspection | Ex 02 | J-01, J-07, J-08 |

---

## 💰 Cost

**Total series cost: $0.00**

All exercises use S3 buckets with no data, which are free.

---

## 🎭 Who is Jerry?

Jerry is your well-meaning but chaotic teammate who:
- Runs `terraform apply` and goes to lunch 🍕
- Makes "quick fixes" in the AWS Console ☁️
- Creates resources "just for testing" 🪣
- Deletes things that "weren't being used" 💀
- Refactors code without migrating state 📦

*Every team has a Jerry. Practice fixing Jerry's messes here, not in production!*

---

**Ready to learn?** Start with [Foundation 01: Remote Backend](exercise-01-remote-backend/)

**Ready for chaos?** Start with [Jerry 01: Stale Lock](jerry-01-stale-lock/)
