#!/bin/bash
# Validation script for Jerry 01: Stale Lock
#
# Usage: ./validate.sh [student-work-dir]
#
# Exit codes:
#   0 - Success (lock removed)
#   1 - Failure (lock still exists or other error)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory to validate
WORK_DIR="${1:-.}"

echo "🔍 Validating Jerry 01: Stale Lock"
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

# Check 2: Lock file does NOT exist
echo -n "Checking lock file removed... "
if [ -f ".terraform.tfstate.lock.info" ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "   Lock file still exists!"
    echo ""
    echo "   Current lock details:"
    cat .terraform.tfstate.lock.info | grep -v '^{' | grep -v '^}' | sed 's/^/   /'
    echo ""
    echo "   To unlock:"
    LOCK_ID=$(grep '"ID"' .terraform.tfstate.lock.info | cut -d'"' -f4)
    echo "   terraform force-unlock $LOCK_ID"
    echo ""
    exit 1
fi
echo -e "${GREEN}OK${NC} - Lock file removed"

# Check 3: Terraform plan works
echo -n "Checking terraform plan works... "
PLAN_OUTPUT=$(terraform plan -no-color 2>&1) || PLAN_EXIT=$?

if [ "${PLAN_EXIT:-0}" -ne 0 ]; then
    # Check if it's a lock error
    if echo "$PLAN_OUTPUT" | grep -q "Error acquiring the state lock"; then
        echo -e "${RED}FAILED${NC}"
        echo ""
        echo "   State is still locked!"
        echo ""
        echo "$PLAN_OUTPUT" | grep -A 10 "Error acquiring"
        echo ""
        exit 1
    else
        echo -e "${YELLOW}WARNING${NC}"
        echo "   Plan failed for a different reason:"
        echo "$PLAN_OUTPUT" | head -20
        echo ""
        echo "   But the lock is removed, so this exercise is complete."
    fi
else
    echo -e "${GREEN}OK${NC} - Plan executed successfully"
fi

# Check 4: Verify no other lock indicators
echo -n "Checking for other lock indicators... "
if ls .terraform.tfstate.lock* 2>/dev/null | grep -q .; then
    echo -e "${YELLOW}WARNING${NC}"
    echo "   Found unexpected lock files:"
    ls .terraform.tfstate.lock*
else
    echo -e "${GREEN}OK${NC}"
fi

# All checks passed
echo ""
echo -e "${GREEN}✅ Validation Passed!${NC}"
echo ""
echo "   You successfully removed the stale lock."
echo "   Terraform operations can now proceed normally."
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

# Reflection questions
echo -e "${YELLOW}📝 Reflection:${NC}"
echo "   1. Why was it safe to force-unlock in this scenario?"
echo "   2. When would force-unlock be dangerous?"
echo "   3. How can you prevent stale locks in a team environment?"
echo ""

exit 0
