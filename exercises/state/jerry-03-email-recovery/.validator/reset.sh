#!/bin/bash
set -e

# Jerry-03: Email Recovery - Reset Script
# Cleans up AWS resources and local files to start fresh

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
echo -e "${BLUE}║   Jerry-03: Email Recovery - Reset                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}This will:${NC}"
echo "1. Destroy AWS resources (S3 bucket)"
echo "2. Clean up Terraform state files"
echo "3. Remove generated configuration files"
echo "4. Reset jerry-backup.tfstate to template"
echo ""
echo -e "${RED}Warning: This will delete AWS resources!${NC}"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Reset cancelled."
    exit 0
fi

echo ""

# Extract bucket name from state file or terraform.tfvars
BUCKET_NAME=""

if [ -f "$SETUP_DIR/terraform.tfvars" ]; then
    BUCKET_NAME=$(grep "bucket_name" "$SETUP_DIR/terraform.tfvars" | awk -F'"' '{print $2}' || echo "")
fi

if [ -z "$BUCKET_NAME" ] && [ -f "$SETUP_DIR/terraform.tfstate" ]; then
    BUCKET_NAME=$(grep -o '"bucket": "[^"]*"' "$SETUP_DIR/terraform.tfstate" | head -1 | awk -F'"' '{print $4}')
fi

if [ -z "$BUCKET_NAME" ] && [ -f "$EXERCISE_DIR/jerry-backup.tfstate" ]; then
    BUCKET_NAME=$(grep -o '"bucket": "[^"]*"' "$EXERCISE_DIR/jerry-backup.tfstate" | head -1 | awk -F'"' '{print $4}')
fi

# Delete S3 bucket if found
if [ -n "$BUCKET_NAME" ] && [ "$BUCKET_NAME" != "BUCKET_NAME_PLACEHOLDER" ]; then
    echo -e "${BLUE}Step 1: Deleting S3 bucket: ${BUCKET_NAME}${NC}"

    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        # Empty bucket first (required before deletion)
        echo "  Emptying bucket..."
        aws s3 rm "s3://${BUCKET_NAME}" --recursive 2>/dev/null || true

        # Delete bucket
        echo "  Deleting bucket..."
        aws s3api delete-bucket --bucket "$BUCKET_NAME" 2>/dev/null || true

        echo -e "${GREEN}✓ Bucket deleted${NC}"
    else
        echo -e "${YELLOW}⚠ Bucket doesn't exist or already deleted${NC}"
    fi
else
    echo -e "${YELLOW}⚠ No bucket name found, skipping AWS cleanup${NC}"
fi
echo ""

# Clean up Terraform files in setup/
echo -e "${BLUE}Step 2: Cleaning up Terraform files${NC}"
cd "$SETUP_DIR"

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

# Reset jerry-backup.tfstate to template
echo -e "${BLUE}Step 3: Resetting jerry-backup.tfstate to template${NC}"
cat > "$EXERCISE_DIR/jerry-backup.tfstate" << 'EOF'
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 5,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "bucket_name": {
      "value": "BUCKET_NAME_PLACEHOLDER",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_s3_bucket",
      "name": "important_data",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "bucket": "BUCKET_NAME_PLACEHOLDER",
            "id": "BUCKET_NAME_PLACEHOLDER",
            "arn": "arn:aws:s3:::BUCKET_NAME_PLACEHOLDER",
            "region": "us-east-1",
            "tags": {
              "Name": "Jerry Important Data",
              "Owner": "jerry",
              "Environment": "production"
            },
            "tags_all": {
              "Name": "Jerry Important Data",
              "Owner": "jerry",
              "Environment": "production",
              "Exercise": "jerry-03-email-recovery",
              "Track": "jerry",
              "Category": "state",
              "ManagedBy": "terraform"
            }
          }
        }
      ]
    },
    {
      "mode": "managed",
      "type": "aws_s3_bucket_versioning",
      "name": "important_data",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "bucket": "BUCKET_NAME_PLACEHOLDER",
            "id": "BUCKET_NAME_PLACEHOLDER",
            "versioning_configuration": [
              {
                "status": "Enabled",
                "mfa_delete": ""
              }
            ]
          },
          "dependencies": [
            "aws_s3_bucket.important_data"
          ]
        }
      ]
    }
  ],
  "check_results": null
}
EOF

echo -e "${GREEN}✓ Reset jerry-backup.tfstate to template${NC}"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Reset Complete!                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}To start the exercise again:${NC}"
echo "1. Run: ../.validator/simulate-jerry.sh"
echo "2. Follow the exercise instructions in README.md"
echo ""
