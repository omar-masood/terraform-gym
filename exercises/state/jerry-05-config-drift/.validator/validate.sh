#!/bin/bash
#
# validate.sh
# Validates that the student has successfully resolved the configuration drift
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Navigate to setup directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$SCRIPT_DIR/../setup"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Jerry-05 Validation${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track validation results
PASSED=0
FAILED=0
TOTAL=0

# Helper function for validation checks
check() {
    local name="$1"
    local description="$2"
    shift 2

    TOTAL=$((TOTAL + 1))
    echo -n "[$TOTAL] $description... "

    if "$@" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}"
        PASSED=$((PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}"
        FAILED=$((FAILED + 1))
        return 1
    fi
}

# Check if we're in the right directory
cd "$SETUP_DIR" 2>/dev/null || {
    echo -e "${RED}Error: Cannot find setup directory${NC}"
    exit 1
}

# Get bucket name
BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null || echo "")

if [[ -z "$BUCKET_NAME" ]]; then
    echo -e "${RED}Error: Cannot get bucket name from Terraform${NC}"
    echo "Please ensure Terraform has been applied successfully"
    exit 1
fi

echo -e "${BLUE}Validating bucket: $BUCKET_NAME${NC}"
echo ""

# Validation checks

# Check 1: Terraform plan shows no drift
echo -e "${YELLOW}Checking Terraform state...${NC}"
check "no_drift" "No configuration drift detected" \
    terraform plan -detailed-exitcode

# Check 2: Versioning is enabled in AWS
echo ""
echo -e "${YELLOW}Checking AWS bucket configuration...${NC}"
VERSIONING_STATUS=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "")

if [[ "$VERSIONING_STATUS" == "Enabled" ]]; then
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "[2] Bucket versioning is enabled... ${GREEN}✓ PASS${NC}"
else
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    echo -e "[2] Bucket versioning is enabled... ${RED}✗ FAIL${NC}"
    echo -e "    Current status: ${YELLOW}$VERSIONING_STATUS${NC}"
fi

# Check 3: Encryption is configured in AWS
ENCRYPTION_ALGO=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "")

if [[ "$ENCRYPTION_ALGO" == "AES256" ]]; then
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "[3] Server-side encryption is configured... ${GREEN}✓ PASS${NC}"
else
    TOTAL=$((TOTAL + 1))
    FAILED=$((FAILED + 1))
    echo -e "[3] Server-side encryption is configured... ${RED}✗ FAIL${NC}"
    echo -e "    Current algorithm: ${YELLOW}${ENCRYPTION_ALGO:-None}${NC}"
fi

# Check 4: Student documented their decision (optional but recommended)
echo ""
echo -e "${YELLOW}Checking documentation...${NC}"
if [[ -f "$SETUP_DIR/DECISION.md" ]] || [[ -f "$SCRIPT_DIR/../DECISION.md" ]]; then
    TOTAL=$((TOTAL + 1))
    PASSED=$((PASSED + 1))
    echo -e "[4] Decision is documented... ${GREEN}✓ PASS${NC}"
else
    TOTAL=$((TOTAL + 1))
    echo -e "[4] Decision is documented... ${YELLOW}⚠ SKIPPED${NC}"
    echo -e "    ${YELLOW}Recommended: Create DECISION.md to document your reasoning${NC}"
    # Don't count as failed, but as warning
    PASSED=$((PASSED + 1))
fi

# Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Validation Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All checks passed! ($PASSED/$TOTAL)${NC}"
    echo ""
    echo -e "${GREEN}Congratulations!${NC} You've successfully resolved the configuration drift."
    echo ""
    echo -e "${YELLOW}Key Takeaways:${NC}"
    echo "  • Configuration drift is more serious than tag drift"
    echo "  • Always read the plan carefully before applying"
    echo "  • Security settings shouldn't be disabled without proper assessment"
    echo "  • Infrastructure changes should go through proper change management"
    echo ""
    echo -e "${BLUE}What's next?${NC}"
    echo "  • Review the discussion questions in README.md"
    echo "  • Check out Jerry-06: Import Rescue"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Some checks failed ($PASSED/$TOTAL passed)${NC}"
    echo ""
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo ""

    if ! terraform plan -detailed-exitcode >/dev/null 2>&1; then
        echo -e "${RED}Drift still exists:${NC}"
        echo "  Run: terraform plan"
        echo "  Read the plan carefully and decide on your response"
        echo ""
    fi

    if [[ "$VERSIONING_STATUS" != "Enabled" ]]; then
        echo -e "${RED}Versioning not enabled:${NC}"
        echo "  Current status: $VERSIONING_STATUS"
        echo "  Expected: Enabled"
        echo ""
        echo "  To fix:"
        echo "  • Option A: Run 'terraform apply' to re-enable"
        echo "  • Option B: Update Terraform config to match current state"
        echo ""
    fi

    if [[ "$ENCRYPTION_ALGO" != "AES256" ]]; then
        echo -e "${RED}Encryption not configured:${NC}"
        echo "  Current: ${ENCRYPTION_ALGO:-None}"
        echo "  Expected: AES256"
        echo ""
        echo "  To fix:"
        echo "  • Option A: Run 'terraform apply' to restore encryption"
        echo "  • Option B: Remove encryption resource from Terraform config"
        echo ""
    fi

    echo -e "${YELLOW}Hints:${NC}"
    echo "  • Review the README.md for detailed instructions"
    echo "  • Check the solution directory for guidance"
    echo "  • Think about the security implications before deciding"
    echo ""
    exit 1
fi
