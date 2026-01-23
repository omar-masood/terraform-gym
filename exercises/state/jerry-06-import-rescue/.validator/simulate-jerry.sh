#!/bin/bash
# Simulate Jerry's manual bucket creation
#
# This script creates an S3 bucket via AWS CLI (not Terraform),
# simulating what Jerry did in the console. The student must then
# discover and import this bucket.
#
# Usage: ./simulate-jerry.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🏖️  Jerry is creating infrastructure in the AWS Console...${NC}"
echo ""
echo "  'I just need this for quick testing!'"
echo "  'I'll add it to Terraform later...'"
echo ""

# Generate random suffix for unique bucket name
RANDOM_SUFFIX=$(openssl rand -hex 3)
BUCKET_NAME="jerry-prod-data-${RANDOM_SUFFIX}"

# Get AWS region from terraform.tfvars or use default
if [ -f "terraform.tfvars" ]; then
    AWS_REGION=$(grep aws_region terraform.tfvars | cut -d'"' -f2 || echo "us-east-1")
else
    AWS_REGION="us-east-1"
fi

echo -e "${YELLOW}Creating S3 bucket: ${BUCKET_NAME}${NC}"
echo "Region: ${AWS_REGION}"
echo ""

# Create the bucket
if [ "$AWS_REGION" = "us-east-1" ]; then
    # us-east-1 doesn't need LocationConstraint
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" 2>&1 | grep -v "Location" || true
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION" 2>&1 | grep -v "Location" || true
fi

echo -e "${GREEN}✓${NC} Bucket created"

# Add Jerry's tags
echo -n "Adding Jerry's tags... "
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {"Key": "CreatedBy", "Value": "jerry"},
            {"Key": "Purpose", "Value": "testing"},
            {"Key": "Department", "Value": "engineering"}
        ]
    }'
echo -e "${GREEN}✓${NC}"

# Enable versioning (because Jerry thought it was a good idea)
echo -n "Enabling versioning... "
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled
echo -e "${GREEN}✓${NC}"

# Put some "test data" in the bucket
echo -n "Adding 'test' data... "
echo "Jerry's test file - now it's production!" > /tmp/jerry-test.txt
aws s3 cp /tmp/jerry-test.txt "s3://${BUCKET_NAME}/test-data.txt" --quiet
rm /tmp/jerry-test.txt
echo -e "${GREEN}✓${NC}"

echo ""
echo -e "${GREEN}✅ Jerry's bucket is ready!${NC}"
echo ""

# Save bucket name for validation
mkdir -p .jerry
echo "$BUCKET_NAME" > .jerry/bucket-name.txt

# Create manifest
cat > .jerry/manifest.json << EOF
{
    "version": "1.0",
    "exercise": "jerry-06-import-rescue",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "scenarios": [
        {
            "type": "manual-creation",
            "status": "active",
            "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "details": {
                "scenario": "manual-bucket",
                "bucket_name": "$BUCKET_NAME",
                "region": "$AWS_REGION",
                "configuration": {
                    "versioning": "Enabled",
                    "tags": {
                        "CreatedBy": "jerry",
                        "Purpose": "testing",
                        "Department": "engineering"
                    }
                }
            }
        }
    ],
    "hints_used": 0,
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

# Show what was created
echo -e "${CYAN}📋 What Jerry created:${NC}"
echo ""
echo "  Bucket Name: ${BUCKET_NAME}"
echo "  Region:      ${AWS_REGION}"
echo "  Versioning:  Enabled"
echo "  Tags:"
echo "    - CreatedBy: jerry"
echo "    - Purpose: testing"
echo "    - Department: engineering"
echo "  Contents:    1 test file"
echo ""
echo -e "${CYAN}📝 What Jerry DIDN'T do (security gaps):${NC}"
echo "  - No encryption configured"
echo "  - No public access block"
echo "  - No lifecycle policies"
echo ""
echo -e "${YELLOW}💡 Your mission:${NC}"
echo ""
echo "  1. Find Jerry's bucket:"
echo "     ${CYAN}aws s3 ls | grep jerry${NC}"
echo ""
echo "  2. Inspect its configuration:"
echo "     ${CYAN}aws s3api get-bucket-tagging --bucket ${BUCKET_NAME}${NC}"
echo "     ${CYAN}aws s3api get-bucket-versioning --bucket ${BUCKET_NAME}${NC}"
echo ""
echo "  3. Write Terraform config to match it"
echo ""
echo "  4. Import the bucket:"
echo "     ${CYAN}terraform import aws_s3_bucket.jerry_bucket ${BUCKET_NAME}${NC}"
echo "     ${CYAN}terraform import aws_s3_bucket_versioning.jerry_bucket ${BUCKET_NAME}${NC}"
echo ""
echo "  5. Verify:"
echo "     ${CYAN}terraform plan${NC} (should show no changes)"
echo ""
echo -e "${GREEN}Good luck! 🚀${NC}"
echo ""
