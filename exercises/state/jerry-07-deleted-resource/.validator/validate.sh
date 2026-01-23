#!/bin/bash
set -e

# Jerry-07: Deleted Resource - Validation Script
# This validator accepts BOTH solutions:
# - Option A: Remove from state (terraform state rm)
# - Option B: Recreate the bucket (terraform apply)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")/setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VALIDATION_FAILED=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Jerry-07: Deleted Resource - Validation                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Change to setup directory
cd "$SETUP_DIR"

# Check 1: Terraform is initialized
echo -e "${BLUE}[1/5] Checking Terraform initialization...${NC}"
if [ -d ".terraform" ]; then
    echo -e "${GREEN}✓ Terraform is initialized${NC}"
else
    echo -e "${RED}✗ Terraform not initialized${NC}"
    VALIDATION_FAILED=1
fi
echo ""

# Check 2: Get current state
echo -e "${BLUE}[2/5] Checking Terraform state...${NC}"
STATE_RESOURCES=$(terraform state list 2>/dev/null || echo "")

if [ -z "$STATE_RESOURCES" ]; then
    echo -e "${RED}✗ State appears to be empty${NC}"
    VALIDATION_FAILED=1
else
    echo -e "${GREEN}✓ State contains resources${NC}"
    echo "Resources in state:"
    echo "$STATE_RESOURCES" | sed 's/^/  /'
fi
echo ""

# Check 3: Determine which solution was used
echo -e "${BLUE}[3/5] Determining which solution approach was used...${NC}"

OLD_LOGS_IN_STATE=false
if echo "$STATE_RESOURCES" | grep -q "aws_s3_bucket.old_logs"; then
    OLD_LOGS_IN_STATE=true
fi

# Try to get bucket name from state (if it exists) or from outputs
OLD_LOGS_BUCKET=""
if [ "$OLD_LOGS_IN_STATE" = true ]; then
    OLD_LOGS_BUCKET=$(terraform state show aws_s3_bucket.old_logs 2>/dev/null | grep "bucket " | awk '{print $3}' | tr -d '"' || echo "")
fi

# Fallback: try to construct bucket name from pattern
if [ -z "$OLD_LOGS_BUCKET" ]; then
    # Get the random suffix from app_data bucket
    APP_BUCKET=$(terraform state show aws_s3_bucket.app_data 2>/dev/null | grep "bucket " | awk '{print $3}' | tr -d '"' || echo "")
    if [ -n "$APP_BUCKET" ]; then
        SUFFIX=$(echo "$APP_BUCKET" | sed 's/app-data-//')
        OLD_LOGS_BUCKET="old-logs-${SUFFIX}"
    fi
fi

# Check if bucket exists in AWS
OLD_LOGS_EXISTS_IN_AWS=false
if [ -n "$OLD_LOGS_BUCKET" ]; then
    if aws s3api head-bucket --bucket "$OLD_LOGS_BUCKET" 2>/dev/null; then
        OLD_LOGS_EXISTS_IN_AWS=true
    fi
fi

# Determine which solution was used
if [ "$OLD_LOGS_IN_STATE" = true ] && [ "$OLD_LOGS_EXISTS_IN_AWS" = true ]; then
    SOLUTION="recreate"
    echo -e "${BLUE}→ Detected: Option B (Recreate) - Bucket exists in both state and AWS${NC}"
elif [ "$OLD_LOGS_IN_STATE" = false ] && [ "$OLD_LOGS_EXISTS_IN_AWS" = false ]; then
    SOLUTION="remove"
    echo -e "${BLUE}→ Detected: Option A (Remove) - Bucket removed from state${NC}"
elif [ "$OLD_LOGS_IN_STATE" = true ] && [ "$OLD_LOGS_EXISTS_IN_AWS" = false ]; then
    SOLUTION="incomplete"
    echo -e "${YELLOW}→ Detected: Problem still exists - Bucket in state but not in AWS${NC}"
