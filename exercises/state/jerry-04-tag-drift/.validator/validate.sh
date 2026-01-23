#!/bin/bash
# Validation script for Jerry 04: Tag Drift
#
# Usage: ./validate.sh [student-work-dir]
#
# Exit codes:
#   0 - Success (drift resolved)
#   1 - Failure (drift still exists or other error)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory to validate
WORK_DIR="${1:-.}"

echo "🔍 Validating Jerry 04: Tag Drift"
echo "   Directory: $WORK_DIR"
echo ""

# Change to work directory
cd "$WORK_DIR"

# Check 1: Terraform is initialized
echo -n "Checking Terraform initialized... "
if [ ! -d ".terraform" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   Run 'terraform init' first"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check 2: Terraform validates
echo -n "Checking configuration valid... "
if ! terraform validate -no-color > /dev/null 2>&1; then
    echo -e "${RED}FAILED${NC}"
    echo "   Configuration has errors. Run 'terraform validate' for details."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check 3: Terraform plan shows no changes
echo -n "Checking for drift (terraform plan)... "
PLAN_OUTPUT=$(terraform plan -no-color -detailed-exitcode 2>&1) || PLAN_EXIT=$?

# Exit code 0 = no changes, 1 = error, 2 = changes pending
if [ "${PLAN_EXIT:-0}" -eq 2 ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "   Drift still exists! Terraform wants to make changes:"
    echo ""
    echo "$PLAN_OUTPUT" | grep -A 50 "Terraform will perform" | head -30
    echo ""
    echo "   Fix the drift by either:"
    echo "   - Option A: Run 'terraform apply' to revert to Terraform's version"
    echo "   - Option B: Update main.tf to match current AWS state"
    exit 1
elif [ "${PLAN_EXIT:-0}" -eq 1 ]; then
    echo -e "${RED}ERROR${NC}"
    echo "   Terraform plan failed:"
    echo "$PLAN_OUTPUT"
    exit 1
fi
echo -e "${GREEN}OK${NC} - No drift detected"

# Check 4: State file exists and has resources
echo -n "Checking state has resources... "
RESOURCE_COUNT=$(terraform state list 2>/dev/null | wc -l)
if [ "$RESOURCE_COUNT" -lt 1 ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   No resources in state. Did you run 'terraform apply'?"
    exit 1
fi
echo -e "${GREEN}OK${NC} - $RESOURCE_COUNT resources in state"

# All checks passed
echo ""
echo -e "${GREEN}✅ Validation Passed!${NC}"
echo ""
echo "   You successfully resolved the tag drift."
echo ""

# Calculate score (basic version - jerry-ctl will do this better)
SCORE=100
HINTS_FILE=".jerry/manifest.json"
if [ -f "$HINTS_FILE" ]; then
    HINTS_USED=$(grep -o '"hints_used":[0-9]*' "$HINTS_FILE" | grep -o '[0-9]*' || echo "0")
    HINT_PENALTY=$((HINTS_USED * 5))
    SCORE=$((SCORE - HINT_PENALTY))
    echo "   Hints used: $HINTS_USED (-$HINT_PENALTY points)"
fi

echo "   Score: $SCORE/100"
echo ""

# Bonus: Ask about their approach
echo -e "${YELLOW}📝 Reflection:${NC}"
echo "   Which approach did you use?"
echo "   A) terraform apply (revert to Terraform)"
echo "   B) Updated main.tf (accept Jerry's changes)"
echo ""
echo "   Think about: When would each approach be appropriate?"

exit 0
