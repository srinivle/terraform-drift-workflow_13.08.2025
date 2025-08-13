# terraform-drift-workflow_13.08.2025
Key Features:
1.	Simple Directory Structure
2.	Multi-Region Support - Supports US, Asia Pacific, and China regions (cn-north-1, cn-northwest-1)
3.	Multi-Account Support - Uses assume role for different AWS accounts
4.	China Region Handling - Special AWS provider for China regions with aws-cn ARN format
5.	Drift Detection - Automated script to detect configuration drift
6.	Drift Monitoring 
7.	Makefile Automation - Simple commands for common operations

Simple Directory Structure:
```
├── Jenkinsfile
├── Makefile
├── main.tf
├── backend.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars
├── versions.tf
├── scripts/
│   ├── drift-detection.sh
│   ├── drift-monitoring.sh
│   ├── slack-notify.sh
|   ├── teams-notify.sh
|   ├── webex-notify.sh
│   ├── email-notify.sh
│   └── approval-notify.sh
├── modules/
│   └── ec2/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── configs/
│   ├── accounts.yaml
│   └── regions.yaml
└── drift-reports/
    └── .gitkeep
```


# 🎯 Makefile Features:
# 🔔 Multi-Channel Notification Integration:
- All 4 channels: Slack, Email, Webex, Teams
- Smart notification helpers: Automatic success/failure/destroy notifications
- Comprehensive testing: make test-all-notifications tests all channels
- Status tracking: Shows configuration status for all notification services

# 🌍 Enhanced Multi-Region Support:
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
→ Plans, notifies, waits for approval, deploys to all 5 regions
→ Sends notifications to ALL channels at each step

# 🔍 Advanced Drift Management:
-  Individual region: make drift-check
-  All regions: make drift-check-all
-  Full monitoring: make drift-monitor with HTML dashboard
-  Emergency mode: make emergency-drift-check with DRIFT_THRESHOLD=1

# 🚀 Jenkinsfile Features:
📋 Enhanced Pipeline Parameters:
- New parameter: SEND_NOTIFICATIONS (enable/disable notifications)
- New parameter: ENABLE_DRIFT_ALERTS (control drift alerting)
-	New action: test-notifications (test all notification channels)
🔔 Comprehensive Notification System:
- Pipeline start: Notifications when pipeline begins
-	Approval requests: Multi-channel approval notifications
-	Success/failure: Detailed notifications to all channels
-	Multi-region: Progress notifications during multi-region deployments
📊 Advanced Reporting:
-	HTML reports: Drift detection and monitoring dashboards
-	Artifact archiving: All plans, logs, and reports saved
-	Console output: Beautiful formatted output with emojis and colors

# 📋 Approval Notification Script:

🌍 Multi-Region Awareness:
-	Detects multi-region deployments: Special handling for ALL-REGIONS
-	Region-specific messaging: Different messages for single vs multi-region
-	Critical region alerts: Enhanced warnings for China regions and prod accounts

📊 Comprehensive Tracking:
-	Notification success tracking: Monitors each channel's success/failure
-	Success rate calculation: Shows percentage of successful notifications
-	Detailed logging: Complete audit trail of approval requests

📄 Enhanced Documentation:
-	Approval summary files: Complete deployment details and instructions
-	Multi-region checklists: Specific guidance for multi-region deployments
-	Configuration health checks: Shows status of all notification configurations

