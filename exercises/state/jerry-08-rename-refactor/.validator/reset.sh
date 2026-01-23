#!/bin/bash
# Reset Jerry's rename refactor
#
# This script resets the exercise by restoring the original main.tf
# and optionally resetting the state.
#
# Usage: ./reset.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Resetting exercise...${NC}"
echo ""

# Check if backup exists
if [ ! -f "main.tf.backup" ]; then
    echo -e "${YELLOW}Warning: main.tf.backup not found.${NC}"
    echo "Either Jerry's simulation hasn't run, or backup was deleted."
    echo ""
    echo "Restoring from ../setup/main.tf instead..."
    cp ../setup/main.tf .
    echo -e "${GREEN}OK${NC}"
else
    echo "Restoring original main.tf from backup..."
    cp main.tf.backup main.tf
    rm main.tf.backup
    echo -e "${GREEN}OK${NC}"
fi

# Clean up jerry manifest
if [ -d ".jerry" ]; then
    rm -rf .jerry
    echo "Cleaned up .jerry directory"
fi

# Check if state needs to be reset
echo ""
echo -e "${CYAN}Checking state...${NC}"
STATE_LIST=$(terraform state list 2>/dev/null || echo "")

# If state has new addresses, offer to reset
if echo "$STATE_LIST" | grep -q "application_data"; then
    echo ""
    echo "State has been migrated to new addresses."
    echo ""
    echo "Do you want to reset state to original addresses? (y/N)"
    read -r RESET_STATE

    if [[ "$RESET_STATE" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Resetting state addresses..."

        # Move resources back to original names
        if echo "$STATE_LIST" | grep -q "aws_s3_bucket.application_data"; then
            terraform state mv aws_s3_bucket.application_data aws_s3_bucket.bucket1 2>/dev/null || true
        fi
        if echo "$STATE_LIST" | grep -q "aws_s3_bucket.user_uploads"; then
            terraform state mv aws_s3_bucket.user_uploads aws_s3_bucket.bucket2 2>/dev/null || true
        fi
        if echo "$STATE_LIST" | grep -q "random_id.app_suffix"; then
            terraform state mv random_id.app_suffix random_id.suffix1 2>/dev/null || true
        fi
        if echo "$STATE_LIST" | grep -q "random_id.uploads_suffix"; then
            terraform state mv random_id.uploads_suffix random_id.suffix2 2>/dev/null || true
        fi

        # Move all dependent resources
        for resource in $(terraform state list | grep "application_data" | grep -v "aws_s3_bucket.application_data"); do
            new_name=$(echo "$resource" | sed 's/application_data/bucket1/')
            terraform state mv "$resource" "$new_name" 2>/dev/null || true
        done

        for resource in $(terraform state list | grep "user_uploads" | grep -v "aws_s3_bucket.user_uploads"); do
            new_name=$(echo "$resource" | sed 's/user_uploads/bucket2/')
            terraform state mv "$resource" "$new_name" 2>/dev/null || true
        done

        echo -e "${GREEN}State addresses reset to original names${NC}"
    else
        echo "Keeping current state addresses."
    fi
fi

# Remove any moved blocks from main.tf
if grep -q "^moved {" main.tf 2>/dev/null; then
    echo ""
    echo "Removing moved blocks from main.tf..."
    # This is a simple version - assumes moved blocks are clearly separated
    sed -i.tmp '/^moved {/,/^}/d' main.tf
    rm -f main.tf.tmp
    echo -e "${GREEN}Moved blocks removed${NC}"
fi

echo ""
echo -e "${GREEN}✅ Exercise reset complete!${NC}"
echo ""
echo "You can now run '../.validator/simulate-jerry.sh' to recreate the problem."
echo ""
