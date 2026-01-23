#!/bin/bash
# Simulate Jerry's stale lock
#
# This script creates a stale local lock file, simulating what happens
# when Jerry's laptop locks or his process crashes during an apply.
#
# Usage: ./simulate-jerry.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔧 Jerry is about to abandon a terraform apply...${NC}"
echo ""

# Check we're in the right directory
if [ ! -d ".terraform" ]; then
    echo -e "${RED}Error: Terraform not initialized.${NC}"
    echo "Run 'terraform init' first"
    exit 1
fi

# Check if lock already exists
if [ -f ".terraform.tfstate.lock.info" ]; then
    echo -e "${YELLOW}Warning: Lock file already exists.${NC}"
    echo "Removing old lock..."
    rm -f .terraform.tfstate.lock.info
fi

echo -e "${YELLOW}Jerry is running 'terraform apply' on his laptop...${NC}"
sleep 1
echo "Jerry's laptop is locked! He went to lunch..."
sleep 1
echo ""

# Generate a realistic UUID for the lock ID
LOCK_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "a1b2c3d4-e5f6-7890-abcd-ef1234567890")

# Create timestamp (2 hours ago)
LOCK_TIME=$(date -u -d '2 hours ago' '+%Y-%m-%dT%H:%M:%S.%NZ' 2>/dev/null || date -u -v-2H '+%Y-%m-%dT%H:%M:%S.000000000Z' 2>/dev/null || echo "2025-01-15T10:30:00.000000000Z")

# Create the lock file
cat > .terraform.tfstate.lock.info << EOF
{
  "ID": "$LOCK_ID",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "jerry@jerrys-macbook",
  "Version": "1.9.0",
  "Created": "$LOCK_TIME",
  "Path": "terraform.tfstate"
}
EOF

echo -e "${GREEN}Done!${NC} Jerry's stale lock has been created."
echo ""

# Show the lock file
echo "Lock file created: .terraform.tfstate.lock.info"
echo ""
echo "Lock details:"
cat .terraform.tfstate.lock.info | grep -v '^{' | grep -v '^}' | sed 's/^/  /'
echo ""

echo -e "${RED}⚠️  STATE IS LOCKED!${NC}"
echo ""
echo "  Jerry started an apply but his laptop is locked."
echo "  The lock has been sitting there for 2 hours."
echo ""
echo -e "${YELLOW}Now try to run 'terraform plan'...${NC}"
echo ""
echo "  You'll get an error about the state lock."
echo ""
echo -e "${CYAN}Your mission:${NC}"
echo "  Safely unlock the state so you can proceed with your work."
echo "  Remember: Jerry's apply never completed, so it's safe to force unlock."
echo ""

# Create jerry manifest for tracking
mkdir -p .jerry
cat > .jerry/manifest.json << EOF
{
    "version": "1.0",
    "exercise": "jerry-01-stale-lock",
    "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "scenarios": [
        {
            "type": "lock",
            "status": "active",
            "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
            "details": {
                "backend": "local",
                "lock_id": "$LOCK_ID",
                "lock_file": ".terraform.tfstate.lock.info",
                "who": "jerry@jerrys-macbook",
                "age_hours": 2,
                "operation": "OperationTypeApply"
            }
        }
    ],
    "hints_used": 0,
    "start_time": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "Manifest created at .jerry/manifest.json"
echo ""
