#!/bin/bash
# Validation script for Jerry 08: Rename Refactor
#
# Usage: ./validate.sh [student-work-dir]
#
# Exit codes:
#   0 - Success (rename fixed, no destroy/create)
#   1 - Failure (still shows destroy/create or other error)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get the directory to validate
WORK_DIR="${1:-.}"

echo "🔍 Validating Jerry 08: Rename Refactor"
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

# Check 3: Verify renamed resources exist in code
echo -n "Checking renamed resources in code... "
RENAMED_COUNT=0
if grep -q "aws_s3_bucket.application_data" main.tf 2>/dev/null; then
    ((RENAMED_COUNT++))
fi
if grep -q "aws_s3_bucket.user_uploads" main.tf 2>/dev/null; then
    ((RENAMED_COUNT++))
fi

if [ "$RENAMED_COUNT" -lt 2 ]; then
    echo -e "${YELLOW}WARNING${NC}"
    echo "   Renamed resources not found in main.tf"
    echo "   Expected: aws_s3_bucket.application_data and aws_s3_bucket.user_uploads"
    echo "   Did Jerry's simulation run?"
else
    echo -e "${GREEN}OK${NC}"
fi

# Check 4: Verify state addresses match code
echo -n "Checking state addresses... "
STATE_LIST=$(terraform state list 2>/dev/null)

HAS_APP_DATA=$(echo "$STATE_LIST" | grep -c "aws_s3_bucket.application_data" || true)
HAS_UPLOADS=$(echo "$STATE_LIST" | grep -c "aws_s3_bucket.user_uploads" || true)
HAS_OLD_BUCKET1=$(echo "$STATE_LIST" | grep -c "aws_s3_bucket.bucket1" || true)
HAS_OLD_BUCKET2=$(echo "$STATE_LIST" | grep -c "aws_s3_bucket.bucket2" || true)

