#!/bin/bash
# Simulate Jerry's rename refactor
#
# This script simulates Jerry "improving" resource names in main.tf
# without updating the state file, creating a dangerous destroy/create scenario.
#
# Usage: ./simulate-jerry.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Jerry is about to 'improve' your resource names...${NC}"
echo ""

# Check we're in the right directory
if [ ! -f "main.tf" ]; then
    echo -e "${RED}Error: main.tf not found.${NC}"
    echo "Run this script from your student-work directory."
    exit 1
fi

# Check infrastructure exists
echo -n "Checking infrastructure deployed... "
if [ ! -d ".terraform" ]; then
    echo -e "${RED}FAILED${NC}"
    echo "   Run 'terraform init' and 'terraform apply' first"
    exit 1
fi

# Verify state has the original resources
STATE_LIST=$(terraform state list 2>/dev/null || echo "")
if ! echo "$STATE_LIST" | grep -q "aws_s3_bucket.bucket1"; then
    echo -e "${RED}FAILED${NC}"
    echo "   Original resources not found in state."
    echo "   Ensure you've run 'terraform apply' to create infrastructure first."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Backup original main.tf
echo -n "Backing up original main.tf... "
cp main.tf main.tf.backup
echo -e "${GREEN}OK${NC}"

echo ""
echo -e "${YELLOW}Jerry is 'improving' the resource names for clarity...${NC}"
echo ""
sleep 1

# Replace bucket1 with application_data
# Replace bucket2 with user_uploads
# Replace random_id.suffix1 with random_id.app_suffix
# Replace random_id.suffix2 with random_id.uploads_suffix

# Create the new main.tf with Jerry's "improvements"
sed -i.tmp \
    -e 's/resource "random_id" "suffix1"/resource "random_id" "app_suffix"/g' \
    -e 's/resource "random_id" "suffix2"/resource "random_id" "uploads_suffix"/g' \
    -e 's/random_id\.suffix1/random_id.app_suffix/g' \
    -e 's/random_id\.suffix2/random_id.uploads_suffix/g' \
    -e 's/resource "aws_s3_bucket" "bucket1"/resource "aws_s3_bucket" "application_data"/g' \
    -e 's/resource "aws_s3_bucket" "bucket2"/resource "aws_s3_bucket" "user_uploads"/g' \
    -e 's/aws_s3_bucket\.bucket1/aws_s3_bucket.application_data/g' \
    -e 's/aws_s3_bucket\.bucket2/aws_s3_bucket.user_uploads/g' \
    -e 's/"bucket1"/"application_data"/g' \
    -e 's/"bucket2"/"user_uploads"/g' \
    main.tf

rm -f main.tf.tmp

# Update comments in the file
sed -i.tmp \
    -e 's/Bucket 1/Application Data Bucket/g' \
    -e 's/Bucket 2/User Uploads Bucket/g' \
    -e 's/Jerry will rename this to "application_data"/Better naming by Jerry/g' \
    -e 's/Jerry will rename this to "user_uploads"/Better naming by Jerry/g' \
    main.tf

rm -f main.tf.tmp

echo -e "${GREEN}Done!${NC} Jerry renamed the resources."
echo ""

# Show what Jerry changed
echo -e "${CYAN}What Jerry changed:${NC}"
echo ""
echo "  Resource Name Changes:"
echo "    aws_s3_bucket.bucket1           → aws_s3_bucket.application_data"
echo "    aws_s3_bucket.bucket2           → aws_s3_bucket.user_uploads"
echo "    random_id.suffix1               → random_id.app_suffix"
echo "    random_id.suffix2               → random_id.uploads_suffix"
echo ""
echo "  Plus all dependent resources (versioning, encryption, public access blocks)"
echo ""

# Show state still has old names
echo -e "${CYAN}Current state addresses (Jerry didn't update these!):${NC}"
terraform state list | grep -E "(bucket|random_id)" | sed 's/^/  /'
echo ""

echo -e "${RED}⚠️  WARNING: STATE DOES NOT MATCH CODE!${NC}"
echo ""
echo "  The state file still has the OLD resource names,"
echo "  but main.tf now has NEW resource names."
echo ""
echo -e "${YELLOW}Now run 'terraform plan' to see the DANGER...${NC}"
echo ""
echo "  Terraform will want to:"
echo "    - DESTROY aws_s3_bucket.bucket1 (and bucket2)"
echo "    - CREATE aws_s3_bucket.application_data (and user_uploads)"
echo ""
echo "  This would DELETE all data in the buckets!"
echo ""
echo -e "${CYAN}Your mission:${NC}"
echo "  Fix the state addressing WITHOUT destroying resources."
echo "  Use either:"
echo "    - terraform state mv (imperative approach)"
echo "    - moved blocks (declarative approach)"
echo ""

# Create jerry manifest for tracking
mkdir -p .jerry
cat > .jerry/manifest.json << EOF
{
    "version": "1.0",
    "exercise": "jerry-08-rename-refactor",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "scenarios": [
        {
            "type": "move",
            "status": "active",
            "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "details": {
                "scenario": "rename",
                "renames": [
                    {
                        "from": "aws_s3_bucket.bucket1",
                        "to": "aws_s3_bucket.application_data"
                    },
                    {
                        "from": "aws_s3_bucket.bucket2",
                        "to": "aws_s3_bucket.user_uploads"
                    },
                    {
                        "from": "random_id.suffix1",
                        "to": "random_id.app_suffix"
                    },
                    {
                        "from": "random_id.suffix2",
                        "to": "random_id.uploads_suffix"
                    }
                ],
                "backup_file": "main.tf.backup"
            }
        }
    ],
    "hints_used": 0,
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "Manifest created at .jerry/manifest.json"
echo "Original main.tf backed up to main.tf.backup"
echo ""
