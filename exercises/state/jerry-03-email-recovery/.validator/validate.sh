#!/bin/bash
set -e

# Jerry-03: Email Recovery - Validation Script
# Checks if the student has successfully recovered Jerry's state

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXERCISE_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_DIR="$EXERCISE_DIR/setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VALIDATION_FAILED=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Jerry-03: Email Recovery - Validation                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Change to setup directory
cd "$SETUP_DIR"

# Check 1: Terraform is initialized
echo -e "${BLUE}[1/6] Checking Terraform initialization...${NC}"
if [ -d ".terraform" ]; then
    echo -e "${GREEN}✓ Terraform is initialized${NC}"
else
    echo -e "${RED}✗ Terraform not initialized. Run: terraform init${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 2: State file exists and is not empty
echo -e "${BLUE}[2/6] Checking state file exists...${NC}"
if [ -f "terraform.tfstate" ]; then
    STATE_SIZE=$(wc -c < "terraform.tfstate")
    if [ "$STATE_SIZE" -gt 100 ]; then
        echo -e "${GREEN}✓ State file exists and has content${NC}"
    else
        echo -e "${RED}✗ State file exists but appears empty${NC}"
        VALIDATION_FAILED=1
    fi
else
    echo -e "${RED}✗ No terraform.tfstate found${NC}"
    echo -e "${YELLOW}  Hint: Have you recovered the state using terraform state push?${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 3: State contains the expected resources
echo -e "${BLUE}[3/6] Checking state contains correct resources...${NC}"
if [ -f "terraform.tfstate" ]; then
    BUCKET_COUNT=$(terraform state list 2>/dev/null | grep -c "aws_s3_bucket.important_data" || true)
    VERSIONING_COUNT=$(terraform state list 2>/dev/null | grep -c "aws_s3_bucket_versioning.important_data" || true)

    if [ "$BUCKET_COUNT" -ge 1 ] && [ "$VERSIONING_COUNT" -ge 1 ]; then
        echo -e "${GREEN}✓ State contains expected resources:${NC}"
        terraform state list | while read -r resource; do
            echo -e "  ${GREEN}• ${resource}${NC}"
        done
    else
        echo -e "${RED}✗ State is missing expected resources${NC}"
        echo -e "${YELLOW}  Expected:${NC}"
        echo -e "  • aws_s3_bucket.important_data"
        echo -e "  • aws_s3_bucket_versioning.important_data"
        echo -e "${YELLOW}  Found:${NC}"
        terraform state list || echo "  (none)"
        VALIDATION_FAILED=1
    fi
else
    echo -e "${RED}✗ Cannot check resources - no state file${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 4: Get bucket name from state
echo -e "${BLUE}[4/6] Extracting bucket name from state...${NC}"
if [ -f "terraform.tfstate" ]; then
    BUCKET_NAME=$(terraform state show aws_s3_bucket.important_data 2>/dev/null | grep "bucket " | awk '{print $3}' | tr -d '"' || echo "")

    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "null" ]; then
        echo -e "${GREEN}✓ Bucket name: ${BUCKET_NAME}${NC}"
    else
        echo -e "${RED}✗ Could not extract bucket name from state${NC}"
        VALIDATION_FAILED=1
    fi
else
    echo -e "${RED}✗ Cannot extract bucket name - no state file${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 5: Verify resources exist in AWS
