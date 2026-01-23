#!/bin/bash
# Reset script for Jerry 06: Import Rescue
#
# This script:
# - Deletes Jerry's manually created bucket
# - Cleans up local files
# - Allows you to start fresh
#
# Usage: ./reset.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔄 Resetting Jerry 06: Import Rescue${NC}"
echo ""

# Check if bucket exists
if [ ! -f ".jerry/bucket-name.txt" ]; then
    echo -e "${YELLOW}No bucket to delete.${NC}"
    echo "Run '../.validator/simulate-jerry.sh' to create one."
    exit 0
fi

BUCKET_NAME=$(cat .jerry/bucket-name.txt)
echo "Bucket to delete: ${BUCKET_NAME}"
echo ""

# Confirm deletion
echo -e "${YELLOW}⚠️  This will DELETE the bucket and all its contents!${NC}"
read -p "Are you sure? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "Cancelled."
    exit 0
fi

# Check if bucket exists in AWS
echo -n "Checking bucket exists... "
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}NOT FOUND${NC}"
    echo "Bucket doesn't exist in AWS (already deleted?)"
else
    echo -e "${GREEN}OK${NC}"

    # Empty the bucket first (required before deletion)
    echo -n "Emptying bucket... "
    aws s3 rm "s3://${BUCKET_NAME}" --recursive --quiet 2>/dev/null || true
    echo -e "${GREEN}✓${NC}"

    # Delete the bucket
    echo -n "Deleting bucket... "
    aws s3api delete-bucket --bucket "$BUCKET_NAME" 2>/dev/null || {
        echo -e "${RED}FAILED${NC}"
        echo "Could not delete bucket. It may have versioned objects."
        echo ""
        echo "Manual cleanup:"
        echo "  aws s3api list-object-versions --bucket $BUCKET_NAME"
        echo "  aws s3api delete-bucket --bucket $BUCKET_NAME"
        exit 1
    }
    echo -e "${GREEN}✓${NC}"
fi

# Clean up local files
echo -n "Cleaning up local files... "
rm -rf .jerry
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
rm -rf .terraform
rm -f generated.tf
echo -e "${GREEN}✓${NC}"

echo ""
echo -e "${GREEN}✅ Reset complete!${NC}"
echo ""
echo "You can now:"
echo "  1. Run '../.validator/simulate-jerry.sh' to create a new bucket"
echo "  2. Try the exercise again with a different approach"
echo ""
