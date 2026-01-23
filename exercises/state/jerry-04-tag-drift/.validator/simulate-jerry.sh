#!/bin/bash
# Simulate Jerry's tag drift
#
# This script creates the drift scenario by modifying S3 bucket tags
# directly via AWS CLI, simulating what jerry-ctl will do when implemented.
#
# Usage: ./simulate-jerry.sh [bucket-name]
#
# If bucket-name is not provided, it will try to get it from Terraform output.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Jerry is about to mess with your tags...${NC}"
echo ""

# Get bucket name
if [ -n "$1" ]; then
    BUCKET_NAME="$1"
else
    echo "Getting bucket name from Terraform output..."
    BUCKET_NAME=$(terraform output -raw bucket_name 2>/dev/null) || {
        echo -e "${RED}Error: Could not get bucket name.${NC}"
        echo "Either provide bucket name as argument or ensure Terraform has been applied."
        echo ""
        echo "Usage: ./simulate-jerry.sh [bucket-name]"
        exit 1
    }
fi

echo "Target bucket: $BUCKET_NAME"
echo ""

# Verify bucket exists
echo -n "Checking bucket exists... "
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "Bucket does not exist. Run 'terraform apply' first."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Get current tags for display
echo ""
echo "Current tags:"
aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" 2>/dev/null | jq -r '.TagSet[] | "  \(.Key): \(.Value)"' || echo "  (no tags)"

# Jerry's new tags
echo ""
echo -e "${YELLOW}Jerry is making 'quick changes' in the AWS Console...${NC}"
echo ""
sleep 1

# Apply Jerry's tag changes
# - Change Environment from "Learning" to "Production"
# - Add CostCenter = "JERRY-FIXME"
# - Remove ManagedBy tag
aws s3api put-bucket-tagging --bucket "$BUCKET_NAME" --tagging '{
    "TagSet": [
        {"Key": "Name", "Value": "Company Data Bucket"},
        {"Key": "Environment", "Value": "Production"},
        {"Key": "CostCenter", "Value": "JERRY-FIXME"}
    ]
}'

echo -e "${GREEN}Done!${NC} Jerry changed the tags."
echo ""

# Show new tags
echo "New tags (after Jerry):"
aws s3api get-bucket-tagging --bucket "$BUCKET_NAME" | jq -r '.TagSet[] | "  \(.Key): \(.Value)"'

echo ""
echo -e "${CYAN}What Jerry changed:${NC}"
echo "  - Environment: Learning → Production"
echo "  - CostCenter: (added) JERRY-FIXME"
echo "  - ManagedBy: (removed)"
echo ""
echo -e "${YELLOW}Now run 'terraform plan' to see the drift!${NC}"
echo ""

# Create jerry manifest for tracking (simple version)
mkdir -p .jerry
cat > .jerry/manifest.json << EOF
{
    "version": "1.0",
    "exercise": "jerry-04-tag-drift",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "scenarios": [
        {
            "type": "drift",
            "status": "active",
            "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "details": {
                "scenario": "tags",
                "resource": "aws_s3_bucket.data",
                "bucket": "$BUCKET_NAME",
                "changes": {
                    "add": {"CostCenter": "JERRY-FIXME"},
                    "modify": {"Environment": "Production"},
                    "remove": ["ManagedBy"]
                }
            }
        }
    ],
    "hints_used": 0,
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "Manifest created at .jerry/manifest.json"