# 💡 Key Usage Examples:
Complete Workflow:
1. Test all notifications first
```
make test-all-notifications
```
2. Plan deployment
```
make plan REGION=us-east-1 ACCOUNT_ID=123456789012
```
3. Apply with full notification workflow
```
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
- Sends approval requests to all 4 channels
- Waits for Jenkins approval
- Deploys infrastructure
- Sends success notifications to all 4 channels

4. Multi-region deployment
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
- Plans all 5 regions
- Sends multi-region approval request
- Waits for approval for each region
- Deploys to all regions
- Sends completion notifications

Jenkins Pipeline:
```
In Jenkins, select:
- ACTION: apply
- REGION: us-east-1  
- ACCOUNT_ID: 123456789012
- DEPLOY_ALL_REGIONS: true (for multi-region)
- SEND_NOTIFICATIONS: true
```
- Full automated workflow with multi-channel notifications

# 🔍 Drift Detection Script Features:

📊 Enhanced Reporting:
- Modern HTML Dashboard - Interactive reports with Font Awesome icons, animations, and responsive design
- JSON Reports - Machine-readable data with comprehensive metadata
- Progress Bars - Visual drift threshold tracking
- Auto-refresh - Dashboard refreshes every 5 minutes for live monitoring

🔔 Multi-Channel Notifications:
- All 4 Channels - Slack, Email, Webex, Teams
- Status-based Messaging - Different messages for success, warning, error, critical
- Threshold Alerts - Critical notifications when drift threshold exceeded
- Rich Formatting - Detailed status information with timestamps and links

📈 Advanced Analytics:
- Drift Counters - Persistent tracking per region/account
- Execution Metrics - Performance monitoring and timing
- Build Integration - Jenkins build information in reports
- Error Handling - Comprehensive error capture and reporting

# 📊 Drift Monitoring Script Features:

🌍 Multi-Region Dashboard:
- Interactive HTML Dashboard - Real-time monitoring across all 5 regions
- Region Cards - Individual status cards with progress bars
- Critical Alerts - Animated alerts for threshold violations
- Auto-refresh - Live updates every 5 minutes

📊 Comprehensive Analytics:
- Health Scoring - Overall infrastructure health percentage
- Success Rates - Statistical analysis across regions
- Execution Timing - Performance metrics per region
- Drift Summaries - Detailed issue reporting

📄 Multiple Report Formats:
- HTML Dashboard - Interactive web interface
- JSON Export - Complete data for API integration
- CSV Export - Spreadsheet-compatible data
- Executive Summary - High-level text report with recommendations

🚨 Advanced Alert System:
- Critical Thresholds - Immediate alerts when limits exceeded
- Multi-channel Notifications - All 4 notification channels
- Status Aggregation - Overall health across all regions
- Recommendation Engine - Automated next-step guidance

# 💡 Key Usage Examples:
Single Region Drift Check: Enhanced drift detection with multi-channel notifications
```
./scripts/drift-detection.sh us-east-1 123456789012
```
# Output:
- ✅ Beautiful HTML report with interactive features
- 📊 JSON report with comprehensive metadata
- 🔔 Notifications sent to all 4 channels
- 📈 Drift threshold tracking and alerts

Multi-Region Monitoring: Comprehensive monitoring across all regions
```
./scripts/drift-monitoring.sh 123456789012
```
# Output:
- 🌍 Interactive dashboard with all 5 regions
- 📊 Health score and success rate analytics
- 🚨 Critical alerts if thresholds exceeded
- 📄 Multiple report formats (HTML, JSON, CSV)
- 🔔 Summary notifications to all channels

# Integration with Makefile: Enhanced makefile commands
```
make drift-check REGION=cn-north-1 ACCOUNT_ID=456789012345
make drift-monitor ACCOUNT_ID=123456789012
```
Example Usage:
# Deploy to specific region and account
```
make plan apply REGION=cn-north-1 ACCOUNT_ID=123456789012
```
# Deploy to all regions
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Check drift
```
make drift-check REGION=us-east-1 ACCOUNT_ID=123456789012
```
Important Notes:
1. China Regions: Uses aws.china provider with arn:aws-cn format
2. State Management: Each region/account combination gets its own state file
3. EC2 Module: Deploys a simple web server with region-specific content
4. Security Groups: Basic HTTP and SSH access configured
5. AMI Selection: Uses latest Amazon Linux 2 AMI automatically

✅ Updated accounts.yaml Structure
1. Removed environment prefixes: No more dev/staging/prod naming
2. Simple account listing: Clean account-1, account-2, etc. structure
3. Added China accounts: Separate accounts with arn:aws-cn format for China regions
4. Descriptive names: Added human-readable names for each account

Account Management
```
accounts:
  account-1:
    account_id: "123456789012"
    role_arn: "arn:aws:iam::123456789012:role/TerraformRole"
    name: "Primary Account"
  china-account-1:
    account_id: "456789012345"
    role_arn: "arn:aws-cn:iam::456789012345:role/TerraformRole"
    name: "China Region Account 1"
