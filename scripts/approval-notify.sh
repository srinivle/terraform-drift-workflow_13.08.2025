#!/bin/bash

# approval-notify.sh - Complete approval notifications to all channels
# Supports: Slack, Email, Webex, Microsoft Teams

ACTION=${1:-apply}
REGION=${2:-us-east-1}
ACCOUNT_ID=${3:-123456789012}

# Colors for terminal output
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Get additional context
TIMESTAMP=$(date)
BUILD_URL=${BUILD_URL:-"Not available"}
JENKINS_USER=${BUILD_USER:-"Jenkins"}
BUILD_NUMBER=${BUILD_NUMBER:-"N/A"}
JOB_NAME=${JOB_NAME:-"terraform-pipeline"}

# Enhanced header
echo -e "${CYAN}$(printf '═%.0s' {1..70})${NC}"
echo -e "${BLUE}📋 TERRAFORM APPROVAL NOTIFICATION CENTER 📋${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..70})${NC}"
echo -e "${PURPLE}🚀 Pipeline: ${JOB_NAME}${NC}"
echo -e "${YELLOW}📋 Action: ${ACTION}${NC}"
echo -e "${YELLOW}🌍 Region: ${REGION}${NC}"
echo -e "${YELLOW}🏢 Account: ${ACCOUNT_ID}${NC}"
echo -e "${YELLOW}🔢 Build: ${BUILD_NUMBER}${NC}"
echo -e "${YELLOW}👤 User: ${JENKINS_USER}${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..70})${NC}"

# Determine deployment scope and create appropriate messages
if [ "${REGION}" = "ALL-REGIONS" ] || [ "${ACTION}" = "apply-multi-region" ]; then
    DEPLOYMENT_SCOPE="Multi-Region"
    REGIONS_LIST="us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1"
    APPROVAL_MESSAGE="🌍 *Multi-Region Terraform Approval Required*

*🚀 COMPREHENSIVE DEPLOYMENT APPROVAL NEEDED*

*📋 Deployment Details:*
• *Action:* Multi-Region Apply
• *Regions:* us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1
• *Account ID:* ${ACCOUNT_ID}
• *Build Number:* ${BUILD_NUMBER}
• *Requested By:* ${JENKINS_USER}
• *Timestamp:* ${TIMESTAMP}

*🔍 Critical Review Required:*
This deployment will affect **ALL 5 REGIONS** simultaneously:
✅ US East (N. Virginia) - us-east-1
✅ US West (N. California) - us-west-1  
✅ Asia Pacific (Mumbai) - ap-south-1
✅ China (Beijing) - cn-north-1
✅ China (Ningxia) - cn-northwest-1

*📁 Review Materials:*
• Plan Files: Multiple tfplan-{region}-${ACCOUNT_ID}.plan files
• Build URL: ${BUILD_URL}
• Console: ${BUILD_URL}console
• Artifacts: ${BUILD_URL}artifact/

*⚠️ CRITICAL CONSIDERATIONS:*
• This affects production infrastructure across multiple regions
• Review all terraform plans before approval
• Consider impact on users in different time zones
• Verify backup and rollback procedures are in place

*⏰ Action Required:*
The pipeline is paused awaiting your manual approval for this multi-region deployment."

else
    DEPLOYMENT_SCOPE="Single Region"
    APPROVAL_MESSAGE="🔄 *Terraform Approval Required*

*📋 Deployment Details:*
• *Action:* ${ACTION}
• *Region:* ${REGION}  
• *Account ID:* ${ACCOUNT_ID}
• *Build Number:* ${BUILD_NUMBER}
• *Requested By:* ${JENKINS_USER}
• *Timestamp:* ${TIMESTAMP}

*🔍 Review Required:*
Please review the terraform plan and approve the deployment to proceed.

*📁 Artifacts:*
• Plan File: \`tfplan-${REGION}-${ACCOUNT_ID}.plan\`
• Build URL: ${BUILD_URL}
• Console: ${BUILD_URL}console

*⏰ Action Needed:*
The pipeline is currently paused waiting for manual approval."
fi

# Enhanced approval message for critical regions/accounts
CRITICAL_NOTICE=""
if [[ "${REGION}" == "cn-"* ]] || [[ "${ACCOUNT_ID}" == *"prod"* ]] || [[ "${REGION}" = "ALL-REGIONS" ]]; then
    CRITICAL_NOTICE="

*🚨 CRITICAL DEPLOYMENT NOTICE:*
This deployment targets critical infrastructure. Extra caution and thorough review are required."
fi

APPROVAL_MESSAGE="${APPROVAL_MESSAGE}${CRITICAL_NOTICE}"

# Create detailed email content
EMAIL_APPROVAL_MESSAGE="Terraform Deployment Approval Required - ${DEPLOYMENT_SCOPE}

DEPLOYMENT APPROVAL REQUEST
===========================

Pipeline: ${JOB_NAME}
Action: ${ACTION}
Scope: ${DEPLOYMENT_SCOPE}
$(if [ "${REGION}" = "ALL-REGIONS" ]; then
    echo "Regions: ${REGIONS_LIST}"
else
    echo "Region: ${REGION}"
fi)
Account ID: ${ACCOUNT_ID}
Build Number: ${BUILD_NUMBER}
Requested By: ${JENKINS_USER}
Timestamp: ${TIMESTAMP}

REVIEW REQUIREMENTS
==================
$(if [ "${REGION}" = "ALL-REGIONS" ]; then
    cat << 'MULTI_REGION_EOF'
This is a MULTI-REGION deployment affecting all 5 supported regions:

1. us-east-1 (US East - N. Virginia)
2. us-west-1 (US West - N. California)  
3. ap-south-1 (Asia Pacific - Mumbai)
4. cn-north-1 (China - Beijing)
5. cn-northwest-1 (China - Ningxia)

CRITICAL REVIEW CHECKLIST:
□ Review all terraform plan files for each region
□ Verify resource changes are expected and safe
□ Consider cross-region dependencies
□ Check for potential service disruptions
□ Ensure backup procedures are in place
□ Verify rollback plan is available

Plan Files to Review:
- tfplan-us-east-1-${ACCOUNT_ID}.plan
- tfplan-us-west-1-${ACCOUNT_ID}.plan
- tfplan-ap-south-1-${ACCOUNT_ID}.plan
- tfplan-cn-north-1-${ACCOUNT_ID}.plan
- tfplan-cn-northwest-1-${ACCOUNT_ID}.plan
MULTI_REGION_EOF
else
    echo "Single region deployment to: ${REGION}"
    echo ""
    echo "Plan File: tfplan-${REGION}-${ACCOUNT_ID}.