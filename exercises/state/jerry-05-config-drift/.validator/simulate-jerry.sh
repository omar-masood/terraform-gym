#!/bin/bash
#
# simulate-jerry.sh
# Simulates Jerry's "cost optimization" by disabling S3 bucket versioning
# and encryption via AWS CLI (mimicking Console changes)
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
echo -e "${BLUE}  Jerry's Cost Optimization Script 💰${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if we're in a Terraform directory
if [[ ! -f "$SETUP_DIR/main.tf" ]]; then
    echo -e "${RED}Error: Cannot find setup/main.tf${NC}"
    echo "Run this script from the jerry-05-config-drift directory"
    exit 1
fi

# Check if Terraform is initialized
if [[ ! -d "$SETUP_DIR/.terraform" ]]; then
    echo -e "${YELLOW}Warning: Terraform not initialized${NC}"
    echo "Please run: cd setup && terraform init && terraform apply"
    exit 1
fi

# Get bucket name from Terraform output
cd "$SETUP_DIR"
BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null || true)

if [[ -z "$BUCKET_NAME" ]]; then
    echo -e "${RED}Error: Cannot get bucket name from Terraform${NC}"
    echo "Please run: terraform apply first"
    exit 1
fi

echo -e "${YELLOW}Target bucket: $BUCKET_NAME${NC}"
echo ""

# Check current configuration
echo -e "${BLUE}Current bucket configuration:${NC}"
echo -n "  Versioning: "
CURRENT_VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "Not configured")
echo -e "${GREEN}$CURRENT_VERSIONING${NC}"

echo -n "  Encryption: "
CURRENT_ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "Not configured")
echo -e "${GREEN}$CURRENT_ENCRYPTION${NC}"
echo ""

# Simulate Jerry's changes
echo -e "${YELLOW}Jerry's thought process:${NC}"
echo "  💭 'Hmm, versioning is storing multiple copies of every object...'"
echo "  💭 'That's gotta be expensive! And encryption adds overhead...'"
echo "  💭 'I'll just turn these off real quick to save costs!'"
echo ""

sleep 2

echo -e "${RED}Simulating Jerry's AWS Console changes...${NC}"
echo ""

# Disable versioning (suspend, not disable completely)
echo -n "  [1/2] Suspending bucket versioning... "
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Suspended \
    >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Done${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    exit 1
fi

# Delete encryption configuration
echo -n "  [2/2] Removing server-side encryption... "
aws s3api delete-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✓ Done${NC}"
else
    echo -e "${RED}✗ Failed${NC}"
    exit 1
fi

echo ""

# Verify changes
echo -e "${BLUE}New bucket configuration:${NC}"
echo -n "  Versioning: "
NEW_VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null || echo "Not configured")
echo -e "${RED}$NEW_VERSIONING${NC}"

echo -n "  Encryption: "
NEW_ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null || echo "Not configured")
echo -e "${RED}$NEW_ENCRYPTION${NC}"
echo ""

# Jerry's message
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Jerry's Slack Message (9:47 PM):${NC}"
echo -e "${YELLOW}========================================${NC}"
cat << 'EOF'

Hey team! 👋 I noticed our S3 bucket was getting expensive
with all that versioning enabled. Also the encryption was
slowing down uploads. I went ahead and disabled both via
the AWS Console to optimize for cost and performance.

Bucket is running MUCH faster now! 💰⚡

You're welcome! 😎

EOF
echo -e "${YELLOW}========================================${NC}"
echo ""

# Warning about what happened
echo -e "${RED}⚠️  WHAT JUST HAPPENED:${NC}"
echo ""
echo -e "${RED}✗${NC} Versioning: Enabled → Suspended"
echo "    • New objects won't be versioned"
echo "    • Existing versions still exist (for now)"
echo "    • Can't recover if accidentally deleted"
echo ""
echo -e "${RED}✗${NC} Encryption: AES256 → None"
echo "    • New objects won't be encrypted at rest"
echo "    • Existing objects keep their encryption"
echo "    • May violate compliance requirements"
echo ""

# Next steps
echo -e "${GREEN}NEXT STEPS:${NC}"
echo ""
echo "1. Run terraform plan and READ it carefully:"
echo "   ${BLUE}cd setup && terraform plan${NC}"
echo ""
echo "2. Assess the security and compliance implications"
echo ""
echo "3. Choose your response:"
echo "   ${GREEN}Option A:${NC} Re-enable security features (terraform apply)"
echo "   ${RED}Option B:${NC} Accept reduced security (update Terraform config)"
echo ""
echo "4. Document your decision in DECISION.md"
echo ""
echo "5. Verify with: ${BLUE}terraform plan${NC} (should show no changes)"
echo ""

echo -e "${YELLOW}Remember: Not all drift is equal. Configuration drift is${NC}"
echo -e "${YELLOW}more dangerous than tag drift!${NC}"
echo ""
