# Challenge: Pokedex Infrastructure - Grading Rubric

**Total Points: 100** (110 with bonus)

---

## 1. Pokemon Team Variable (10 points)

### Variable Definition (5 points)

- **5 points**: Variable correctly defined as `list(object({ name = string, id = number }))`
- **3 points**: Variable defined but type is incorrect (e.g., missing object structure)
- **0 points**: Variable missing or completely incorrect

### Validations (5 points)

- **2 points**: Team size validation (1-6 Pokemon)
- **2 points**: Pokemon ID validation (1-1010)
- **1 point**: Pokemon name validation (lowercase, no spaces)
- **0 points**: No validation blocks present

**Deductions:**
- -1 point: Validation error messages are unclear or missing
- -1 point: Validation conditions are logically incorrect

---

## 2. Fetch Pokemon Data (10 points)

### Data Source Configuration (6 points)

- **6 points**: Uses `data "http"` with `for_each`, fetches all Pokemon correctly
- **4 points**: Uses `data "http"` but with `count` instead of `for_each`
- **2 points**: Attempts to fetch data but has errors
- **0 points**: Does not fetch from API

### Data Parsing (4 points)

- **4 points**: Correctly parses JSON with `jsondecode()` and extracts all required fields (name, id, types, hp, sprite)
- **3 points**: Parses JSON but missing 1-2 fields
- **2 points**: Parses JSON but missing 3+ fields
- **0 points**: Does not parse JSON or extracts no fields

**Deductions:**
- -1 point: Hardcodes values instead of extracting from API
- -1 point: Does not handle API response structure correctly

---

## 3. Create Infrastructure with for_each (15 points)

### Resource Creation (8 points)

- **8 points**: Creates instances/containers using `for_each` with Pokemon names as keys
- **5 points**: Creates instances/containers using `count` (wrong approach but working)
- **3 points**: Creates instances/containers but with errors
- **0 points**: Does not create instances/containers

### Resource Addressing (4 points)

- **4 points**: Resources properly keyed by Pokemon name (stable addressing)
- **2 points**: Resources created but not properly addressable
- **0 points**: Resources not addressable or addressing broken

### Instance/Container Configuration (3 points)

- **3 points**: Proper instance type/image, correct configuration
- **2 points**: Working but suboptimal configuration
- **0 points**: Configuration missing or incorrect

**Deductions:**
- -2 points: Used `count` instead of `for_each` (major requirement violation)
- -1 point: Resources not named properly

---

## 4. Tag/Label Resources (10 points)

### Required Tags/Labels (7 points)

- **1 point each**: Pokemon name, ID, types, HP, trainer name, environment, managed-by
- Must have at least 5/7 for partial credit

### Tag/Label Format (3 points)

- **3 points**: All values properly formatted (strings where needed, proper separators)
- **2 points**: Minor formatting issues (e.g., types not comma-separated)
- **1 point**: Major formatting issues
- **0 points**: Tags/labels present but unusable

**Deductions:**
- -1 point: Missing required tags/labels
- -1 point: Incorrect values in tags/labels

---

## 5. Dynamic Security Configuration (20 points)

### Dynamic Block Implementation (10 points)

- **10 points**: Correctly uses `dynamic` blocks with `for_each` over unique types
- **7 points**: Uses dynamic blocks but not iterating over types
- **5 points**: Attempts dynamic blocks but has errors
- **0 points**: Does not use dynamic blocks (hardcoded instead)

### Type-Port Mapping (5 points)

- **5 points**: Uses `lookup()` with proper type-to-port mapping and default fallback
- **3 points**: Maps types to ports but without `lookup()` or no fallback
- **1 point**: Attempts mapping but broken
- **0 points**: No type-port mapping

### Configuration Correctness (5 points)

**EC2:**
- **5 points**: Security group created, rules correct, attached to instances
- **3 points**: Security group created but not attached or rules incorrect
- **0 points**: No security group or completely broken

**Docker:**
- **5 points**: Dynamic env vars and labels created correctly for each type
- **3 points**: Dynamic env vars created but missing labels or vice versa
- **0 points**: No dynamic configuration

**Deductions:**
- -2 points: Not using unique types (duplicates in rules)
- -1 point: Incorrect port numbers or missing types

---

## 6. Custom Conditions (10 points)

### Precondition on Resources (5 points)

- **5 points**: Precondition checks HP > 30, inside `lifecycle` block, proper error message
- **3 points**: Precondition present but error message unclear or condition wrong
- **1 point**: Attempts precondition but not in `lifecycle` or completely broken
- **0 points**: No precondition present

### Variable Validations (5 points)

- **5 points**: All three validations present (team size, IDs, names) and working
- **3 points**: 2/3 validations present and working
- **2 points**: 1/3 validations present and working
- **0 points**: No variable validations

**Deductions:**
- -1 point: Validation conditions are too lenient or incorrect
- -1 point: Error messages are not helpful

---

## 7. Comprehensive Outputs (15 points)

### Required Outputs (12 points)

- **3 points**: `team_roster` - Map with all Pokemon details
- **3 points**: `pokedex_report` - Formatted multi-line string
- **3 points**: `type_coverage` - Map of types to Pokemon
- **3 points**: `team_stats` - Object with total HP, unique types, strongest Pokemon

**Scoring per output:**
- Full points: Output present, correct format, all required fields
- Half points: Output present but missing fields or incorrect format
- 0 points: Output missing

### Output Quality (3 points)