echo -e "${BLUE}[5/6] Verifying resources exist in AWS...${NC}"
if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "null" ]; then
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo -e "${GREEN}✓ Bucket exists in AWS: ${BUCKET_NAME}${NC}"

        # Check versioning
        VERSIONING_STATUS=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "None")
        if [ "$VERSIONING_STATUS" == "Enabled" ]; then
            echo -e "${GREEN}✓ Versioning is enabled${NC}"
        else
            echo -e "${YELLOW}⚠ Versioning status: ${VERSIONING_STATUS}${NC}"
        fi

        # Check tags
        OWNER_TAG=$(aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" --query "TagSet[?Key=='Owner'].Value" --output text 2>/dev/null || echo "")
        if [ "$OWNER_TAG" == "jerry" ]; then
            echo -e "${GREEN}✓ Bucket has correct tags (Owner: jerry)${NC}"
        else
            echo -e "${YELLOW}⚠ Owner tag: ${OWNER_TAG:-'not set'}${NC}"
        fi
    else
        echo -e "${RED}✗ Bucket does not exist in AWS: ${BUCKET_NAME}${NC}"
        echo -e "${YELLOW}  Did you run simulate-jerry.sh first?${NC}"
        VALIDATION_FAILED=1
    fi
else
    echo -e "${RED}✗ Cannot verify AWS resources - no bucket name${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 6: Run terraform plan and verify no changes
echo -e "${BLUE}[6/6] Running terraform plan...${NC}"
if terraform plan -detailed-exitcode > /tmp/tf-plan-output.txt 2>&1; then
    echo -e "${GREEN}✓ terraform plan shows no changes${NC}"
    echo -e "${GREEN}  State matches actual infrastructure!${NC}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        echo -e "${RED}✗ terraform plan shows changes needed${NC}"
        echo -e "${YELLOW}  This means state doesn't match infrastructure${NC}"
        echo ""
        echo -e "${YELLOW}Plan output:${NC}"
        cat /tmp/tf-plan-output.txt
        VALIDATION_FAILED=1
    else
        echo -e "${RED}✗ terraform plan failed with error${NC}"
        cat /tmp/tf-plan-output.txt
        VALIDATION_FAILED=1
    fi
fi
rm -f /tmp/tf-plan-output.txt
echo ""

# Final verdict
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    VALIDATION PASSED!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Congratulations!${NC} You've successfully recovered Jerry's state."
    echo ""
    echo -e "${YELLOW}What you accomplished:${NC}"
    echo "✓ Recovered state from Jerry's email backup"
    echo "✓ State correctly tracks AWS resources"
    echo "✓ terraform plan shows no drift"
    echo "✓ Infrastructure is now manageable again"
    echo ""
    echo -e "${YELLOW}Key Lessons:${NC}"
    echo "• State files are Terraform's memory of managed resources"
    echo "• Without state, Terraform doesn't know about existing infrastructure"
    echo "• Local state is dangerous (single point of failure)"
    echo "• Always use remote backends (S3, Terraform Cloud) for production"
    echo "• Enable versioning on state storage for recovery"
    echo ""
    echo -e "${BLUE}Going Further:${NC}"
    echo "1. Try migrating to an S3 backend (see solution/SOLUTION.md)"
    echo "2. Experiment with terraform state commands:"
    echo "   • terraform state show aws_s3_bucket.important_data"
    echo "   • terraform state list"
    echo "3. Make a change and observe how the state file updates"
    echo "4. Review the state file structure (cat terraform.tfstate | jq .)"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    VALIDATION FAILED                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Common Issues:${NC}"
    echo ""
    echo -e "${YELLOW}1. Haven't run simulate-jerry.sh yet?${NC}"
    echo "   Run: ../.validator/simulate-jerry.sh"
    echo ""
    echo -e "${YELLOW}2. Haven't recovered the state?${NC}"
    echo "   Try: terraform state push ../jerry-backup.tfstate"
    echo ""
    echo -e "${YELLOW}3. State has wrong resources?${NC}"
    echo "   Check: terraform state list"
    echo "   Compare with: cat ../jerry-backup.tfstate | jq .resources[].name"
    echo ""
    echo -e "${YELLOW}4. Need to start over?${NC}"
    echo "   Run: ../.validator/reset.sh"
    echo ""
    echo -e "${BLUE}Hints:${NC}"
    echo "• Look at hints in README.md (especially Hint 5)"
    echo "• Examine jerry-backup.tfstate to understand what should be in state"
    echo "• The terraform state push command is your friend"
    echo "• Run ../.validator/verify-aws-resources.sh to check AWS"
    echo ""
    exit 1
fi