elif [ "$OLD_LOGS_IN_STATE" = false ] && [ "$OLD_LOGS_EXISTS_IN_AWS" = true ]; then
    SOLUTION="orphan"
    echo -e "${YELLOW}→ Detected: Orphan - Bucket exists in AWS but not in state${NC}"
else
    SOLUTION="unknown"
    echo -e "${YELLOW}→ Unable to determine solution approach${NC}"
fi
echo ""

# Check 4: Verify terraform plan shows no changes
echo -e "${BLUE}[4/5] Running terraform plan...${NC}"
if terraform plan -detailed-exitcode > /tmp/tf-plan-output.txt 2>&1; then
    echo -e "${GREEN}✓ terraform plan shows no changes${NC}"
    echo -e "${GREEN}  State matches actual infrastructure!${NC}"
else
    EXIT_CODE=$?
    if [ $EXIT_CODE -eq 2 ]; then
        echo -e "${RED}✗ terraform plan shows changes needed${NC}"
        echo -e "${YELLOW}  This means the problem isn't fully resolved yet${NC}"
        echo ""
        echo -e "${YELLOW}Plan output:${NC}"
        head -n 50 /tmp/tf-plan-output.txt
        VALIDATION_FAILED=1
    else
        echo -e "${RED}✗ terraform plan failed with error${NC}"
        cat /tmp/tf-plan-output.txt
        VALIDATION_FAILED=1
    fi
fi
rm -f /tmp/tf-plan-output.txt
echo ""

# Check 5: Validate solution coherence
echo -e "${BLUE}[5/5] Validating solution coherence...${NC}"

case $SOLUTION in
    "recreate")
        echo -e "${BLUE}Validating Option B (Recreate)...${NC}"
        if [ "$OLD_LOGS_EXISTS_IN_AWS" = true ]; then
            echo -e "${GREEN}✓ Bucket exists in AWS${NC}"
        else
            echo -e "${RED}✗ Bucket should exist in AWS for this solution${NC}"
            VALIDATION_FAILED=1
        fi

        if [ "$OLD_LOGS_IN_STATE" = true ]; then
            echo -e "${GREEN}✓ Bucket is tracked in state${NC}"
        else
            echo -e "${RED}✗ Bucket should be in state for this solution${NC}"
            VALIDATION_FAILED=1
        fi
        ;;

    "remove")
        echo -e "${BLUE}Validating Option A (Remove from state)...${NC}"
        if [ "$OLD_LOGS_IN_STATE" = false ]; then
            echo -e "${GREEN}✓ Bucket removed from state${NC}"
        else
            echo -e "${RED}✗ Bucket should be removed from state${NC}"
            VALIDATION_FAILED=1
        fi

        if [ "$OLD_LOGS_EXISTS_IN_AWS" = false ]; then
            echo -e "${GREEN}✓ Bucket deleted from AWS (as Jerry intended)${NC}"
        else
            echo -e "${YELLOW}⚠ Bucket still exists in AWS but not in state${NC}"
            echo -e "${YELLOW}  Consider: Should you remove from .tf files too?${NC}"
        fi

        # Check if resource is still in main.tf
        if grep -q "aws_s3_bucket.*old_logs" main.tf 2>/dev/null; then
            echo -e "${YELLOW}⚠ Resource still defined in main.tf${NC}"
            echo -e "${YELLOW}  Recommendation: Remove it from configuration too${NC}"
        else
            echo -e "${GREEN}✓ Resource also removed from configuration${NC}"
        fi
        ;;

    "incomplete")
        echo -e "${RED}✗ Problem not resolved${NC}"
        echo -e "${YELLOW}  Bucket is in state but doesn't exist in AWS${NC}"
        echo -e "${YELLOW}  You need to either:${NC}"
        echo -e "${YELLOW}    A) terraform state rm aws_s3_bucket.old_logs${NC}"
        echo -e "${YELLOW}    B) terraform apply (to recreate)${NC}"
        VALIDATION_FAILED=1
        ;;

    "orphan")
        echo -e "${YELLOW}⚠ Unusual state: Bucket exists in AWS but not in state${NC}"
        echo -e "${YELLOW}  Did you recreate manually instead of using Terraform?${NC}"
        VALIDATION_FAILED=1
        ;;

    *)
        echo -e "${RED}✗ Unable to validate - unclear solution state${NC}"
        VALIDATION_FAILED=1
        ;;
