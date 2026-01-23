#!/bin/bash
# Simulate Jerry's CI/CD pipeline crash with stale S3 lock
#
# This script creates a stale .tflock file in S3, simulating what happens
# when a CI/CD pipeline (GitHub Actions) crashes mid-apply.
#
# Usage: ./simulate-jerry.sh [state-bucket]
#
# If state-bucket is not provided, it will try to get it from terraform.tfvars

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Jerry's CI/CD pipeline is about to crash...${NC}"
echo ""

# Get state bucket name
if [ -n "$1" ]; then
    STATE_BUCKET="$1"
else
    echo "Getting state bucket from terraform.tfvars..."
    STATE_BUCKET=$(grep '^state_bucket' terraform.tfvars 2>/dev/null | awk '{print $3}' | tr -d '"') || {
        echo -e "${RED}Error: Could not find state_bucket in terraform.tfvars${NC}"
        echo "Either provide bucket name as argument or ensure terraform.tfvars exists."
        echo ""
        echo "Usage: ./simulate-jerry.sh [state-bucket-name]"
        exit 1
    }
fi

if [ -z "$STATE_BUCKET" ]; then
    echo -e "${RED}Error: state_bucket is empty${NC}"
    echo "Check your terraform.tfvars file."
    exit 1
fi

echo "State bucket: $STATE_BUCKET"
echo ""

# Define S3 paths
STATE_KEY="gym/state/jerry-02-remote-lock/terraform.tfstate"
LOCK_KEY="${STATE_KEY}.tflock"
S3_STATE_PATH="s3://${STATE_BUCKET}/${STATE_KEY}"
S3_LOCK_PATH="s3://${STATE_BUCKET}/${LOCK_KEY}"

# Verify state bucket exists
echo -n "Checking state bucket exists... "
if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "State bucket does not exist: $STATE_BUCKET"
    echo "Create it or use an existing state bucket."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Verify state file exists
echo -n "Checking state file exists... "
if ! aws s3api head-object --bucket "$STATE_BUCKET" --key "$STATE_KEY" &>/dev/null; then
    echo -e "${RED}FAILED${NC}"
    echo "State file not found: $S3_STATE_PATH"
    echo "Run 'terraform init -backend-config=\"bucket=$STATE_BUCKET\"' and 'terraform apply' first."
    exit 1
fi
echo -e "${GREEN}OK${NC}"

# Check if lock already exists
echo -n "Checking for existing lock... "
if aws s3api head-object --bucket "$STATE_BUCKET" --key "$LOCK_KEY" &>/dev/null; then
    echo -e "${YELLOW}FOUND${NC}"
    echo "Lock already exists. Remove it first with:"
    echo "  aws s3 rm $S3_LOCK_PATH"
    echo ""
    read -p "Remove existing lock and continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
    aws s3 rm "$S3_LOCK_PATH"
    echo "Existing lock removed."
fi
echo -e "${GREEN}OK${NC} - No lock exists"

echo ""
echo -e "${YELLOW}Simulating CI/CD pipeline crash...${NC}"
echo ""
sleep 1

# Generate a lock ID (UUID v4)
LOCK_ID=$(cat /proc/sys/kernel/random/uuid)

# Create timestamp 4 hours ago (stale lock)
LOCK_CREATED=$(date -u -d '4 hours ago' '+%Y-%m-%dT%H:%M:%S.000000Z' 2>/dev/null || date -u -v-4H '+%Y-%m-%dT%H:%M:%S.000000Z')

# Create lock file content
LOCK_CONTENT=$(cat <<EOF
{
  "ID": "$LOCK_ID",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "github-actions@ci-runner-12345",
  "Version": "1.9.0",
  "Created": "$LOCK_CREATED",
  "Path": "$STATE_KEY"
}
EOF
)

# Write lock file to S3
echo "$LOCK_CONTENT" | aws s3 cp - "$S3_LOCK_PATH" --content-type "application/json"

echo -e "${GREEN}Done!${NC} Lock file created in S3."
echo ""

# Verify lock file exists
echo "Lock file location:"
echo "  $S3_LOCK_PATH"
echo ""

# Show lock details
echo "Lock details:"
echo "$LOCK_CONTENT" | jq .
echo ""

echo -e "${CYAN}What happened:${NC}"
echo "  - CI/CD pipeline started: terraform apply"
echo "  - Lock created: $LOCK_CREATED"
echo "  - Pipeline runner terminated unexpectedly"
echo "  - Lock left behind in S3"
echo "  - Lock ID: $LOCK_ID"
echo ""

echo -e "${YELLOW}Now try running 'terraform plan' - you'll see a lock error!${NC}"
echo ""
echo "To inspect the lock:"
echo "  aws s3 cp $S3_LOCK_PATH - | jq ."
echo ""
echo "To list S3 contents:"
echo "  aws s3 ls s3://${STATE_BUCKET}/gym/state/jerry-02-remote-lock/"
echo ""

# Create jerry manifest for tracking
mkdir -p .jerry
cat > .jerry/manifest.json << EOF
{
    "version": "1.0",
    "exercise": "jerry-02-remote-lock",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "scenarios": [
        {
            "type": "lock",
            "status": "active",
            "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "details": {
                "backend": "s3",
                "lock_type": "native",
                "lock_id": "$LOCK_ID",
                "lock_path": "$S3_LOCK_PATH",
                "state_bucket": "$STATE_BUCKET",
                "state_key": "$STATE_KEY",
                "who": "github-actions@ci-runner-12345",
                "created": "$LOCK_CREATED"
            }
        }
    ],
    "hints_used": 0,
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "Manifest created at .jerry/manifest.json"
echo ""
echo -e "${CYAN}Good luck! You'll need to unlock the state to continue.${NC}"