```
Usage Examples:
# Deploy to standard AWS region
```
make plan apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
# Deploy to China region (automatically uses cn-north-1 for state)
```
make plan apply REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Deploy across all regions for specific account
```
make deploy-all-regions ACCOUNT_ID=123456789012
```

# 🛠 Usage Examples:

# Jenkins Pipeline Trigger Examples:
1. Plan deployment to specific region
ACTION=plan, REGION=us-east-1, ACCOUNT_ID=123456789012
2. Deploy to China region
ACTION=apply, REGION=cn-north-1, ACCOUNT_ID=456789012345
3. Deploy to all regions
ACTION=apply, DEPLOY_ALL_REGIONS=true, ACCOUNT_ID=123456789012
4. Check drift for specific region  
ACTION=drift-check, REGION=ap-south-1, ACCOUNT_ID=123456789012
5. Monitor drift across all regions
ACTION=drift-monitor, ACCOUNT_ID=123456789012
6. Destroy resources with confirmation
ACTION=destroy, REGION=us-west-1, ACCOUNT_ID=123456789012

# 📱 All Notification Channels Now Supported:

- ✅ Slack - Rich messages with interactive buttons
- ✅ Email - HTML emails with SMTP support
- ✅ Cisco Webex - Adaptive Cards with Bot API support
- ✅ Microsoft Teams - Adaptive Cards with webhook integration

🚀 Key Features of New Notification Scripts:
💬 Cisco Webex Notifications (webex-notify.sh):
Dual Integration Methods:
```
# Method 1: Webhook with Adaptive Cards
export WEBEX_WEBHOOK_URL="https://webexapis.com/v1/webhooks/incoming/..."

# Method 2: Bot API with Room ID
export WEBEX_ACCESS_TOKEN="your-bot-token"
export WEBEX_ROOM_ID="room-id"
```
Rich Adaptive Cards:

Beautiful card layouts with Terraform branding
Interactive action buttons (View Build, View Console)
Status-based styling and colors
Critical alerts with attention-grabbing design

🟦 Microsoft Teams Notifications (teams-notify.sh):
Advanced Adaptive Cards:
```
export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
```
Features:

Adaptive Cards v1.4 with rich formatting
Fallback support to MessageCard format if needed
Status-based styling (success=green, error=red, etc.)
Interactive buttons with direct links to Jenkins

📋 Updated Makefile Integration:
Enhanced Script Checking: Now checks all 7 notification scripts
```
make check-scripts
```
# Scripts checked:
- ✅ slack-notify.sh
- ✅ email-notify.sh  
- ✅ webex-notify.sh
- ✅ teams-notify.sh
- ✅ drift-detection.sh
- ✅ drift-monitoring.sh
- ✅ approval-notify.sh

Multi-Channel Notifications: Apply notifications sent to ALL channels
```
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
- Sends success notifications to Slack + Webex + Teams

# Test all notification systems
```
make test-notifications
```
- Tests Slack, Email, Webex, and Teams

Enhanced Status Display:
```
make status
```
# Shows configuration for all notification channels:
- ✅ SLACK_WEBHOOK_URL: Configured
- ✅ WEBEX_WEBHOOK_URL: Configured  
- ✅ TEAMS_WEBHOOK_URL: Configured
- ✅ EMAIL_RECIPIENT: admin@company.com

# 🔧 Configuration Examples:
Environment Variables Setup:
# Slack
```
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
# Email
```
export EMAIL_RECIPIENT="devops@company.com"
export SMTP_SERVER="smtp.company.com"
export SMTP_USER="terraform@company.com"
export SMTP_PASS="password"
```
# Cisco Webex (Choose one method)
```
Method 1: Webhook
export WEBEX_WEBHOOK_URL="https://webexapis.com/v1/webhooks/incoming/..."

# Method 2: Bot API
export WEBEX_ACCESS_TOKEN="your-bot-access-token"
export WEBEX_ROOM_ID="your-room-id"
```
# Microsoft Teams
```
export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
```
🎨 Notification Examples:
✅ Success Notifications:

Slack: Green message with checkmark
Email: HTML email with success styling
Webex: Green Adaptive Card with success icon
Teams: Good container style with success theme

💡 Usage Examples:
# Test All Notifications: Test every notification channel
```
make test-notifications REGION=us-east-1 ACCOUNT_ID=123456789012
```
# Output:
- 📱 Testing Slack notification... ✅
- 📧 Testing email notification... ✅  
- 💬 Testing Webex notification... ✅
- 🟦 Testing Teams notification... ✅

# Deploy with notifications to all channels
```
make apply REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Sends notifications to:
- Slack team channel
- Email distribution list
- Webex team space  
- Teams channel

