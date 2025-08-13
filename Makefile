# Makefile for Terraform Infrastructure Management
# Complete version with all notification channels: Slack, Email, Webex, Teams

.PHONY: help init plan apply destroy drift-check drift-monitor validate format security-scan cost-estimate clean
.DEFAULT_GOAL := help

# Variables
REGION ?= us-east-1
ACCOUNT_ID ?= 123456789012
STATE_BUCKET ?= my-terraform-state-bucket
ACTION ?= apply

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
PURPLE := \033[0;35m
CYAN := \033[0;36m
NC := \033[0m

# Check if required scripts exist
SCRIPTS_DIR := scripts
DRIFT_DETECTION_SCRIPT := $(SCRIPTS_DIR)/drift-detection.sh
DRIFT_MONITORING_SCRIPT := $(SCRIPTS_DIR)/drift-monitoring.sh
SLACK_NOTIFY_SCRIPT := $(SCRIPTS_DIR)/slack-notify.sh
EMAIL_NOTIFY_SCRIPT := $(SCRIPTS_DIR)/email-notify.sh
APPROVAL_NOTIFY_SCRIPT := $(SCRIPTS_DIR)/approval-notify.sh
WEBEX_NOTIFY_SCRIPT := $(SCRIPTS_DIR)/webex-notify.sh
TEAMS_NOTIFY_SCRIPT := $(SCRIPTS_DIR)/teams-notify.sh

help: ## Show this help message
	@echo -e "$(CYAN)================================================================$(NC)"
	@echo -e "$(BLUE)        TERRAFORM INFRASTRUCTURE MANAGEMENT$(NC)"
	@echo -e "$(CYAN)================================================================$(NC)"
	@echo -e "$(YELLOW)Usage: make [target] REGION=[region] ACCOUNT_ID=[account]$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Available Targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-25s$(NC) %s\n", $$1, $$2}'
	@echo -e ""
	@echo -e "$(GREEN)Examples:$(NC)"
	@echo -e "  $(CYAN)make plan REGION=us-east-1 ACCOUNT_ID=123456789012$(NC)"
	@echo -e "  $(CYAN)make apply REGION=cn-north-1 ACCOUNT_ID=456789012345$(NC)"
	@echo -e "  $(CYAN)make drift-monitor ACCOUNT_ID=123456789012$(NC)"
	@echo -e "  $(CYAN)make deploy-all-regions ACCOUNT_ID=123456789012$(NC)"
	@echo -e "  $(CYAN)make test-all-notifications$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Supported Regions:$(NC)"
	@echo -e "  us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1"
	@echo -e ""
	@echo -e "$(GREEN)Notification Channels:$(NC)"
	@echo -e "  📱 Slack, 📧 Email, 💬 Webex, 🟦 Teams"
	@echo -e "$(CYAN)================================================================$(NC)"

check-scripts: ## Check if required scripts exist
	@echo -e "$(BLUE)🔍 Checking required scripts...$(NC)"
	@for script in $(DRIFT_DETECTION_SCRIPT) $(DRIFT_MONITORING_SCRIPT) $(SLACK_NOTIFY_SCRIPT) $(EMAIL_NOTIFY_SCRIPT) $(APPROVAL_NOTIFY_SCRIPT) $(WEBEX_NOTIFY_SCRIPT) $(TEAMS_NOTIFY_SCRIPT); do \
		if [ ! -f "$$script" ]; then \
			echo -e "$(RED)❌ Missing script: $$script$(NC)"; \
			exit 1; \
		else \
			echo -e "$(GREEN)✅ Found: $$script$(NC)"; \
		fi; \
	done
	@echo -e "$(GREEN)✅ All required scripts found$(NC)"

make-scripts-executable: check-scripts ## Make all scripts executable
	@echo -e "$(YELLOW)🔧 Making scripts executable...$(NC)"
	@chmod +x $(SCRIPTS_DIR)/*.sh
	@echo -e "$(GREEN)✅ Scripts are now executable$(NC)"

init: ## Initialize Terraform backend
	@echo -e "$(GREEN)🚀 Initializing Terraform for $(REGION) in account $(ACCOUNT_ID)...$(NC)"
	@BACKEND_REGION=$$(echo $(REGION) | grep -q '^cn-' && echo 'cn-north-1' || echo 'us-east-1'); \
	terraform init \
		-backend-config="bucket=$(STATE_BUCKET)-$(ACCOUNT_ID)" \
		-backend-config="key=terraform/$(REGION)/$(ACCOUNT_ID)/terraform.tfstate" \
		-backend-config="region=$$BACKEND_REGION" \
		-backend-config="encrypt=true"
	@echo -e "$(GREEN)✅ Terraform initialization completed$(NC)"

validate: ## Validate Terraform configuration
	@echo -e "$(GREEN)🔍 Validating Terraform configuration...$(NC)"
	@terraform validate
	@echo -e "$(GREEN)✅ Validation passed$(NC)"

format: ## Format Terraform files
	@echo -e "$(GREEN)📝 Formatting Terraform files...$(NC)"
	@terraform fmt -recursive .
	@echo -e "$(GREEN)✅ Formatting completed$(NC)"

plan: init validate ## Create Terraform execution plan
	@echo -e "$(GREEN)📋 Creating execution plan for $(REGION) in account $(ACCOUNT_ID)...$(NC)"
	@terraform plan \
		-var="region=$(REGION)" \
		-var="account_id=$(ACCOUNT_ID)" \
		-out=tfplan-$(REGION)-$(ACCOUNT_ID).plan
	@echo -e "$(YELLOW)📄 Plan saved as: tfplan-$(REGION)-$(ACCOUNT_ID).plan$(NC)"
	@echo -e "$(GREEN)✅ Plan creation completed$(NC)"

apply: make-scripts-executable ## Apply Terraform changes with multi-channel notifications
	@echo -e "$(GREEN)🚀 Applying Terraform changes for $(REGION) in account $(ACCOUNT_ID)...$(NC)"
	@if [ ! -f "tfplan-$(REGION)-$(ACCOUNT_ID).plan" ]; then \
		echo -e "$(RED)❌ Error: Plan file not found. Run 'make plan' first.$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(YELLOW)📋 Sending approval notifications to all channels...$(NC)"
	@if [ -f "$(APPROVAL_NOTIFY_SCRIPT)" ]; then \
		$(APPROVAL_NOTIFY_SCRIPT) $(ACTION) $(REGION) $(ACCOUNT_ID); \
	fi
	@echo -e "$(YELLOW)⏸️  Applying changes (this may take a while)...$(NC)"
	@terraform apply tfplan-$(REGION)-$(ACCOUNT_ID).plan
	@echo -e "$(GREEN)✅ Apply completed successfully$(NC)"
	@echo -e "$(CYAN)📢 Sending success notifications to all channels...$(NC)"
	@$(MAKE) send-success-notification

apply-without-approval: make-scripts-executable ## Apply without approval notifications (for automation)
	@echo -e "$(GREEN)🚀 Applying Terraform changes for $(REGION) in account $(ACCOUNT_ID)...$(NC)"
	@if [ ! -f "tfplan-$(REGION)-$(ACCOUNT_ID).plan" ]; then \
		echo -e "$(RED)❌ Error: Plan file not found. Run 'make plan' first.$(NC)"; \
		exit 1; \
	fi
	@terraform apply tfplan-$(REGION)-$(ACCOUNT_ID).plan
	@echo -e "$(GREEN)✅ Apply completed successfully$(NC)"
	@$(MAKE) send-success-notification

destroy: make-scripts-executable ## Destroy Terraform resources with notifications
	@echo -e "$(RED)⚠️  WARNING: This will destroy ALL resources in $(REGION) for account $(ACCOUNT_ID)$(NC)"
	@echo -e "$(YELLOW)Type 'DELETE' to confirm destruction (case sensitive):$(NC)"
	@read -r confirmation; \
	if [ "$$confirmation" = "DELETE" ]; then \
		echo -e "$(RED)🗑️  Destroying resources...$(NC)"; \
		terraform destroy \
			-var="region=$(REGION)" \
			-var="account_id=$(ACCOUNT_ID)" \
			-auto-approve; \
		echo -e "$(GREEN)✅ Resources destroyed successfully$(NC)"; \
		$(MAKE) send-destroy-notification; \
	else \
		echo -e "$(YELLOW)❌ Destruction cancelled - confirmation did not match 'DELETE'$(NC)"; \
	fi

drift-check: make-scripts-executable ## Check for configuration drift in specific region
	@echo -e "$(BLUE)🔍 Starting drift detection...$(NC)"
	@echo -e "$(BLUE)Region: $(REGION), Account: $(ACCOUNT_ID)$(NC)"
	@if [ ! -f "$(DRIFT_DETECTION_SCRIPT)" ]; then \
		echo -e "$(RED)❌ Drift detection script not found: $(DRIFT_DETECTION_SCRIPT)$(NC)"; \
		exit 1; \
	fi
	@$(DRIFT_DETECTION_SCRIPT) $(REGION) $(ACCOUNT_ID)

drift-monitor: make-scripts-executable ## Monitor drift across all regions for account
	@echo -e "$(BLUE)🔍 Starting comprehensive drift monitoring...$(NC)"
	@echo -e "$(BLUE)Account: $(ACCOUNT_ID)$(NC)"
	@if [ ! -f "$(DRIFT_MONITORING_SCRIPT)" ]; then \
		echo -e "$(RED)❌ Drift monitoring script not found: $(DRIFT_MONITORING_SCRIPT)$(NC)"; \
		exit 1; \
	fi
	@$(DRIFT_MONITORING_SCRIPT) $(ACCOUNT_ID)

deploy-all-regions: make-scripts-executable ## Deploy to all regions for specific account
	@echo -e "$(PURPLE)🌍 Starting multi-region deployment...$(NC)"
	@echo -e "$(PURPLE)Account: $(ACCOUNT_ID)$(NC)"
	@echo -e "$(PURPLE)Regions: us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1$(NC)"
	@$(MAKE) send-multiregion-start-notification
	@for region in us-east-1 us-west-1 ap-south-1 cn-north-1 cn-northwest-1; do \
		echo -e "$(GREEN)📍 Deploying to $$region...$(NC)"; \
		make plan REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
		if [ -f "$(APPROVAL_NOTIFY_SCRIPT)" ]; then \
			$(APPROVAL_NOTIFY_SCRIPT) "apply" $$region $(ACCOUNT_ID); \
		fi; \
		echo -e "$(YELLOW)⏸️  Pausing for review (press Enter to continue or Ctrl+C to abort)...$(NC)"; \
		read; \
		make apply-without-approval REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
		echo -e "$(GREEN)✅ $$region deployment completed$(NC)"; \
		sleep 5; \
	done
	@echo -e "$(PURPLE)✅ Multi-region deployment completed$(NC)"
	@$(MAKE) send-multiregion-complete-notification

security-scan: ## Run security scan on Terraform files
	@echo -e "$(YELLOW)🔒 Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		echo -e "$(GREEN)📊 Running tfsec scan...$(NC)"; \
		tfsec . --format json > security-report.json || true; \
		tfsec . --format table; \
		echo -e "$(GREEN)✅ Security scan completed. Report: security-report.json$(NC)"; \
	else \
		echo -e "$(RED)❌ tfsec not installed. Install with:$(NC)"; \
		echo -e "$(CYAN)  brew install tfsec$(NC)"; \
		echo -e "$(CYAN)  # or$(NC)"; \
		echo -e "$(CYAN)  curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash$(NC)"; \
	fi

cost-estimate: ## Estimate infrastructure costs
	@echo -e "$(YELLOW)💰 Estimating infrastructure costs...$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		echo -e "$(GREEN)📊 Running infracost analysis...$(NC)"; \
		infracost breakdown --path . --format json > cost-estimate.json; \
		echo -e "$(GREEN)💰 Cost breakdown:$(NC)"; \
		infracost breakdown --path . --format table; \
		echo -e "$(GREEN)✅ Cost estimate completed. Report: cost-estimate.json$(NC)"; \
	else \
		echo -e "$(RED)❌ infracost not installed. Install from: https://www.infracost.io/docs/$(NC)"; \
	fi

clean: ## Clean temporary files and artifacts
	@echo -e "$(YELLOW)🧹 Cleaning temporary files...$(NC)"
	@rm -f tfplan-*.plan
	@rm -f .terraform.lock.hcl
	@rm -f terraform.tfstate.backup
	@rm -f security-report.json
	@rm -f cost-estimate.json
	@rm -f approval-summary-*.txt
	@rm -rf .terraform/
	@echo -e "$(GREEN)✅ Cleanup completed$(NC)"

show-state: ## Show current Terraform state
	@echo -e "$(BLUE)📋 Current Terraform state for $(REGION) in account $(ACCOUNT_ID):$(NC)"
	@terraform show

refresh: ## Refresh Terraform state
	@echo -e "$(YELLOW)🔄 Refreshing Terraform state...$(NC)"
	@terraform refresh \
		-var="region=$(REGION)" \
		-var="account_id=$(ACCOUNT_ID)"
	@echo -e "$(GREEN)✅ State refreshed$(NC)"

drift-check-all: make-scripts-executable ## Check drift across all regions for account
	@echo -e "$(BLUE)🔍 Checking drift across all regions for account $(ACCOUNT_ID)...$(NC)"
	@for region in us-east-1 us-west-1 ap-south-1 cn-north-1 cn-northwest-1; do \
		echo -e "$(YELLOW)🌍 Checking $$region...$(NC)"; \
		make drift-check REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
		echo -e "$(BLUE)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(NC)"; \
	done
	@echo -e "$(GREEN)✅ All regions checked$(NC)"

test-all-notifications: make-scripts-executable ## Test all notification systems comprehensively
	@echo -e "$(CYAN)🔔 COMPREHENSIVE NOTIFICATION TESTING$(NC)"
	@echo -e "$(CYAN)═══════════════════════════════════════$(NC)"
	@TEST_MESSAGE="🧪 **Test Notification from Terraform Pipeline**\n\n**Region:** $(REGION)\n**Account:** $(ACCOUNT_ID)\n**Timestamp:** $(shell date)\n\nThis is a test of the notification system. All channels should receive this message."
	@echo -e "$(BLUE)Testing all notification channels...$(NC)"
	@TESTS_PASSED=0; TESTS_FAILED=0; \
	if [ -f "$(SLACK_NOTIFY_SCRIPT)" ]; then \
		echo -e "$(YELLOW)📱 Testing Slack notification...$(NC)"; \
		if $(SLACK_NOTIFY_SCRIPT) "info" "$$TEST_MESSAGE" 2>/dev/null; then \
			echo -e "$(GREEN)  ✅ Slack test passed$(NC)"; \
			TESTS_PASSED=$$((TESTS_PASSED + 1)); \
		else \
			echo -e "$(RED)  ❌ Slack test failed$(NC)"; \
			TESTS_FAILED=$$((TESTS_FAILED + 1)); \
		fi; \
	else \
		echo -e "$(RED)❌ Slack notification script not found$(NC)"; \
		TESTS_FAILED=$$((TESTS_FAILED + 1)); \
	fi; \
	if [ -f "$(EMAIL_NOTIFY_SCRIPT)" ]; then \
		echo -e "$(YELLOW)📧 Testing email notification...$(NC)"; \
		if $(EMAIL_NOTIFY_SCRIPT) "info" "$$TEST_MESSAGE" 2>/dev/null; then \
			echo -e "$(GREEN)  ✅ Email test passed$(NC)"; \
			TESTS_PASSED=$$((TESTS_PASSED + 1)); \
		else \
			echo -e "$(RED)  ❌ Email test failed$(NC)"; \
			TESTS_FAILED=$$((TESTS_FAILED + 1)); \
		fi; \
	else \
		echo -e "$(RED)❌ Email notification script not found$(NC)"; \
		TESTS_FAILED=$$((TESTS_FAILED + 1)); \
	fi; \
	if [ -f "$(WEBEX_NOTIFY_SCRIPT)" ]; then \
		echo -e "$(YELLOW)💬 Testing Webex notification...$(NC)"; \
		if $(WEBEX_NOTIFY_SCRIPT) "info" "$$TEST_MESSAGE" 2>/dev/null; then \
			echo -e "$(GREEN)  ✅ Webex test passed$(NC)"; \
			TESTS_PASSED=$$((TESTS_PASSED + 1)); \
		else \
			echo -e "$(RED)  ❌ Webex test failed$(NC)"; \
			TESTS_FAILED=$$((TESTS_FAILED + 1)); \
		fi; \
	else \
		echo -e "$(RED)❌ Webex notification script not found$(NC)"; \
		TESTS_FAILED=$$((TESTS_FAILED + 1)); \
	fi; \
	if [ -f "$(TEAMS_NOTIFY_SCRIPT)" ]; then \
		echo -e "$(YELLOW)🟦 Testing Teams notification...$(NC)"; \
		if $(TEAMS_NOTIFY_SCRIPT) "info" "$$TEST_MESSAGE" 2>/dev/null; then \
			echo -e "$(GREEN)  ✅ Teams test passed$(NC)"; \
			TESTS_PASSED=$$((TESTS_PASSED + 1)); \
		else \
			echo -e "$(RED)  ❌ Teams test failed$(NC)"; \
			TESTS_FAILED=$$((TESTS_FAILED + 1)); \
		fi; \
	else \
		echo -e "$(RED)❌ Teams notification script not found$(NC)"; \
		TESTS_FAILED=$$((TESTS_FAILED + 1)); \
	fi; \
	echo -e "$(CYAN)═══════════════════════════════════════$(NC)"; \
	echo -e "$(BLUE)📊 Test Summary:$(NC)"; \
	echo -e "  $(GREEN)✅ Passed: $$TESTS_PASSED$(NC)"; \
	echo -e "  $(RED)❌ Failed: $$TESTS_FAILED$(NC)"; \
	if [ $$TESTS_PASSED -gt 0 ]; then \
		echo -e "$(GREEN)✅ Notification testing completed successfully$(NC)"; \
	else \
		echo -e "$(RED)❌ All notification tests failed - check your configurations$(NC)"; \
		exit 1; \
	fi

status: ## Show current status and configuration
	@echo -e "$(CYAN)================================================================$(NC)"
	@echo -e "$(BLUE)           TERRAFORM INFRASTRUCTURE STATUS$(NC)"
	@echo -e "$(CYAN)================================================================$(NC)"
	@echo -e "$(GREEN)Configuration:$(NC)"
	@echo -e "  Region: $(YELLOW)$(REGION)$(NC)"
	@echo -e "  Account ID: $(YELLOW)$(ACCOUNT_ID)$(NC)"
	@echo -e "  State Bucket: $(YELLOW)$(STATE_BUCKET)-$(ACCOUNT_ID)$(NC)"
	@echo -e "  Action: $(YELLOW)$(ACTION)$(NC)"
	@echo -e ""
	@echo -e "$(GREEN)Scripts Status:$(NC)"
	@for script in $(DRIFT_DETECTION_SCRIPT) $(DRIFT_MONITORING_SCRIPT) $(SLACK_NOTIFY_SCRIPT) $(EMAIL_NOTIFY_SCRIPT) $(APPROVAL_NOTIFY_SCRIPT) $(WEBEX_NOTIFY_SCRIPT) $(TEAMS_NOTIFY_SCRIPT); do \
		if [ -f "$$script" ]; then \
			if [ -x "$$script" ]; then \
				echo -e "  $(GREEN)✅ $$script (executable)$(NC)"; \
			else \
				echo -e "  $(YELLOW)⚠️  $$script (not executable)$(NC)"; \
			fi; \
		else \
			echo -e "  $(RED)❌ $$script (missing)$(NC)"; \
		fi; \
	done
	@echo -e ""
	@echo -e "$(GREEN)Notification Environment Variables:$(NC)"
	@echo -e "  📱 SLACK_WEBHOOK_URL: $(if $(SLACK_WEBHOOK_URL),$(GREEN)✅ Configured$(NC),$(RED)❌ Not set$(NC))"
	@echo -e "  📧 EMAIL_RECIPIENT: $(if $(EMAIL_RECIPIENT),$(GREEN)✅ $(EMAIL_RECIPIENT)$(NC),$(RED)❌ Not set$(NC))"
	@echo -e "  📧 SMTP_SERVER: $(if $(SMTP_SERVER),$(GREEN)✅ $(SMTP_SERVER)$(NC),$(RED)❌ Not set$(NC))"
	@echo -e "  💬 WEBEX_WEBHOOK_URL: $(if $(WEBEX_WEBHOOK_URL),$(GREEN)✅ Configured$(NC),$(RED)❌ Not set$(NC))"
	@echo -e "  💬 WEBEX_ACCESS_TOKEN: $(if $(WEBEX_ACCESS_TOKEN),$(GREEN)✅ Configured$(NC),$(RED)❌ Not set$(NC))"
	@echo -e "  🟦 TEAMS_WEBHOOK_URL: $(if $(TEAMS_WEBHOOK_URL),$(GREEN)✅ Configured$(NC),$(RED)❌ Not set$(NC))"
	@echo -e ""
	@echo -e "$(GREEN)Tools Status:$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		echo -e "  $(GREEN)✅ Terraform: $$(terraform version | head -1)$(NC)"; \
	else \
		echo -e "  $(RED)❌ Terraform: Not installed$(NC)"; \
	fi
	@if command -v tfsec >/dev/null 2>&1; then \
		echo -e "  $(GREEN)✅ tfsec: $$(tfsec --version | head -1)$(NC)"; \
	else \
		echo -e "  $(RED)❌ tfsec: Not installed$(NC)"; \
	fi
	@if command -v infracost >/dev/null 2>&1; then \
		echo -e "  $(GREEN)✅ infracost: $$(infracost --version)$(NC)"; \
	else \
		echo -e "  $(RED)❌ infracost: Not installed$(NC)"; \
	fi
	@echo -e "$(CYAN)================================================================$(NC)"

# Helper targets for notification sending
send-success-notification:
	@SUCCESS_MESSAGE="✅ **Terraform Apply Successful**\n\n**Region:** $(REGION)\n**Account:** $(ACCOUNT_ID)\n**Timestamp:** $(shell date)\n\nDeployment completed successfully!"
	@if [ -f "$(SLACK_NOTIFY_SCRIPT)" ]; then $(SLACK_NOTIFY_SCRIPT) "success" "$$SUCCESS_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(WEBEX_NOTIFY_SCRIPT)" ]; then $(WEBEX_NOTIFY_SCRIPT) "success" "$$SUCCESS_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(TEAMS_NOTIFY_SCRIPT)" ]; then $(TEAMS_NOTIFY_SCRIPT) "success" "$$SUCCESS_MESSAGE" 2>/dev/null || true; fi

send-destroy-notification:
	@DESTROY_MESSAGE="🗑️ **Terraform Resources Destroyed**\n\n**Region:** $(REGION)\n**Account:** $(ACCOUNT_ID)\n**Timestamp:** $(shell date)\n\nAll resources have been successfully destroyed."
	@if [ -f "$(SLACK_NOTIFY_SCRIPT)" ]; then $(SLACK_NOTIFY_SCRIPT) "warning" "$$DESTROY_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(WEBEX_NOTIFY_SCRIPT)" ]; then $(WEBEX_NOTIFY_SCRIPT) "warning" "$$DESTROY_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(TEAMS_NOTIFY_SCRIPT)" ]; then $(TEAMS_NOTIFY_SCRIPT) "warning" "$$DESTROY_MESSAGE" 2>/dev/null || true; fi

send-multiregion-start-notification:
	@MULTIREGION_START_MESSAGE="🌍 **Multi-Region Deployment Started**\n\n**Account:** $(ACCOUNT_ID)\n**Regions:** us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1\n**Started:** $(shell date)\n\nDeploying to all regions..."
	@if [ -f "$(SLACK_NOTIFY_SCRIPT)" ]; then $(SLACK_NOTIFY_SCRIPT) "info" "$$MULTIREGION_START_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(WEBEX_NOTIFY_SCRIPT)" ]; then $(WEBEX_NOTIFY_SCRIPT) "info" "$$MULTIREGION_START_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(TEAMS_NOTIFY_SCRIPT)" ]; then $(TEAMS_NOTIFY_SCRIPT) "info" "$$MULTIREGION_START_MESSAGE" 2>/dev/null || true; fi

send-multiregion-complete-notification:
	@MULTIREGION_COMPLETE_MESSAGE="🌍 **Multi-Region Deployment Completed**\n\n**Account:** $(ACCOUNT_ID)\n**Regions:** ✅ us-east-1, ✅ us-west-1, ✅ ap-south-1, ✅ cn-north-1, ✅ cn-northwest-1\n**Completed:** $(shell date)\n\nAll regions deployed successfully!"
	@if [ -f "$(SLACK_NOTIFY_SCRIPT)" ]; then $(SLACK_NOTIFY_SCRIPT) "success" "$$MULTIREGION_COMPLETE_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(WEBEX_NOTIFY_SCRIPT)" ]; then $(WEBEX_NOTIFY_SCRIPT) "success" "$$MULTIREGION_COMPLETE_MESSAGE" 2>/dev/null || true; fi
	@if [ -f "$(TEAMS_NOTIFY_SCRIPT)" ]; then $(TEAMS_NOTIFY_SCRIPT) "success" "$$MULTIREGION_COMPLETE_MESSAGE" 2>/dev/null || true; fi

# Advanced targets for specific scenarios
china-deploy: ## Deploy to China regions only
	@echo -e "$(PURPLE)🇨🇳 Deploying to China regions...$(NC)"
	@for region in cn-north-1 cn-northwest-1; do \
		echo -e "$(GREEN)📍 Deploying to $$region...$(NC)"; \
		make plan REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
		make apply REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
	done

us-deploy: ## Deploy to US regions only
	@echo -e "$(PURPLE)🇺🇸 Deploying to US regions...$(NC)"
	@for region in us-east-1 us-west-1; do \
		echo -e "$(GREEN)📍 Deploying to $$region...$(NC)"; \
		make plan REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
		make apply REGION=$$region ACCOUNT_ID=$(ACCOUNT_ID); \
	done

emergency-drift-check: make-scripts-executable ## Emergency drift check with critical alerts
	@echo -e "$(RED)🚨 EMERGENCY DRIFT CHECK$(NC)"
	@DRIFT_THRESHOLD=1 make drift-check REGION=$(REGION) ACCOUNT_ID=$(ACCOUNT_ID)

setup: ## Initial setup - install tools and configure
	@echo -e "$(CYAN)🔧 Setting up Terraform infrastructure tools...$(NC)"
	@echo -e "$(YELLOW)This will install required tools (requires sudo)$(NC)"
	@echo -e "$(YELLOW)Continue? (y/N):$(NC)"
	@read -r confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo -e "$(GREEN)Installing tools...$(NC)"; \
		curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -; \
		sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $$(lsb_release -cs) main"; \
		sudo apt-get update && sudo apt-get install terraform; \
		curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash; \
		curl -fsSL https://raw.githubusercontent.com/infracost/infracost/master/scripts/install.sh | sh; \
		echo -e "$(GREEN)✅ Setup completed$(NC)"; \
	else \
		echo -e "$(YELLOW)Setup cancelled$(NC)"; \
	fi