- **3 points**: Outputs are well-formatted, readable, and informative
- **2 points**: Outputs work but formatting could be better
- **1 point**: Outputs barely readable
- **0 points**: Outputs are unreadable or broken

**Deductions:**
- -1 point: Missing output descriptions
- -1 point: Outputs contain hardcoded values instead of computed values

---

## 8. Code Quality (10 points)

### Code Organization (3 points)

- **3 points**: Code well-organized, proper separation of concerns, logical structure
- **2 points**: Code works but could be better organized
- **1 point**: Code disorganized and hard to follow
- **0 points**: Code is a mess

### Code Style (3 points)

- **3 points**: Code formatted (`terraform fmt`), consistent style, good naming
- **2 points**: Minor style issues
- **1 point**: Major style issues
- **0 points**: Code unformatted and inconsistent

### Documentation (2 points)

- **2 points**: Good comments explaining complex logic
- **1 point**: Some comments present
- **0 points**: No comments

### Validation (2 points)

- **2 points**: `terraform validate` passes, no errors
- **1 point**: Validates with warnings
- **0 points**: Does not validate

**Deductions:**
- -1 point: Overly complex code (over-engineering)
- -1 point: Duplicate code that could be DRY'd up
- -1 point: Poor variable/resource naming

---

## 9. Stretch Goals (Bonus - 10 points)

Pick any 2 for full bonus:

### S3 Bucket for Sprites (5 points)

- **5 points**: S3 bucket created, sprites would be stored correctly
- **3 points**: S3 bucket created but implementation incomplete
- **0 points**: Not implemented

### Trainer Card with templatefile() (5 points)

- **5 points**: HTML template created, `templatefile()` used correctly, outputs nice card
- **3 points**: Template created but issues with implementation
- **0 points**: Not implemented

### Multiple Environments (5 points)

- **5 points**: Supports gym-leader vs trainer with different configs, uses `locals` or `var` to switch
- **3 points**: Attempts multiple environments but incomplete
- **0 points**: Not implemented

### Type Effectiveness (5 points)

- **5 points**: Fetches type data from API, shows strengths/weaknesses in outputs
- **3 points**: Attempts but incomplete
- **0 points**: Not implemented

### Auto-scaling Groups (EC2 only) (5 points)

- **5 points**: Uses ASG instead of instances, scaling policies configured
- **3 points**: ASG created but not fully configured
- **0 points**: Not implemented

**Note:** Maximum 10 bonus points total (choose any 2)

---

## Grading Scale

| Points | Grade | Assessment |
|--------|-------|------------|
| 90-110 | A+ | Excellent! Mastery of all concepts |
| 80-89 | A | Great work! Strong understanding |
| 70-79 | B | Good! Most concepts understood |
| 60-69 | C | Passing, but needs improvement |
| 50-59 | D | Significant gaps in understanding |
| 0-49 | F | Does not meet requirements |

---

## Common Mistakes and Penalties

### Critical Errors (Major deductions)

- **-10 points**: Used `count` instead of `for_each` for resources
- **-5 points**: Did not fetch data from API (hardcoded instead)
- **-5 points**: No dynamic blocks used (hardcoded security config)
- **-5 points**: No validation or preconditions

### Minor Errors (Small deductions)

- **-2 points**: Missing required tags/labels
- **-2 points**: Poor output formatting
- **-1 point**: No comments explaining complex logic
- **-1 point**: Inconsistent naming conventions

### Automatic Failures (0 points)

- Code does not run (`terraform validate` fails with errors)
- Plagiarism detected (copied solution without understanding)
- Did not attempt the challenge (empty or minimal starter code)

---

## Grading Process

1. **Clone/Download** student submission
2. **Run Validation**: `terraform validate`
   - If fails: Check for syntax errors, provide feedback
3. **Review Code**: Check against rubric requirements
4. **Run Plan**: `terraform plan` (optional, if AWS/Docker available)
5. **Check Outputs**: Verify output structure and content
6. **Assign Points**: Use rubric sections above
7. **Provide Feedback**: Specific comments on what was good and what needs improvement

---

## Feedback Template

```
POKEDEX INFRASTRUCTURE CHALLENGE - FEEDBACK

Total Score: ____ / 100

=== STRENGTHS ===
-
-
-

=== AREAS FOR IMPROVEMENT ===
-
-
-

=== DETAILED BREAKDOWN ===
1. Pokemon Team Variable: ____ / 10
   Comments:

2. Fetch Pokemon Data: ____ / 10
   Comments:

3. Infrastructure with for_each: ____ / 15
   Comments:

4. Tag/Label Resources: ____ / 10
   Comments:

5. Dynamic Security Config: ____ / 20
   Comments:

6. Custom Conditions: ____ / 10
   Comments:

7. Comprehensive Outputs: ____ / 15
   Comments:

8. Code Quality: ____ / 10
   Comments:

9. Stretch Goals (Bonus): ____ / 10
   Comments:

=== FINAL GRADE: _____ ===

Great job completing the challenge! Your Pokedex infrastructure is ready to battle!
```

---

## Self-Assessment

Before submitting, use this checklist:

- [ ] All validations pass
- [ ] `terraform validate` succeeds
- [ ] `terraform fmt` applied
- [ ] All required outputs present
- [ ] Used `for_each` (NOT `count`)
- [ ] Dynamic blocks implemented
- [ ] Preconditions added
- [ ] Code is well-commented
- [ ] Tested with at least 3 different Pokemon
- [ ] README or comments explain your approach

---

**Good luck, and may your Pokemon team be the strongest!** 🎮⚡