# Multi-Region with Approvals: Deploy to all regions with approval notifications
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# For each region:
1. Creates terraform plan
2. Sends approval request to ALL channels
3. Waits for manual approval
4. Applies changes
5. Sends success notification to ALL channels


Example Usage:

# Core Commands
```
make init plan apply destroy
```
# Drift Management  
```
make drift-check drift-monitor drift-check-all
make drift-check          # Single region
make drift-monitor        # All regions with dashboard
make drift-check-all      # All regions simple check
```

# Multi-Region Operations
```
make deploy-all-regions
```
# Code Quality
```
make validate format security-scan cost-estimate
```
# Utilities
```
make clean show-state refresh
```
# Deploy to specific region and account
```
make plan apply REGION=cn-north-1 ACCOUNT_ID=123456789012
```
# Deploy to all regions
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Check drift
```
make drift-check REGION=us-east-1 ACCOUNT_ID=123456789012
```
Important Notes:
- China Regions: Uses aws.china provider with arn:aws-cn format
- State Management: Each region/account combination gets its own state file
- EC2 Module: Deploys a simple web server with region-specific content
- Security Groups: Basic HTTP and SSH access configured
- AMI Selection: Uses latest Amazon Linux 2 AMI automatically

  # Deploy to standard AWS region
```
make plan apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
# Deploy to China region (automatically uses cn-north-1 for state)
```
make plan apply REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Deploy across all regions for specific account
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Basic deployment
```
make plan REGION=us-east-1 ACCOUNT_ID=123456789012
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
# China regions
```
make plan REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Drift monitoring
```
make drift-monitor ACCOUNT_ID=123456789012
```
# Multi-region deployment
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Jenkins Pipeline:
```
groovy
// Multi-region deployment
if (params.DEPLOY_ALL_REGIONS) {
    sh "make deploy-all-regions ACCOUNT_ID=${params.ACCOUNT_ID}"
}

// Approval notifications
sh "./scripts/approval-notify.sh apply ${params.REGION} ${params.ACCOUNT_ID}"
```
# Use individual scripts
```
./scripts/drift-detection.sh us-east-1 123456789012
./scripts/drift-monitoring.sh 123456789012
./scripts/slack-notify.sh "success" "Deployment complete"
./scripts/email-notify.sh "approval" "Review required"
./scripts/approval-notify.sh apply us-east-1 123456789012
```
- Jenkins Pipeline
- Just configure the Jenkinsfile in your repository
- Set parameters and run!

- 📋 Enhanced Help & Status
```
make help    # Beautiful colored help with examples
make status  # Show current configuration and tool status
```
- 🔧 Script Management
```
make check-scripts           # Verify all required scripts exist
make make-scripts-executable # Make scripts executable automatically
```
- 🎯 Core Infrastructure Commands - Basic workflow with notifications
```
make init plan apply destroy
```
# Multi-region operations
```
make deploy-all-regions ACCOUNT_ID=123456789012
make china-deploy ACCOUNT_ID=456789012345
make us-deploy ACCOUNT_ID=123456789012
```
🔍 Drift Management
```
make drift-check REGION=us-east-1 ACCOUNT_ID=123456789012
make drift-monitor ACCOUNT_ID=123456789012
make drift-check-all ACCOUNT_ID=123456789012
make emergency-drift-check REGION=us-east-1 ACCOUNT_ID=123456789012
```
🔔 Notification Integration
```
make test-notifications  # Test Slack and email systems - Automatic notifications on apply/destroy
```
- Enhanced Apply Process:
```
apply: make-scripts-executable ## Apply with notifications
  1. Check plan file exists
	2. Send approval notification
	3. Apply changes
	4. Send success notification
```
- Multi-Region Deployment with Approval:
```
deploy-all-regions:
  1. Plans for each region
	2. Sends approval notification
	3. Waits for manual confirmation
	4. Applies changes
	5. Sends completion notification
```
- Emergency Operations:
```
emergency-drift-check:  # Sets DRIFT_THRESHOLD=1 for immediate alerts
```
🎨 Beautiful Output - Colored output with emojis
echo -e "$(GREEN)✅ Apply completed successfully$(NC)"
echo -e "$(BLUE)🔍 Starting drift detection...$(NC)"
echo -e "$(RED)🚨 EMERGENCY DRIFT CHECK$(NC)"

