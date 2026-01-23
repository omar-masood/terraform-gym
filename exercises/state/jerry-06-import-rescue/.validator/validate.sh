#!/bin/bash
# Validation script for Jerry 06: Import Rescue
#
# Usage: ./validate.sh [student-work-dir]
#
# Exit codes:
#   0 - Success (bucket imported correctly)
#   1 - Failure (bucket not imported or has drift)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get the directory to validate
WORK_DIR="${1:-.}"

echo "🔍 Validating Jerry 06: Import Rescue"
echo "   Directory: $WORK_DIR"
echo ""

# Change to work directory
cd "$WORK_DIR"

# Check 0: Jerry's bucket exists
echo -n "Checking Jerry's bucket exists... "
if [ ! -f ".jerry/bucket-name.txt" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   No bucket created yet. Run '../.validator/simulate-jerry.sh' first."
    exit 1
fi
BUCKET_NAME=$(cat .jerry/bucket-name.txt)
echo -e "${GREEN}OK${NC} - $BUCKET_NAME"

# Verify bucket exists in AWS
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "   Bucket doesn't exist in AWS anymore. Did you delete it?"
    echo "   Run '../.validator/simulate-jerry.sh' to recreate."
    exit 1
fi

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

# Check 3: State file exists
echo -n "Checking state file exists... "
if [ ! -f "terraform.tfstate" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   No state file found. Have you imported the bucket yet?"
    echo ""
    echo "   Try: terraform import aws_s3_bucket.jerry_bucket $BUCKET_NAME"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check 4: Bucket is in state
echo -n "Checking bucket in state... "
if ! terraform state list 2>/dev/null | grep -q "aws_s3_bucket.jerry_bucket"; then
    echo -e "${RED}FAILED${NC}"
    echo "   Bucket not found in state!"
    echo ""
    echo "   Import the bucket with:"
    echo "   terraform import aws_s3_bucket.jerry_bucket $BUCKET_NAME"
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check 5: Versioning is in state
echo -n "Checking versioning in state... "
if ! terraform state list 2>/dev/null | grep -q "aws_s3_bucket_versioning.jerry_bucket"; then
    echo -e "${YELLOW}WARNING${NC}"
    echo ""
    echo "   Versioning resource not imported!"
    echo "   Jerry enabled versioning, so you need to import it too:"
    echo ""
    echo "   terraform import aws_s3_bucket_versioning.jerry_bucket $BUCKET_NAME"
    echo ""
    echo "   Without this, 'terraform plan' will want to CREATE the versioning resource."
    echo ""
    # Don't exit - let's see if plan is clean
else
    echo -e "${GREEN}OK${NC}"
fi

# Check 6: Terraform plan shows no changes
echo -n "Checking for drift (terraform plan)... "
PLAN_OUTPUT=$(terraform plan -no-color -detailed-exitcode 2>&1) || PLAN_EXIT=$?

# Exit code 0 = no changes, 1 = error, 2 = changes pending
if [ "${PLAN_EXIT:-0}" -eq 2 ]; then
    echo -e "${RED}FAILED${NC}"
    echo ""
    echo "   Drift detected! Terraform wants to make changes:"
    echo ""
    echo "$PLAN_OUTPUT" | grep -A 100 "Terraform will perform" | head -50
    echo ""
    echo -e "${CYAN}Common issues:${NC}"
    echo ""
    echo "   1. Tags don't match:"
    echo "      Your config must match Jerry's tags exactly:"
    echo "        CreatedBy: jerry"
    echo "        Purpose: testing"
    echo "        Department: engineering"
    echo ""
    echo "   2. Versioning not imported:"
    echo "      Import it with:"
    echo "      terraform import aws_s3_bucket_versioning.jerry_bucket $BUCKET_NAME"
    echo ""
    echo "   3. Bucket name mismatch:"
    echo "      Use the exact bucket name: $BUCKET_NAME"
    echo ""
    exit 1
elif [ "${PLAN_EXIT:-0}" -eq 1 ]; then
    echo -e "${RED}ERROR${NC}"
    echo "   Terraform plan failed:"
    echo "$PLAN_OUTPUT"
    exit 1
fi
echo -e "${GREEN}OK${NC} - No drift detected"

# All checks passed!
echo ""
echo -e "${GREEN}✅ Validation Passed!${NC}"
echo ""
echo "   You successfully imported Jerry's bucket into Terraform!"
echo ""

# Check which import method was used
IMPORT_METHOD="unknown"
if [ -f "main.tf" ]; then
    if grep -q "^import {" main.tf; then
        IMPORT_METHOD="import blocks"
    else
        IMPORT_METHOD="terraform import command"
    fi
fi

echo "   Import method: ${IMPORT_METHOD}"

# Calculate score
SCORE=100
HINTS_FILE=".jerry/manifest.json"
if [ -f "$HINTS_FILE" ]; then
    HINTS_USED=$(grep -o '"hints_used":[0-9]*' "$HINTS_FILE" | grep -o '[0-9]*' || echo "0")
    HINT_PENALTY=$((HINTS_USED * 5))
    SCORE=$((SCORE - HINT_PENALTY))
    echo "   Hints used: $HINTS_USED (-$HINT_PENALTY points)"
fi

# Bonus points
BONUS=0
if grep -q "aws_s3_bucket_server_side_encryption_configuration" main.tf 2>/dev/null; then
    BONUS=$((BONUS + 10))
    echo "   Bonus: Added encryption (+10)"
fi
if grep -q "aws_s3_bucket_public_access_block" main.tf 2>/dev/null; then
    BONUS=$((BONUS + 10))
    echo "   Bonus: Added public access block (+10)"
fi

FINAL_SCORE=$((SCORE + BONUS))
echo ""
echo "   Score: ${FINAL_SCORE}/100"
echo ""

# Reflection questions
echo -e "${YELLOW}📝 Reflection:${NC}"
echo ""
echo "   1. Which import method did you use?"
echo "      - terraform import (legacy)"
echo "      - import blocks (modern)"
echo ""
echo "   2. What was the trickiest part?"
echo "      - Finding the bucket"
echo "      - Matching the configuration exactly"
echo "      - Remembering to import versioning"
echo ""
echo "   3. How would you prevent 'Jerry scenarios' in real life?"
echo ""
echo -e "${CYAN}💡 Next challenge:${NC}"
echo "   Try the OTHER import method!"
echo ""
echo "   1. Delete your state: rm terraform.tfstate*"
echo "   2. Re-import using the other method"
echo "   3. Compare the experience"
echo ""

exit 0
