#!/bin/bash
# Validation script for Jerry 02: Remote Lock
#
# Usage: ./validate.sh [student-work-dir]
#
# Exit codes:
#   0 - Success (lock removed, terraform works)
#   1 - Failure (lock still exists or other error)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory to validate
WORK_DIR="${1:-.}"

echo "🔍 Validating Jerry 02: Remote Lock"
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

# Get state bucket from backend config
echo -n "Getting backend configuration... "
STATE_BUCKET=$(grep -A 20 'backend "s3"' backend.tf terraform.tfvars 2>/dev/null | grep -E '(bucket|state_bucket)' | head -1 | awk '{print $3}' | tr -d '",')

if [ -z "$STATE_BUCKET" ]; then
    # Try from terraform.tfvars
    STATE_BUCKET=$(grep '^state_bucket' terraform.tfvars 2>/dev/null | awk '{print $3}' | tr -d '"')
fi

if [ -z "$STATE_BUCKET" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   Could not determine state bucket name"
    exit 1
fi
echo -e "${GREEN}OK${NC}"
echo "   State bucket: $STATE_BUCKET"

# Check 2: Lock file should NOT exist in S3
STATE_KEY="gym/state/jerry-02-remote-lock/terraform.tfstate"
LOCK_KEY="${STATE_KEY}.tflock"
S3_LOCK_PATH="s3://${STATE_BUCKET}/${LOCK_KEY}"

echo -n "Checking lock file removed from S3... "
if aws s3api head-object --bucket "$STATE_BUCKET" --key "$LOCK_KEY" &>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "   Lock file still exists at: $S3_LOCK_PATH"
    echo ""
    echo "   Remove it using one of these methods:"
    echo ""
    echo "   Method A (Recommended):"
    echo "     1. Get lock ID from error message when running 'terraform plan'"
    echo "     2. terraform force-unlock <LOCK_ID>"
    echo ""
    echo "   Method B (Emergency):"
    echo "     aws s3 rm $S3_LOCK_PATH"
    echo ""
    exit 1
fi
echo -e "${GREEN}OK${NC} - Lock removed"

# Check 3: Terraform configuration is valid
echo -n "Checking configuration valid... "
if ! terraform validate -no-color > /dev/null 2>&1; then
    echo -e "${RED}FAILED${NC}"
    echo "   Configuration has errors. Run 'terraform validate' for details."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check 4: Terraform plan succeeds (no lock error)
echo -n "Checking terraform plan works... "
PLAN_OUTPUT=$(terraform plan -no-color -detailed-exitcode 2>&1) || PLAN_EXIT=$?

# Exit code 0 = no changes, 1 = error, 2 = changes pending
if [ "${PLAN_EXIT:-0}" -eq 1 ]; then
    # Check if it's a lock error
    if echo "$PLAN_OUTPUT" | grep -q "Error acquiring the state lock"; then
        echo -e "${RED}FAILED${NC}"
        echo ""
        echo "   Still getting lock errors:"
        echo ""
        echo "$PLAN_OUTPUT" | grep -A 20 "Error acquiring"
        echo ""
        echo "   The lock file may have been recreated or there's a different issue."
        exit 1
    else
        echo -e "${RED}ERROR${NC}"
        echo "   Terraform plan failed (not a lock error):"
        echo ""
        echo "$PLAN_OUTPUT"
        exit 1
    fi
fi
echo -e "${GREEN}OK${NC}"

# Check 5: State file exists and has resources
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
echo "   You successfully unlocked the remote state!"
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
echo "   Which method did you use?"
echo "   A) terraform force-unlock <LOCK_ID>"
echo "   B) aws s3 rm (manual deletion)"
echo ""
echo "   Think about:"
echo "   - When is each method appropriate?"
echo "   - What are the risks of manual deletion?"
echo "   - How can CI/CD pipelines prevent stale locks?"
echo ""

# Check for lock in manifest and show how long it took
if [ -f "$HINTS_FILE" ]; then
    START_TIME=$(grep '"start_time"' "$HINTS_FILE" | awk -F'"' '{print $4}')
    if [ -n "$START_TIME" ]; then
        END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "   Started: $START_TIME"
        echo "   Completed: $END_TIME"
    fi
fi

exit 0
