#!/bin/bash
# Reset Jerry's stale lock
#
# This script resets the exercise by removing the lock file.
#
# Usage: ./reset.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔄 Resetting exercise...${NC}"
echo ""

# Remove lock file if it exists
if [ -f ".terraform.tfstate.lock.info" ]; then
    echo "Removing stale lock file..."
    rm -f .terraform.tfstate.lock.info
    echo -e "${GREEN}Lock file removed${NC}"
else
    echo "No lock file found (already clean)"
fi

# Clean up jerry manifest
if [ -d ".jerry" ]; then
    rm -rf .jerry
    echo "Cleaned up .jerry directory"
fi

echo ""
echo -e "${GREEN}✅ Exercise reset complete!${NC}"
echo ""
echo "You can now run '../.validator/simulate-jerry.sh' to create a lock again."
echo ""
