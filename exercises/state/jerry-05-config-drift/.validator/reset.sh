#!/bin/bash
#
# reset.sh
# Resets the exercise to initial state by re-enabling security features
# and running terraform apply to synchronize state
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
echo -e "${BLUE}  Jerry-05 Exercise Reset${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in a Terraform directory
if [[ ! -f "$SETUP_DIR/main.tf" ]]; then
    echo -e "${RED}Error: Cannot find setup/main.tf${NC}"
    exit 1
fi

# Get bucket name
cd "$SETUP_DIR"
BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null || echo "")

if [[ -z "$BUCKET_NAME" ]]; then
    echo -e "${RED}Error: Cannot get bucket name from Terraform${NC}"
    echo "The infrastructure may not be deployed. Run: terraform apply"
    exit 1
fi

echo -e "${YELLOW}This will reset the exercise to its initial state:${NC}"
echo "  • Re-enable versioning on bucket: $BUCKET_NAME"
echo "  • Restore server-side encryption (AES256)"
echo "  • Run terraform apply to synchronize state"
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Reset cancelled${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}Resetting bucket configuration...${NC}"

# Re-enable versioning
echo -n "  [1/2] Re-enabling versioning... "
if aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    echo -e "${RED}Error: Could not re-enable versioning${NC}"
    exit 1
fi

# Restore encryption
echo -n "  [2/2] Restoring encryption... "
if aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            },
            "BucketKeyEnabled": true
        }]
    }' >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    echo -e "${RED}Error: Could not restore encryption${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Synchronizing Terraform state...${NC}"
echo ""

# Refresh state to detect the changes we just made
terraform apply -refresh-only -auto-approve

echo ""
echo -e "${GREEN}✓ Exercise reset complete!${NC}"
echo ""

# Verify
echo -e "${BLUE}Current configuration:${NC}"
VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null)
ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null)

echo "  Versioning: ${GREEN}$VERSIONING${NC}"
echo "  Encryption: ${GREEN}$ENCRYPTION${NC}"
echo ""

# Clean up any decision files
if [[ -f "$SETUP_DIR/DECISION.md" ]]; then
    read -p "Remove DECISION.md? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$SETUP_DIR/DECISION.md"
        echo -e "${GREEN}Removed DECISION.md${NC}"
    fi
fi

echo ""
echo -e "${YELLOW}You can now run simulate-jerry.sh again to practice${NC}"
echo ""
