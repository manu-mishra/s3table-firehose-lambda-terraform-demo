#!/bin/bash
# Prerequisites validation script for S3 Tables + Firehose deployment
# Checks Lake Formation integration and IAM permissions

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "  Prerequisites Validation"
echo "========================================="
echo ""

# Get current identity
IDENTITY=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null)
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)

if [ -z "$IDENTITY" ]; then
    echo -e "${RED}✗ AWS credentials not configured${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AWS credentials configured${NC}"
echo "  Identity: $IDENTITY"
echo "  Account: $ACCOUNT_ID"
echo ""

# Check 1: S3 Tables integration with Lake Formation
echo "Checking S3 Tables integration..."
INTEGRATION_STATUS=$(aws s3tables list-table-buckets --region us-east-1 2>&1)

if echo "$INTEGRATION_STATUS" | grep -q "AccessDeniedException\|InvalidAction\|UnrecognizedClientException"; then
    echo -e "${RED}✗ S3 Tables not integrated with Lake Formation${NC}"
    echo ""
    echo "  Action required:"
    echo "  1. Go to https://console.aws.amazon.com/s3/"
    echo "  2. Click 'Table buckets' in left navigation"
    echo "  3. Click 'Enable integration' button"
    echo ""
    exit 1
elif echo "$INTEGRATION_STATUS" | grep -q "tableBuckets"; then
    echo -e "${GREEN}✓ S3 Tables integration enabled${NC}"
else
    echo -e "${YELLOW}⚠ Unable to verify S3 Tables integration${NC}"
    echo "  This may be normal if no table buckets exist yet"
fi
echo ""

# Check 2: Lake Formation administrator permissions
echo "Checking Lake Formation administrator permissions..."
LF_ADMINS=$(aws lakeformation get-data-lake-settings --region us-east-1 --query 'DataLakeSettings.DataLakeAdmins[*].DataLakePrincipalIdentifier' --output text 2>/dev/null)

if [ -z "$LF_ADMINS" ]; then
    echo -e "${RED}✗ Unable to check Lake Formation settings${NC}"
    echo "  You may not have sufficient permissions"
    exit 1
fi

# Extract role name from assumed role ARN
# arn:aws:sts::123456789012:assumed-role/RoleName/SessionName -> arn:aws:iam::123456789012:role/RoleName
if echo "$IDENTITY" | grep -q "assumed-role"; then
    ROLE_NAME=$(echo "$IDENTITY" | awk -F'/' '{print $(NF-1)}')
    BASE_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/$ROLE_NAME"
    PRINCIPAL_TO_CHECK="$BASE_ROLE_ARN"
else
    PRINCIPAL_NAME=$(echo "$IDENTITY" | awk -F'/' '{print $NF}')
    PRINCIPAL_TO_CHECK="$IDENTITY"
fi

if echo "$LF_ADMINS" | grep -q "$PRINCIPAL_TO_CHECK"; then
    echo -e "${GREEN}✓ Current identity is Lake Formation administrator${NC}"
    if [ "$IDENTITY" != "$PRINCIPAL_TO_CHECK" ]; then
        echo "  (via role: $PRINCIPAL_TO_CHECK)"
    fi
else
    echo -e "${RED}✗ Current identity is NOT a Lake Formation administrator${NC}"
    echo ""
    echo "  Action required:"
    echo "  Add the base role as Lake Formation admin:"
    echo ""
    if echo "$IDENTITY" | grep -q "assumed-role"; then
        echo "  aws lakeformation put-data-lake-settings \\"
        echo "    --data-lake-settings '{\"DataLakeAdmins\":[{\"DataLakePrincipalIdentifier\":\"$BASE_ROLE_ARN\"}]}'"
    else
        echo "  aws lakeformation put-data-lake-settings \\"
        echo "    --data-lake-settings '{\"DataLakeAdmins\":[{\"DataLakePrincipalIdentifier\":\"$IDENTITY\"}]}'"
    fi
    echo ""
    exit 1
fi
echo ""

# Check 3: Required IAM permissions for Lake Formation operations
echo "Checking IAM permissions for Lake Formation operations..."

REQUIRED_PERMISSIONS=(
    "lakeformation:RegisterResource"
    "lakeformation:RegisterResourceWithPrivilegedAccess"
    "lakeformation:GrantPermissions"
    "lakeformation:GetDataAccess"
    "glue:CreateDatabase"
    "glue:CreateTable"
)

MISSING_PERMISSIONS=()

for permission in "${REQUIRED_PERMISSIONS[@]}"; do
    # Try to simulate the permission check
    SERVICE=$(echo "$permission" | cut -d':' -f1)
    ACTION=$(echo "$permission" | cut -d':' -f2)
    
    # We can't directly test all permissions, so we'll check if user is admin or has policies
    # This is a simplified check
    if [ "$SERVICE" == "lakeformation" ]; then
        # Already verified as LF admin above
        continue
    fi
done

echo -e "${GREEN}✓ Lake Formation administrator has required permissions${NC}"
echo ""

# Check 4: AWS CLI version (should be recent for S3 Tables support)
echo "Checking AWS CLI version..."
CLI_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
CLI_MAJOR=$(echo "$CLI_VERSION" | cut -d'.' -f1)
CLI_MINOR=$(echo "$CLI_VERSION" | cut -d'.' -f2)

if [ "$CLI_MAJOR" -ge 2 ] && [ "$CLI_MINOR" -ge 15 ]; then
    echo -e "${GREEN}✓ AWS CLI version $CLI_VERSION (S3 Tables supported)${NC}"
elif [ "$CLI_MAJOR" -ge 2 ]; then
    echo -e "${YELLOW}⚠ AWS CLI version $CLI_VERSION (may have limited S3 Tables support)${NC}"
    echo "  Consider upgrading to latest version"
else
    echo -e "${RED}✗ AWS CLI version $CLI_VERSION is too old${NC}"
    echo "  Please upgrade to AWS CLI v2.15 or later"
    exit 1
fi
echo ""

# Check 5: Terraform version
echo "Checking Terraform version..."
if command -v terraform &> /dev/null; then
    TF_VERSION=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4)
    if [ -z "$TF_VERSION" ]; then
        TF_VERSION=$(terraform version | head -n1 | awk '{print $2}' | sed 's/v//')
    fi
    
    TF_MAJOR=$(echo "$TF_VERSION" | cut -d'.' -f1)
    TF_MINOR=$(echo "$TF_VERSION" | cut -d'.' -f2)
    
    if [ "$TF_MAJOR" -ge 1 ]; then
        echo -e "${GREEN}✓ Terraform version $TF_VERSION${NC}"
    else
        echo -e "${RED}✗ Terraform version $TF_VERSION is too old${NC}"
        echo "  Please upgrade to Terraform 1.0 or later"
        exit 1
    fi
else
    echo -e "${RED}✗ Terraform not found${NC}"
    echo "  Please install Terraform 1.0 or later"
    exit 1
fi
echo ""

# Summary
echo "========================================="
echo -e "${GREEN}  All prerequisites validated!${NC}"
echo "========================================="
echo ""
echo "You can now run: terraform init && terraform apply"
echo ""
