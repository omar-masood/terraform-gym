#!/bin/bash
# Reset Jerry's tag drift
#
# This script resets the exercise by applying Terraform to restore original tags.
#
# Usage: ./reset.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Resetting exercise...${NC}"
echo ""

# Apply Terraform to restore original state
echo "Applying Terraform to restore original tags..."
terraform apply -auto-approve

# Clean up jerry manifest
if [ -d ".jerry" ]; then
    rm -rf .jerry
    echo "Cleaned up .jerry directory"
fi

echo ""
echo -e "${GREEN}✅ Exercise reset complete!${NC}"
echo ""
echo "You can now run './simulate-jerry.sh' to create drift again."
