#!/bin/bash
set -e

# Jerry-07: Deleted Resource - Simulation Script
# This script creates infrastructure and then simulates Jerry deleting a bucket

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_DIR="$(dirname "$SCRIPT_DIR")/setup"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Jerry-07: Deleted Resource - Simulation                 ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Scenario Setup:${NC}"
echo "1. Create infrastructure with Terraform (2 S3 buckets)"
echo "2. Simulate Jerry deleting the 'old_logs' bucket via AWS Console"
echo "3. Leave the bucket in Terraform state (creating the problem)"
echo ""
echo -e "${YELLOW}After this runs:${NC}"
echo "- app_data bucket will exist (working normally)"
echo "- old_logs bucket will be DELETED from AWS"
echo "- old_logs bucket will still be IN STATE"
echo "- terraform plan will want to CREATE old_logs"
echo ""

# Check prerequisites
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Error: Terraform is not installed${NC}"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites check passed${NC}"
echo ""

# Change to setup directory
cd "$SETUP_DIR"

# Initialize Terraform
echo -e "${BLUE}Step 1: Initializing Terraform${NC}"
terraform init > /dev/null 2>&1
echo -e "${GREEN}✓ Terraform initialized${NC}"
echo ""

# Create infrastructure
echo -e "${BLUE}Step 2: Creating infrastructure with Terraform${NC}"
echo "This will create:"
echo "  - app_data S3 bucket (will stay)"
echo "  - old_logs S3 bucket (Jerry will delete this)"
echo ""

terraform apply -auto-approve

echo ""
echo -e "${GREEN}✓ Infrastructure created${NC}"
echo ""

# Get bucket names from state
echo -e "${BLUE}Step 3: Getting bucket names from Terraform state${NC}"
APP_BUCKET=$(terraform output -raw app_data_bucket 2>/dev/null || echo "")
OLD_LOGS_BUCKET=$(terraform output -raw old_logs_bucket 2>/dev/null || echo "")

if [ -z "$APP_BUCKET" ] || [ -z "$OLD_LOGS_BUCKET" ]; then
    echo -e "${RED}Error: Could not get bucket names from outputs${NC}"
    exit 1
fi

echo "  app_data bucket: ${APP_BUCKET}"
echo "  old_logs bucket: ${OLD_LOGS_BUCKET}"
echo -e "${GREEN}✓ Bucket names retrieved${NC}"
echo ""

# Verify buckets exist
echo -e "${BLUE}Step 4: Verifying buckets exist in AWS${NC}"
if aws s3api head-bucket --bucket "$APP_BUCKET" 2>/dev/null; then
    echo -e "${GREEN}✓ app_data bucket exists${NC}"
else
    echo -e "${RED}✗ app_data bucket not found${NC}"
    exit 1
fi

if aws s3api head-bucket --bucket "$OLD_LOGS_BUCKET" 2>/dev/null; then
    echo -e "${GREEN}✓ old_logs bucket exists${NC}"
else
    echo -e "${RED}✗ old_logs bucket not found${NC}"
    exit 1
fi
echo ""

# Simulate Jerry's deletion
echo -e "${BLUE}Step 5: Simulating Jerry's manual deletion${NC}"
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Jerry's Internal Monologue:                              ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  'Hmm, this old_logs bucket isn't being used anymore...'"
echo "  'It's tagged as deprecated and legacy...'"
echo "  'We should clean up unused resources to save costs.'"
echo "  'I'll just delete it real quick via the AWS console.'"
echo "  'No need to bother the team about this small cleanup.'"
echo ""
echo -e "${YELLOW}  *clicks delete in AWS Console*${NC}"
echo ""
echo -e "${YELLOW}  'There we go! One less bucket to worry about.'${NC}"
echo -e "${YELLOW}  'Better send a message to the team so they know.'${NC}"
echo ""
echo -e "${YELLOW}════════════════════════════════════════════════════════════${NC}"
echo ""

echo "Deleting ${OLD_LOGS_BUCKET} via AWS CLI (simulating console deletion)..."
aws s3 rb "s3://${OLD_LOGS_BUCKET}" --force 2>/dev/null || \
    aws s3api delete-bucket --bucket "$OLD_LOGS_BUCKET" 2>/dev/null

# Verify deletion
if aws s3api head-bucket --bucket "$OLD_LOGS_BUCKET" 2>/dev/null; then
    echo -e "${RED}✗ Bucket still exists (deletion failed)${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Bucket deleted from AWS${NC}"
fi
echo ""

# Show state still has it
echo -e "${BLUE}Step 6: Checking Terraform state${NC}"
echo "Resources in state:"
terraform state list
echo ""

if terraform state list | grep -q "aws_s3_bucket.old_logs"; then
    echo -e "${YELLOW}⚠ Notice: old_logs is STILL IN STATE even though it's deleted from AWS!${NC}"
else
    echo -e "${RED}✗ Unexpected: old_logs not in state${NC}"
    exit 1
fi
echo ""

# Show what terraform plan will say
echo -e "${BLUE}Step 7: Running terraform plan to see the problem${NC}"
echo ""
terraform plan -no-color | head -n 30
echo ""
echo -e "${YELLOW}Notice the '+' symbol: Terraform wants to CREATE the bucket${NC}"
echo -e "${YELLOW}This is because:${NC}"
echo -e "${YELLOW}  - State says: 'I manage aws_s3_bucket.old_logs'${NC}"
echo -e "${YELLOW}  - AWS says: 'No such bucket exists'${NC}"
echo -e "${YELLOW}  - Terraform says: 'I better create it then!'${NC}"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Simulation Complete!                                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}What just happened:${NC}"
echo "✓ Created 2 S3 buckets with Terraform"
echo "✓ Jerry manually deleted old_logs bucket via 'AWS Console'"
echo "✓ Bucket is gone from AWS but still in Terraform state"
echo "✓ terraform plan wants to recreate the deleted bucket"
echo ""
echo -e "${YELLOW}The Problem:${NC}"
echo "State and reality don't match!"
echo "  State: aws_s3_bucket.old_logs exists"
echo "  AWS:   No such bucket"
echo ""
echo -e "${YELLOW}Your Mission:${NC}"
echo "You need to decide what to do:"
echo ""
echo -e "${BLUE}Option A: Remove from state${NC} (if Jerry was right to delete it)"
echo "  terraform state rm aws_s3_bucket.old_logs"
echo "  terraform plan  # Should show no changes"
echo ""
echo -e "${BLUE}Option B: Let Terraform recreate it${NC} (if we actually need the bucket)"
echo "  terraform apply"
echo "  terraform plan  # Should show no changes"
echo ""
echo -e "${YELLOW}Hint:${NC} The bucket was called 'old_logs', tagged as 'deprecated'"
echo "      and 'legacy', and Jerry said it 'wasn't being used anymore.'"
echo "      What do you think - should it be recreated?"
echo ""
echo -e "${YELLOW}To validate your solution:${NC}"
echo "  ../.validator/validate.sh"
echo ""
echo -e "${YELLOW}To reset and try again:${NC}"
echo "  ../.validator/reset.sh"
echo ""