esac
echo ""

# Final verdict
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
if [ $VALIDATION_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    VALIDATION PASSED!                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    case $SOLUTION in
        "recreate")
            echo -e "${GREEN}Solution: Option B - Recreate the Bucket${NC}"
            echo ""
            echo -e "${YELLOW}What you did:${NC}"
            echo "✓ Ran terraform apply to recreate the deleted bucket"
            echo "✓ Corrected Jerry's manual deletion"
            echo "✓ State and AWS now match"
            echo ""
            echo -e "${YELLOW}This was the right choice if:${NC}"
            echo "• The bucket is actually needed"
            echo "• Jerry made a mistake deleting it"
            echo "• Applications depend on this resource"
            echo ""
            echo -e "${BLUE}Note:${NC} Any data that was in the bucket is permanently lost."
            echo "      The recreated bucket is empty."
            ;;

        "remove")
            echo -e "${GREEN}Solution: Option A - Remove from State${NC}"
            echo ""
            echo -e "${YELLOW}What you did:${NC}"
            echo "✓ Ran terraform state rm to remove bucket from state"
            echo "✓ Accepted Jerry's manual deletion as intentional"
            echo "✓ Cleaned up state to match reality"
            echo ""
            echo -e "${YELLOW}This was the right choice if:${NC}"
            echo "• The bucket was genuinely unused"
            echo "• Jerry's assessment was correct"
            echo "• Resource is being decommissioned"
            echo ""
            if grep -q "aws_s3_bucket.*old_logs" main.tf 2>/dev/null; then
                echo -e "${BLUE}Bonus Task:${NC} Consider removing the resource from main.tf too"
                echo "            to keep your code in sync with state."
            fi
            ;;
    esac

    echo ""
    echo -e "${YELLOW}Key Lessons:${NC}"
    echo "• Terraform state can diverge from AWS reality"
    echo "• Manual deletions create state-reality mismatches"
    echo "• You must decide: recreate or remove from state"
    echo "• Both solutions are valid depending on circumstances"
    echo "• terraform plan detects the mismatch"
    echo "• Always make infrastructure changes through Terraform"
    echo ""
    echo -e "${BLUE}Going Further:${NC}"
    echo "1. Try the other solution approach (reset and retry)"
    echo "2. Add lifecycle prevent_destroy to critical resources"
    echo "3. Review solution/SOLUTION.md for more details"
    echo "4. Practice deciding when to recreate vs remove"
    echo ""
    exit 0
else
    echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    VALIDATION FAILED                       ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Current State:${NC}"
    echo "  old_logs in state: $OLD_LOGS_IN_STATE"
    echo "  old_logs in AWS:   $OLD_LOGS_EXISTS_IN_AWS"
    echo ""
    echo -e "${YELLOW}The Problem:${NC}"
    echo "State and reality don't match yet. You need to make a decision:"
    echo ""
    echo -e "${BLUE}Option A: Remove from state${NC} (if Jerry was right)"
    echo "  terraform state rm aws_s3_bucket.old_logs"
    echo "  terraform plan  # Should show no changes"
    echo ""
    echo -e "${BLUE}Option B: Recreate the bucket${NC} (if we need it)"
    echo "  terraform apply"
    echo "  terraform plan  # Should show no changes"
    echo ""
    echo -e "${YELLOW}Hints:${NC}"
    echo "• Check if bucket exists: aws s3 ls | grep old-logs"
    echo "• Check state: terraform state list | grep old_logs"
    echo "• The bucket was called 'old_logs' and tagged 'deprecated'"
    echo "• Jerry said it 'wasn't being used anymore'"
    echo ""
    echo -e "${YELLOW}To reset and try again:${NC}"
    echo "  ../.validator/reset.sh"
    echo ""
    exit 1
fi