# 💡 Usage Examples:
Basic Operations:
- Check everything is set up
```
make status
```
# Standard deployment workflow
```
make plan REGION=us-east-1 ACCOUNT_ID=123456789012
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
# China region deployment
```
make plan REGION=cn-north-1 ACCOUNT_ID=456789012345
make apply REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Advanced Operations:
Deploy to all regions with approvals
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Monitor drift across all regions
```
make drift-monitor ACCOUNT_ID=123456789012
```
# Emergency drift check with immediate alerts
```
make emergency-drift-check REGION=us-east-1 ACCOUNT_ID=123456789012
```
# Test notification systems
```
make test-notifications
```
# Regional Deployments:
- Deploy only to China regions
```
make china-deploy ACCOUNT_ID=456789012345
```
# Deploy only to US regions  
```
make us-deploy ACCOUNT_ID=123456789012
```
# Check drift in all regions
```
make drift-check-all ACCOUNT_ID=123456789012
```
# Enhanced makefile commands
```
make drift-check REGION=cn-north-1 ACCOUNT_ID=456789012345
make drift-monitor ACCOUNT_ID=123456789012
```
# Multi-Region Monitoring: Comprehensive monitoring across all regions
```
./scripts/drift-monitoring.sh 123456789012
```
# Single Region Drift Check: Enhanced drift detection with multi-channel notifications
```
./scripts/drift-detection.sh us-east-1 123456789012
```
# Complete Workflow:
1. Test all notifications first
```
make test-all-notifications
```
2. Plan deployment
```
make plan REGION=us-east-1 ACCOUNT_ID=123456789012
```
3. Apply with full notification workflow
```
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
4. Multi-region deployment
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Deploy to all regions with approval notifications
```
make deploy-all-regions ACCOUNT_ID=123456789012
```
# Deploy with notifications to all channels
```
make apply REGION=cn-north-1 ACCOUNT_ID=456789012345
```
# Test every notification channel : Slack, Email, Webex, Teams
```
make test-notifications REGION=us-east-1 ACCOUNT_ID=123456789012
```
# Enhanced Script Checking: Now checks all 7 notification scripts
```
make check-scripts
```
Scripts checked:
- ✅ slack-notify.sh
- ✅ email-notify.sh  
- ✅ webex-notify.sh
- ✅ teams-notify.sh
- ✅ drift-detection.sh
- ✅ drift-monitoring.sh
- ✅ approval-notify.sh

# Multi-Channel Notifications: Apply notifications sent to ALL channels
```
make apply REGION=us-east-1 ACCOUNT_ID=123456789012
```
- Sends success notifications to Slack + Webex + Teams

# Test all notification systems
```
make test-notifications
```
# Tests Slack, Email, Webex, and Teams - Enhanced Status Display:
```
make status
```
Shows configuration for all notification channels:
✅ SLACK_WEBHOOK_URL: Configured
✅ WEBEX_WEBHOOK_URL: Configured  
✅ TEAMS_WEBHOOK_URL: Configured
✅ EMAIL_RECIPIENT: admin@company.com

# 🔧 Configuration Examples:
Environment Variables Setup:
# Slack
```
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```
# Email
```
export EMAIL_RECIPIENT="devops@company.com"
export SMTP_SERVER="smtp.company.com"
export SMTP_USER="terraform@company.com"
export SMTP_PASS="password"
```
# Cisco Webex (Choose one method)
```
- Method 1: Webhook
export WEBEX_WEBHOOK_URL="https://webexapis.com/v1/webhooks/incoming/..."

- Method 2: Bot API
export WEBEX_ACCESS_TOKEN="your-bot-access-token"
export WEBEX_ROOM_ID="your-room-id"
```
# Microsoft Teams
```
export TEAMS_WEBHOOK_URL="https://outlook.office.com/webhook/..."
```
