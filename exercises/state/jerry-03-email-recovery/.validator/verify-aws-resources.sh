#!/bin/bash
set -e

# Jerry-03: Email Recovery - Verify AWS Resources Helper
# Checks if Jerry's infrastructure exists in AWS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXERCISE_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_DIR="$EXERCISE_DIR/setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Jerry-03: Verify AWS Resources                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Try to get bucket name from various sources
BUCKET_NAME=""

echo -e "${BLUE}Looking for bucket name...${NC}"

# Check terraform.tfvars first
if [ -f "$SETUP_DIR/terraform.tfvars" ]; then
    BUCKET_NAME=$(grep "bucket_name" "$SETUP_DIR/terraform.tfvars" | awk -F'"' '{print $2}' || echo "")
    if [ -n "$BUCKET_NAME" ]; then
        echo -e "${GREEN}✓ Found bucket name in terraform.tfvars${NC}"
    fi
fi

# Check jerry-backup.tfstate if not found
if [ -z "$BUCKET_NAME" ] && [ -f "$EXERCISE_DIR/jerry-backup.tfstate" ]; then
    BUCKET_NAME=$(grep -o '"bucket": "[^"]*"' "$EXERCISE_DIR/jerry-backup.tfstate" | head -1 | awk -F'"' '{print $4}')
    if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "BUCKET_NAME_PLACEHOLDER" ]; then
        echo -e "${GREEN}✓ Found bucket name in jerry-backup.tfstate${NC}"
    else
        BUCKET_NAME=""
    fi
fi

# Check local state if not found
if [ -z "$BUCKET_NAME" ] && [ -f "$SETUP_DIR/terraform.tfstate" ]; then
    BUCKET_NAME=$(grep -o '"bucket": "[^"]*"' "$SETUP_DIR/terraform.tfstate" | head -1 | awk -F'"' '{print $4}')
    if [ -n "$BUCKET_NAME" ]; then
        echo -e "${GREEN}✓ Found bucket name in terraform.tfstate${NC}"
    fi
fi

if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}✗ Could not find bucket name${NC}"
    echo -e "${YELLOW}Have you run simulate-jerry.sh yet?${NC}"
    exit 1
fi

echo -e "${BLUE}Bucket name:${NC} $BUCKET_NAME"
echo ""

# Check if bucket exists
echo -e "${BLUE}Checking S3 bucket...${NC}"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${GREEN}✓ Bucket exists in AWS${NC}"

    # Get bucket details
    BUCKET_REGION=$(aws s3api get-bucket-location --bucket "$BUCKET_NAME" --query 'LocationConstraint' --output text 2>/dev/null || echo "us-east-1")
    if [ "$BUCKET_REGION" == "None" ] || [ -z "$BUCKET_REGION" ]; then
        BUCKET_REGION="us-east-1"
    fi
    echo -e "${GREEN}  Region: ${BUCKET_REGION}${NC}"

    # Check versioning
    VERSIONING_STATUS=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "Not configured")
    if [ "$VERSIONING_STATUS" == "Enabled" ]; then
        echo -e "${GREEN}  Versioning: Enabled ✓${NC}"
    else
        echo -e "${YELLOW}  Versioning: ${VERSIONING_STATUS}${NC}"
    fi

    # Check tags
    echo -e "${BLUE}  Tags:${NC}"
    aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" --query 'TagSet[*].[Key,Value]' --output table 2>/dev/null || echo -e "${YELLOW}    No tags found${NC}"

    # Check for objects
    OBJECT_COUNT=$(aws s3 ls "s3://${BUCKET_NAME}/" 2>/dev/null | wc -l)
    if [ "$OBJECT_COUNT" -gt 0 ]; then
        echo -e "${BLUE}  Objects: ${OBJECT_COUNT} objects in bucket${NC}"
    else
        echo -e "${BLUE}  Objects: Bucket is empty${NC}"
    fi

else
    echo -e "${RED}✗ Bucket does NOT exist in AWS${NC}"
    echo -e "${YELLOW}Have you run simulate-jerry.sh yet?${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Comparing with jerry-backup.tfstate...${NC}"

if [ -f "$EXERCISE_DIR/jerry-backup.tfstate" ]; then
    STATE_BUCKET=$(jq -r '.resources[] | select(.type=="aws_s3_bucket") | .instances[0].attributes.bucket' "$EXERCISE_DIR/jerry-backup.tfstate" 2>/dev/null)

    if [ "$STATE_BUCKET" == "$BUCKET_NAME" ]; then
        echo -e "${GREEN}✓ Bucket name matches state file${NC}"
    else
        echo -e "${RED}✗ Bucket name mismatch!${NC}"
        echo -e "${YELLOW}  State file: ${STATE_BUCKET}${NC}"
        echo -e "${YELLOW}  AWS bucket: ${BUCKET_NAME}${NC}"
    fi

    STATE_VERSIONING=$(jq -r '.resources[] | select(.type=="aws_s3_bucket_versioning") | .instances[0].attributes.versioning_configuration[0].status' "$EXERCISE_DIR/jerry-backup.tfstate" 2>/dev/null)

    if [ "$STATE_VERSIONING" == "$VERSIONING_STATUS" ]; then
        echo -e "${GREEN}✓ Versioning status matches state file${NC}"
    else
        echo -e "${YELLOW}⚠ Versioning status mismatch${NC}"
        echo -e "${YELLOW}  State file: ${STATE_VERSIONING}${NC}"
        echo -e "${YELLOW}  AWS status: ${VERSIONING_STATUS}${NC}"
    fi
else
    echo -e "${YELLOW}⚠ jerry-backup.tfstate not found, skipping comparison${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                Resources Verified!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "• Bucket exists in AWS: ${BUCKET_NAME}"
echo "• Infrastructure is ready for state recovery"
echo "• You can now practice recovering the state file"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. cd setup/"
echo "2. terraform init"
echo "3. terraform plan (notice: no resources in state!)"
echo "4. terraform state push ../jerry-backup.tfstate"
echo "5. terraform plan (should show: No changes)"
echo ""
