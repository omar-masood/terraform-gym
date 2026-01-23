#!/bin/bash
set -e

# Jerry-07: Deleted Resource - Reset Script
# Cleans up AWS resources and local files to start fresh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")/setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Jerry-07: Deleted Resource - Reset                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This will:${NC}"
echo "1. Destroy all AWS resources (S3 buckets)"
echo "2. Clean up Terraform state files"
echo "3. Remove .terraform directory"
echo ""
echo -e "${RED}Warning: This will delete AWS resources!${NC}"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Reset cancelled."
    exit 0
fi

echo ""

cd "$SETUP_DIR"

# Try to destroy using Terraform first
echo -e "${BLUE}Step 1: Destroying infrastructure with Terraform${NC}"
if [ -d ".terraform" ]; then
    if terraform destroy -auto-approve 2>/dev/null; then
        echo -e "${GREEN}✓ Infrastructure destroyed via Terraform${NC}"
    else
        echo -e "${YELLOW}⚠ Terraform destroy had issues, will clean up manually${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Terraform not initialized, skipping destroy${NC}"
fi
echo ""

# Manual cleanup of any remaining buckets
echo -e "${BLUE}Step 2: Cleaning up any remaining S3 buckets${NC}"

# List buckets that match our pattern
BUCKETS=$(aws s3 ls | awk '{print $3}' | grep -E "(app-data|old-logs)-[a-f0-9]{8}" || echo "")

if [ -n "$BUCKETS" ]; then
    echo "Found buckets to clean up:"
    echo "$BUCKETS" | sed 's/^/  /'
    echo ""

    for BUCKET in $BUCKETS; do
        echo "Deleting bucket: $BUCKET"
        # Empty bucket first
        aws s3 rm "s3://${BUCKET}" --recursive 2>/dev/null || true
        # Delete bucket
        aws s3 rb "s3://${BUCKET}" --force 2>/dev/null || \
            aws s3api delete-bucket --bucket "$BUCKET" 2>/dev/null || true
    done
    echo -e "${GREEN}✓ Buckets cleaned up${NC}"
else
    echo -e "${YELLOW}⚠ No buckets found to clean up${NC}"
fi
echo ""

# Clean up Terraform files
echo -e "${BLUE}Step 3: Cleaning up Terraform files${NC}"

if [ -d ".terraform" ]; then
    rm -rf .terraform
    echo -e "${GREEN}✓ Removed .terraform directory${NC}"
fi

if [ -f "terraform.tfstate" ]; then
    rm -f terraform.tfstate
    echo -e "${GREEN}✓ Removed terraform.tfstate${NC}"
fi

if [ -f "terraform.tfstate.backup" ]; then
    rm -f terraform.tfstate.backup
    echo -e "${GREEN}✓ Removed terraform.tfstate.backup${NC}"
fi

if [ -f ".terraform.lock.hcl" ]; then
    rm -f .terraform.lock.hcl
    echo -e "${GREEN}✓ Removed .terraform.lock.hcl${NC}"
fi

if [ -f "terraform.tfvars" ]; then
    rm -f terraform.tfvars
    echo -e "${GREEN}✓ Removed terraform.tfvars${NC}"
fi

echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Reset Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}To start the exercise again:${NC}"
echo "1. Run: ../.validator/simulate-jerry.sh"
echo "2. Follow the exercise instructions in README.md"
echo ""