if [ "$HAS_APP_DATA" -lt 1 ] || [ "$HAS_UPLOADS" -lt 1 ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   State doesn't have renamed resources:"
    echo "   - aws_s3_bucket.application_data: $([ "$HAS_APP_DATA" -gt 0 ] && echo "✓" || echo "✗")"
    echo "   - aws_s3_bucket.user_uploads: $([ "$HAS_UPLOADS" -gt 0 ] && echo "✓" || echo "✗")"
    echo ""
    echo "   Use 'terraform state mv' or 'moved' blocks to migrate state."
    exit 1
fi

if [ "$HAS_OLD_BUCKET1" -gt 0 ] || [ "$HAS_OLD_BUCKET2" -gt 0 ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   Old bucket addresses still in state:"
    echo "   - aws_s3_bucket.bucket1: $([ "$HAS_OLD_BUCKET1" -gt 0 ] && echo "still present ✗" || echo "removed ✓")"
    echo "   - aws_s3_bucket.bucket2: $([ "$HAS_OLD_BUCKET2" -gt 0 ] && echo "still present ✗" || echo "removed ✓")"
    echo ""
    echo "   Complete the state migration for all resources."
    exit 1
fi

echo -e "${GREEN}OK${NC} - State addresses updated"

# Check 5: Terraform plan shows no changes (CRITICAL!)
echo -n "Checking for destroy/create (terraform plan)... "
PLAN_OUTPUT=$(terraform plan -no-color -detailed-exitcode 2>&1) || PLAN_EXIT=$?

# Exit code 0 = no changes, 1 = error, 2 = changes pending
if [ "${PLAN_EXIT:-0}" -eq 2 ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""

    # Check if it's a destroy/create scenario
    if echo "$PLAN_OUTPUT" | grep -q "will be destroyed"; then
        echo -e "   ${RED}DANGER!${NC} Terraform wants to DESTROY resources!"
        echo ""
        echo "$PLAN_OUTPUT" | grep -A 3 "will be destroyed" | head -20
        echo ""
        echo "   This means the state migration is incomplete or incorrect."
        echo "   DO NOT RUN 'terraform apply' - you would lose data!"
        echo ""
        echo "   Fix by:"
        echo "   1. Check 'terraform state list' - do addresses match main.tf?"
        echo "   2. Use 'terraform state mv' to migrate missing resources"
        echo "   3. Or add 'moved' blocks for remaining resources"
    else
        echo "   Plan shows changes (not destroy/create):"
        echo ""
        echo "$PLAN_OUTPUT" | grep -A 30 "Terraform will perform" | head -25
    fi
    exit 1
elif [ "${PLAN_EXIT:-0}" -eq 1 ]; then
    echo -e "${RED}ERROR${NC}"
    echo "   Terraform plan failed:"
    echo "$PLAN_OUTPUT"
    exit 1
fi
echo -e "${GREEN}OK${NC} - No changes (no destroy/create)"

# Check 6: Verify buckets still exist in AWS
echo -n "Checking buckets exist in AWS... "
BUCKET1_NAME=$(terraform output -raw bucket1_name 2>/dev/null || echo "")
BUCKET2_NAME=$(terraform output -raw bucket2_name 2>/dev/null || echo "")

if [ -z "$BUCKET1_NAME" ] || [ -z "$BUCKET2_NAME" ]; then
    echo -e "${YELLOW}SKIP${NC} (outputs not available)"
else
    BUCKETS_OK=true
    if ! aws s3api head-bucket --bucket "$BUCKET1_NAME" 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "   Bucket 1 ($BUCKET1_NAME) does not exist!"
        echo "   It may have been destroyed. Check AWS Console."
        BUCKETS_OK=false
    fi
    if ! aws s3api head-bucket --bucket "$BUCKET2_NAME" 2>/dev/null; then
        echo -e "${RED}FAILED${NC}"
        echo "   Bucket 2 ($BUCKET2_NAME) does not exist!"
        echo "   It may have been destroyed. Check AWS Console."
        BUCKETS_OK=false
    fi

    if [ "$BUCKETS_OK" = true ]; then
        echo -e "${GREEN}OK${NC} - Both buckets exist"
    else
        exit 1
    fi
fi

# Check 7: State file has expected resource count
echo -n "Checking state has resources... "
RESOURCE_COUNT=$(echo "$STATE_LIST" | wc -l)
EXPECTED_MIN=6  # 2 buckets + 2 random_id + 2 versioning (minimum)

if [ "$RESOURCE_COUNT" -lt "$EXPECTED_MIN" ]; then
    echo -e "${YELLOW}WARNING${NC}"
    echo "   Expected at least $EXPECTED_MIN resources, found $RESOURCE_COUNT"
else
    echo -e "${GREEN}OK${NC} - $RESOURCE_COUNT resources in state"
fi

# All checks passed
echo ""
echo -e "${GREEN}✅ Validation Passed!${NC}"
echo ""
echo "   You successfully fixed the rename refactor without destroying resources!"
echo ""

# Detect which method was used
echo -e "${CYAN}📊 Solution Analysis:${NC}"
if grep -q "^moved {" main.tf 2>/dev/null; then
    echo "   Method: moved blocks (declarative) ⭐"
    echo "   +10 bonus points for using modern approach!"
    BONUS=10
else
    echo "   Method: terraform state mv (imperative)"
    echo "   Works great! Consider 'moved' blocks for team environments."
    BONUS=0
fi

# Calculate score (basic version - jerry-ctl will do this better)
SCORE=100
HINTS_FILE=".jerry/manifest.json"
if [ -f "$HINTS_FILE" ]; then
    HINTS_USED=$(grep -o '"hints_used":[0-9]*' "$HINTS_FILE" | grep -o '[0-9]*' || echo "0")
    HINT_PENALTY=$((HINTS_USED * 5))
    SCORE=$((SCORE - HINT_PENALTY + BONUS))
    echo "   Hints used: $HINTS_USED (-$HINT_PENALTY points)"
fi

echo "   Score: $SCORE/100"
echo ""

# Reflection questions
echo -e "${YELLOW}📝 Reflection:${NC}"
echo "   1. Why did Terraform want to destroy/create?"
echo "   2. When would you use 'state mv' vs 'moved' blocks?"
echo "   3. What would happen if you ran 'terraform apply' before fixing state?"
echo ""

exit 0
