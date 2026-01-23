#!/bin/bash
# Reset Jerry's remote lock scenario
#
# This script removes any existing lock file from S3, allowing you to
# try the exercise again.
#
# Usage: ./reset.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Resetting exercise...${NC}"
echo ""

# Get state bucket from terraform.tfvars
echo -n "Getting state bucket name... "
STATE_BUCKET=$(grep '^state_bucket' terraform.tfvars 2>/dev/null | awk '{print $3}' | tr -d '"') || {
    echo -e "${RED}FAILED${NC}"
    echo "Could not find state_bucket in terraform.tfvars"
    echo "Make sure you're in the student-work directory."
    exit 1
}

if [ -z "$STATE_BUCKET" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "state_bucket is empty in terraform.tfvars"
    exit 1
fi
echo -e "${GREEN}OK${NC}"
echo "   State bucket: $STATE_BUCKET"

# Define S3 paths
STATE_KEY="gym/state/jerry-02-remote-lock/terraform.tfstate"
LOCK_KEY="${STATE_KEY}.tflock"
S3_LOCK_PATH="s3://${STATE_BUCKET}/${LOCK_KEY}"

# Check if lock exists
echo -n "Checking for lock file... "
if aws s3api head-object --bucket "$STATE_BUCKET" --key "$LOCK_KEY" &>/dev/null; then
    echo -e "${YELLOW}FOUND${NC}"
    echo "   Removing lock: $S3_LOCK_PATH"
    aws s3 rm "$S3_LOCK_PATH"
    echo -e "   ${GREEN}Lock removed${NC}"
else
    echo -e "${GREEN}OK${NC} - No lock exists"
fi

# Clean up jerry manifest
if [ -d ".jerry" ]; then
    rm -rf .jerry
    echo "Cleaned up .jerry directory"
fi

# Verify terraform works
echo ""
echo -n "Verifying Terraform works... "
if terraform plan -no-color > /dev/null 2>&1; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}WARNING${NC}"
    echo "   Terraform plan returned non-zero exit code (might be normal if changes pending)"
fi

echo ""
echo -e "${GREEN}✅ Exercise reset complete!${NC}"
echo ""
echo "You can now:"
echo "  1. Run '../.validator/simulate-jerry.sh' to create the lock again"
echo "  2. Practice unlocking with different methods"
echo ""
echo -e "${CYAN}Tip: Try both unlock methods to understand when each is appropriate.${NC}"
