#!/bin/bash

# drift-detection.sh - Enhanced drift detection with multi-channel notifications
# Supports: Slack, Email, Webex, Microsoft Teams
# Features: Threshold alerts, HTML reports, comprehensive logging

set -e

REGION=${1:-us-east-1}
ACCOUNT_ID=${2:-123456789012}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DRIFT_REPORT_DIR="drift-reports"
DRIFT_THRESHOLD=${DRIFT_THRESHOLD:-5}

# Colors for enhanced terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Enhanced header with build information
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"
echo -e "${WHITE}🔍 TERRAFORM DRIFT DETECTION ENGINE 🔍${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"
echo -e "${BLUE}📍 Region: ${REGION}${NC}"
echo -e "${BLUE}🏢 Account: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}⚠️  Drift Threshold: ${DRIFT_THRESHOLD}${NC}"
echo -e "${BLUE}🕐 Started: $(date)${NC}"
echo -e "${BLUE}🏗️  Build: ${BUILD_NUMBER:-Manual}${NC}"
echo -e "${BLUE}👤 User: ${BUILD_USER:-$(whoami)}${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"

# Create enhanced drift reports directory structure
mkdir -p ${DRIFT_REPORT_DIR}/{html,json,logs}

# Initialize Terraform with enhanced logging
echo -e "${YELLOW}🔄 Initializing Terraform infrastructure...${NC}"
if make init REGION=${REGION} ACCOUNT_ID=${ACCOUNT_ID} >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform initialization successful${NC}"
else
    echo -e "${RED}❌ Terraform initialization failed${NC}"
    exit 1
fi

# Refresh state with progress indication
echo -e "${YELLOW}🔄 Refreshing Terraform state (this may take a moment)...${NC}"
if terraform refresh \
    -var="region=${REGION}" \
    -var="account_id=${ACCOUNT_ID}" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ State refresh completed${NC}"
else
    echo -e "${RED}❌ State refresh failed${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Generating comprehensive drift analysis...${NC}"

# Enhanced file naming with metadata
PLAN_OUTPUT_FILE="${DRIFT_REPORT_DIR}/logs/drift_${REGION}_${ACCOUNT_ID}_${TIMESTAMP}.log"
HTML_REPORT_FILE="${DRIFT_REPORT_DIR}/html/drift_${REGION}_${ACCOUNT_ID}_${TIMESTAMP}.html"
JSON_REPORT_FILE="${DRIFT_REPORT_DIR}/json/drift_${REGION}_${ACCOUNT_ID}_${TIMESTAMP}.json"

# Run terraform plan with comprehensive output capture
set +e
terraform plan \
    -var="region=${REGION}" \
    -var="account_id=${ACCOUNT_ID}" \
    -detailed-exitcode \
    -no-color \
    -out="drift_${TIMESTAMP}.tfplan" > "${PLAN_OUTPUT_FILE}" 2>&1

PLAN_EXIT_CODE=$?
set -e

# Enhanced JSON report generation
generate_json_report() {
    local status=$1
    local drift_count=$2
    local plan_file=$3
    
    cat > "${JSON_REPORT_FILE}" << EOF
{
    "metadata": {
        "region": "${REGION}",
        "account_id": "${ACCOUNT_ID}",
        "timestamp": "$(date -Iseconds)",
        "build_number": "${BUILD_NUMBER:-null}",
        "build_user": "${BUILD_USER:-$(whoami)}",
        "drift_threshold": ${DRIFT_THRESHOLD},
        "terraform_version": "$(terraform version -json | jq -r '.terraform_version' 2>/dev/null || echo 'unknown')"
    },
    "drift_detection": {
        "status": "${status}",
        "exit_code": ${PLAN_EXIT_CODE},
        "drift_count": ${drift_count},
        "threshold_exceeded": $([ ${drift_count} -ge ${DRIFT_THRESHOLD} ] && echo "true" || echo "false"),
        "plan_file": "${plan_file}",
        "log_file": "${PLAN_OUTPUT_FILE}",
        "html_report": "${HTML_REPORT_FILE}"
    },
    "execution": {
        "started_at": "$(date -Iseconds)",
        "duration_seconds": ${SECONDS},
        "command": "terraform plan -detailed-exitcode"
    }
}
EOF
}

# Enhanced HTML report generation with modern styling
generate_html_report() {
    local status=$1
    local log_file=$2
    local html_file=$3
    local drift_count=${4:-0}
    
    # Determine status styling
    local status_class=""
    local status_icon=""
    local status_color=""
    case ${status} in
        "success")
            status_class="success"
            status_icon="✅"
            status_color="#28a745"
            ;;
        "warning")
            status_class="warning"
            status_icon="⚠️"
            status_color="#ffc107"
            ;;
        "error")
            status_class="error"
            status_icon="❌"
            status_color="#dc3545"
            ;;
    esac
    
    cat > "${html_file}" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drift Detection Report - ${REGION} (${ACCOUNT_ID})</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 40px;
            border-radius: 20px;
            text-align: center;
            margin-bottom: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }
        
        .header h1 {
            font-size: 3em;
            margin-bottom: 15px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .header-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 30px;
        }
        
        .info-card {
            background: rgba(255, 255, 255, 0.8);
            padding: 20px;
            border-radius: 15px;
            text-align: center;
            backdrop-filter: blur(5px);
            transition: transform 0.3s ease;
        }
        
        .info-card:hover { transform: translateY(-5px); }
        .info-label { font-size: 0.9em; color: #666; margin-bottom: 8px; font-weight: 500; }
        .info-value { font-size: 1.4em; font-weight: bold; color: #333; }
        
        .status-section {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 40px;
            border-radius: 20px;
            margin-bottom: 30px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            border-left: 8px solid ${status_color};
        }
        
        .status-title {
            font-size: 2em;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 15px;
            color: ${status_color};
        }
        
        .drift-metrics {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        
        .metric-card {
            background: #f8f9fa;
            padding: 25px;
            border-radius: 15px;
            text-align: center;
            border: 2px solid #e9ecef;
            transition: all 0.3s ease;
        }
        
        .metric-card:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.1);
        }
        
        .metric-number {
            font-size: 2.5em;
            font-weight: bold;
            color: ${status_color};
            margin-bottom: 10px;
        }
        
        .metric-label { font-size: 1.1em; color: #666; font-weight: 500; }
        
        .actions-section {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin: 30px 0;
        }
        
        .btn {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
            padding: 15px 25px;
            border: none;
            border-radius: 12px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            font-size: 1em;
        }
        
        .btn:hover { transform: translateY(-2px); box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2); }
        .btn-primary { background: linear-gradient(135deg, #007bff, #0056b3); color: white; }
        .btn-success { background: linear-gradient(135deg, #28a745, #1e7e34); color: white; }
        .btn-warning { background: linear-gradient(135deg, #ffc107, #e0a800); color: #212529; }
        .btn-danger { background: linear-gradient(135deg, #dc3545, #c82333); color: white; }
        
        .log-section {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            margin-top: 30px;
        }
        
        .log-content {
            background: #1e1e1e;
            color: #f8f8f2;
            padding: 25px;
            border-radius: 10px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.9em;
            line-height: 1.6;
            max-height: 600px;
            overflow-y: auto;
            white-space: pre-wrap;
            border: 1px solid #333;
        }
        
        .footer {
            text-align: center;
            margin-top: 40px;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            padding: 25px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        }
        
        .footer p { margin-bottom: 8px; color: #666; }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin: 20px 0;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, ${status_color}, ${status_color}aa);
            width: $([ ${drift_count} -ge ${DRIFT_THRESHOLD} ] && echo "100" || echo "$(( drift_count * 100 / DRIFT_THRESHOLD ))")%;
            transition: width 1s ease;
        }
        
        @media (max-width: 768px) {
            .container { padding: 10px; }
            .header { padding: 20px; }
            .status-section { padding: 20px; }
            .header h1 { font-size: 2em; }
        }
        
        .notification-status {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            margin: 20px 0;
        }
        
        .notification-card {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            text-align: center;
            border: 2px solid #e9ecef;
        }
        
        .notification-icon { font-size: 1.5em; margin-bottom: 8px; }
        .notification-label { font-size: 0.9em; color: #666; }
    </style>
    <script>
        function toggleLog() {
            var logContent = document.getElementById('log-content');
            var toggleBtn = document.getElementById('toggle-btn');
            if (logContent.style.display === 'none' || logContent.style.display === '') {
                logContent.style.display = 'block';
                toggleBtn.innerHTML = '<i class="fas fa-eye-slash"></i> Hide Terraform Plan';
            } else {
                logContent.style.display = 'none';
                toggleBtn.innerHTML = '<i class="fas fa-eye"></i> Show Terraform Plan';
            }
        }
        
        function downloadReport() {
            var element = document.createElement('a');
            var content = document.getElementById('log-content').textContent;
            element.setAttribute('href', 'data:text/plain;charset=utf-8,' + encodeURIComponent(content));
            element.setAttribute('download', 'drift-report-${REGION}-${ACCOUNT_ID}-${TIMESTAMP}.txt');
            element.style.display = 'none';
            document.body.appendChild(element);
            element.click();
            document.body.removeChild(element);
        }
        
        function copyToClipboard() {
            var content = document.getElementById('log-content').textContent;
            navigator.clipboard.writeText(content).then(function() {
                var btn = document.getElementById('copy-btn');
                var original = btn.innerHTML;
                btn.innerHTML = '<i class="fas fa-check"></i> Copied!';
                setTimeout(function() { btn.innerHTML = original; }, 2000);
            });
        }
        
        // Auto-refresh every 5 minutes for live monitoring
        setTimeout(function() {
            if (confirm('Refresh drift detection report?')) {
                location.reload();
            }
        }, 300000);
    </script>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${status_icon} Terraform Drift Detection</h1>
            <div class="header-grid">
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-globe"></i> Region</div>
                    <div class="info-value">${REGION}</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-building"></i> Account ID</div>
                    <div class="info-value">${ACCOUNT_ID}</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-clock"></i> Timestamp</div>
                    <div class="info-value">$(date '+%H:%M:%S')</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-flag"></i> Status</div>
                    <div class="info-value">${status^^}</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-hashtag"></i> Build</div>
                    <div class="info-value">${BUILD_NUMBER:-Manual}</div>
                </div>
            </div>
        </div>
        
        <div class="status-section">
            <div class="status-title">
                ${status_icon} ${status^^} - DRIFT DETECTION RESULTS
            </div>
            
EOF
    
    case ${status} in
        "success")
            cat >> "${html_file}" << EOF
            <p style="font-size: 1.2em; margin-bottom: 20px;"><strong>✅ No configuration drift detected!</strong> Your infrastructure perfectly matches the expected configuration.</p>
            
            <div class="drift-metrics">
                <div class="metric-card">
                    <div class="metric-number">0</div>
                    <div class="metric-label">Resources to Change</div>
                </div>
                <div class="metric-card">
                    <div class="metric-number">${drift_count}</div>
                    <div class="metric-label">Consecutive Clean Checks</div>
                </div>
                <div class="metric-card">
                    <div class="metric-number">${DRIFT_THRESHOLD}</div>
                    <div class="metric-label">Alert Threshold</div>
                </div>
            </div>
            
            <div style="background: #d4edda; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3 style="color: #155724; margin-bottom: 10px;"><i class="fas fa-shield-alt"></i> Infrastructure Status: HEALTHY</h3>
                <p><strong>All systems are operating as expected.</strong> No action required at this time.</p>
                <p style="margin-top: 10px;"><i class="fas fa-info-circle"></i> Counter has been reset to 0 due to successful check.</p>
            </div>
EOF
            ;;
        "warning")
            cat >> "${html_file}" << EOF
            <p style="font-size: 1.2em; margin-bottom: 20px;"><strong>⚠️ Configuration drift detected!</strong> Your infrastructure has deviated from the expected configuration.</p>
            
            <div class="drift-metrics">
                <div class="metric-card">
                    <div class="metric-number">${drift_count}</div>
                    <div class="metric-label">Current Drift Count</div>
                </div>
                <div class="metric-card">
                    <div class="metric-number">${DRIFT_THRESHOLD}</div>
                    <div class="metric-label">Alert Threshold</div>
                </div>
                <div class="metric-card">
                    <div class="metric-number">$(( (DRIFT_THRESHOLD - drift_count > 0) ? DRIFT_THRESHOLD - drift_count : 0 ))</div>
                    <div class="metric-label">Checks Until Critical</div>
                </div>
            </div>
            
            <div class="progress-bar">
                <div class="progress-fill"></div>
            </div>
            <p style="text-align: center; font-size: 0.9em; color: #666;">Drift Progress: ${drift_count}/${DRIFT_THRESHOLD}</p>
            
            $(if [ ${drift_count} -ge ${DRIFT_THRESHOLD} ]; then
                echo '<div style="background: #f8d7da; padding: 20px; border-radius: 10px; margin: 20px 0; border-left: 5px solid #dc3545;">'
                echo '<h3 style="color: #721c24; margin-bottom: 10px;"><i class="fas fa-exclamation-triangle"></i> 🚨 CRITICAL ALERT: THRESHOLD EXCEEDED!</h3>'
                echo '<p><strong>The drift threshold has been exceeded!</strong> Immediate attention and remediation required.</p>'
                echo '<p style="margin-top: 10px;"><i class="fas fa-bell"></i> Critical alerts have been sent to all notification channels.</p>'
                echo '</div>'
            else
                echo '<div style="background: #fff3cd; padding: 20px; border-radius: 10px; margin: 20px 0;">'
                echo '<h3 style="color: #856404; margin-bottom: 10px;"><i class="fas fa-exclamation-triangle"></i> Action Recommended</h3>'
                echo '<p><strong>Configuration drift detected but within acceptable limits.</strong> Consider reviewing and applying changes.</p>'
                echo '</div>'
            fi)
            
            <div style="background: #e7f3ff; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3 style="color: #0066cc; margin-bottom: 15px;"><i class="fas fa-tools"></i> Recommended Actions:</h3>
                <ul style="margin-left: 20px; line-height: 1.8;">
                    <li><strong>Review:</strong> Examine the terraform plan output below</li>
                    <li><strong>Validate:</strong> Ensure the changes are expected and safe</li>
                    <li><strong>Apply:</strong> Run <code>make apply REGION=${REGION} ACCOUNT_ID=${ACCOUNT_ID}</code></li>
                    <li><strong>Alternative:</strong> Update configuration to match current state</li>
                    <li><strong>Monitor:</strong> Set up automated drift monitoring</li>
                </ul>
            </div>
EOF
            ;;
        "error")
            cat >> "${html_file}" << EOF
            <p style="font-size: 1.2em; margin-bottom: 20px;"><strong>❌ Error occurred during drift detection!</strong> Unable to complete the drift analysis.</p>
            
            <div style="background: #f8d7da; padding: 20px; border-radius: 10px; margin: 20px 0;">
                <h3 style="color: #721c24; margin-bottom: 15px;"><i class="fas fa-bug"></i> Troubleshooting Steps:</h3>
                <ul style="margin-left: 20px; line-height: 1.8;">
                    <li><strong>Credentials:</strong> Verify AWS credentials and permissions</li>
                    <li><strong>Configuration:</strong> Check terraform configuration syntax</li>
                    <li><strong>Backend:</strong> Ensure backend state is accessible</li>
                    <li><strong>Network:</strong> Check connectivity to AWS and backend</li>
                    <li><strong>Resources:</strong> Verify required resources exist</li>
                    <li><strong>Logs:</strong> Review detailed error logs below</li>
                </ul>
            </div>
EOF
            ;;
    esac
    
    cat >> "${html_file}" << EOF
            
            <div class="actions-section">
                <button id="toggle-btn" class="btn btn-primary" onclick="toggleLog()">
                    <i class="fas fa-eye"></i> Show Terraform Plan
                </button>
                <button id="copy-btn" class="btn btn-success" onclick="copyToClipboard()">
                    <i class="fas fa-copy"></i> Copy to Clipboard
                </button>
                <button class="btn btn-warning" onclick="downloadReport()">
                    <i class="fas fa-download"></i> Download Report
                </button>
                $(if [ "${status}" = "warning" ]; then
                    echo '<a href="#" class="btn btn-danger" onclick="alert(\"Run: make apply REGION='${REGION}' ACCOUNT_ID='${ACCOUNT_ID}'\")"><i class="fas fa-play"></i> Apply Changes</a>'
                fi)
            </div>
        </div>
        
        <div class="log-section">
            <h2><i class="fas fa-terminal"></i> Terraform Plan Output</h2>
            <div id="log-content" class="log-content" style="display: none;">$(cat ${log_file} | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g')</div>
        </div>
        
        <div class="footer">
            <p><strong><i class="fas fa-cogs"></i> Generated by Terraform Infrastructure Pipeline</strong></p>
            <p><i class="fas fa-fingerprint"></i> Report ID: drift_${REGION}_${ACCOUNT_ID}_${TIMESTAMP}</p>
            <p><i class="fas fa-clock"></i> Generated: $(date)</p>
            <p><i class="fas fa-user"></i> Build User: ${BUILD_USER:-$(whoami)}</p>
            $([ -n "${BUILD_URL}" ] && echo "<p><i class=\"fas fa-link\"></i> Jenkins Build: <a href=\"${BUILD_URL}\" target=\"_blank\">${BUILD_URL}</a></p>")
        </div>
    </div>
</body>
</html>
EOF
}

# Function to send notifications to all channels
send_notifications() {
    local notification_type=$1
    local message=$2
    local notification_count=0
    
    echo -e "${CYAN}📢 Sending ${notification_type} notifications to all channels...${NC}"
    
    # Send Slack notification
    if [ -f "./scripts/slack-notify.sh" ]; then
        if ./scripts/slack-notify.sh "${notification_type}" "${message}" 2>/dev/null; then
            echo -e "${GREEN}  ✅ Slack notification sent${NC}"
            notification_count=$((notification_count + 1))
        else
            echo -e "${YELLOW}  ⚠️ Slack notification failed${NC}"
        fi
    fi
    
    # Send Webex notification
    if [ -f "./scripts/webex-notify.sh" ]; then
        if ./scripts/webex-notify.sh "${notification_type}" "${message}" 2>/dev/null; then
            echo -e "${GREEN}  ✅ Webex notification sent${NC}"
            notification_count=$((notification_count + 1))
        else
            echo -e "${YELLOW}  ⚠️ Webex notification failed${NC}"
        fi
    fi
    
    # Send Teams notification
    if [ -f "./scripts/teams-notify.sh" ]; then
        if ./scripts/teams-notify.sh "${notification_type}" "${message}" 2>/dev/null; then
            echo -e "${GREEN}  ✅ Teams notification sent${NC}"
            notification_count=$((notification_count + 1))
        else
            echo -e "${YELLOW}  ⚠️ Teams notification failed${NC}"
        fi
    fi
    
    # Send Email notification
    if [ -f "./scripts/email-notify.sh" ]; then
        if ./scripts/email-notify.sh "${notification_type}" "${message}" 2>/dev/null; then
            echo -e "${GREEN}  ✅ Email notification sent${NC}"
            notification_count=$((notification_count + 1))
        else
            echo -e "${YELLOW}  ⚠️ Email notification failed${NC}"
        fi
    fi
    
    echo -e "${BLUE}📊 Notification Summary: ${notification_count}/4 channels notified${NC}"
    return $notification_count
}

# Process results based on exit code
case ${PLAN_EXIT_CODE} in
    0)
        echo -e "${GREEN}✅ No drift detected in ${REGION} (${ACCOUNT_ID})${NC}"
        
        # Reset drift counter
        DRIFT_COUNT_FILE="${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}"
        echo "0" > "${DRIFT_COUNT_FILE}"
        DRIFT_COUNT=0
        
        # Generate reports
        generate_html_report "success" "${PLAN_OUTPUT_FILE}" "${HTML_REPORT_FILE}" "${DRIFT_COUNT}"
        generate_json_report "success" "${DRIFT_COUNT}" "${PLAN_OUTPUT_FILE}"
        
        # Send success notification
        SUCCESS_MESSAGE="✅ **Drift Detection: All Clear**

**Region:** ${REGION}
**Account:** ${ACCOUNT_ID}
**Status:** No configuration drift detected
**Timestamp:** $(date)

Infrastructure is healthy and matches expected configuration.

**Report:** ${HTML_REPORT_FILE}
**Build:** ${BUILD_NUMBER:-Manual execution}"

        send_notifications "success" "${SUCCESS_MESSAGE}"
        ;;
    1)
        echo -e "${RED}❌ Error occurred during drift detection${NC}"
        cat "${PLAN_OUTPUT_FILE}"
        
        DRIFT_COUNT_FILE="${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}"
        DRIFT_COUNT=$(cat "${DRIFT_COUNT_FILE}" 2>/dev/null || echo "0")
        
        # Generate reports
        generate_html_report "error" "${PLAN_OUTPUT_FILE}" "${HTML_REPORT_FILE}" "${DRIFT_COUNT}"
        generate_json_report "error" "${DRIFT_COUNT}" "${PLAN_OUTPUT_FILE}"
        
        # Send error notification
        ERROR_MESSAGE="❌ **Drift Detection Error**

**Region:** ${REGION}
**Account:** ${ACCOUNT_ID}
**Status:** Error during drift detection
**Error Code:** ${PLAN_EXIT_CODE}
**Timestamp:** $(date)

Please review the logs and resolve the underlying issue.

**Report:** ${HTML_REPORT_FILE}
**Log File:** ${PLAN_OUTPUT_FILE}"

        send_notifications "error" "${ERROR_MESSAGE}"
        
        exit 1
        ;;
    2)
        echo -e "${YELLOW}⚠️  Configuration drift detected in ${REGION} (${ACCOUNT_ID})${NC}"
        
        # Increment drift counter
        DRIFT_COUNT_FILE="${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}"
        CURRENT_COUNT=$(cat "${DRIFT_COUNT_FILE}" 2>/dev/null || echo "0")
        NEW_COUNT=$((CURRENT_COUNT + 1))
        echo "${NEW_COUNT}" > "${DRIFT_COUNT_FILE}"
        
        echo -e "${YELLOW}📊 Drift count: ${NEW_COUNT}/${DRIFT_THRESHOLD}${NC}"
        
        # Generate reports
        generate_html_report "warning" "${PLAN_OUTPUT_FILE}" "${HTML_REPORT_FILE}" "${NEW_COUNT}"
        generate_json_report "warning" "${NEW_COUNT}" "${PLAN_OUTPUT_FILE}"
        
        # Check if drift threshold exceeded
        if [ ${NEW_COUNT} -ge ${DRIFT_THRESHOLD} ]; then
            echo -e "${RED}🚨 CRITICAL: Drift threshold (${DRIFT_THRESHOLD}) exceeded!${NC}"
            
            # Send critical alert to all channels
            CRITICAL_MESSAGE="🚨 **CRITICAL DRIFT ALERT**

**Region:** ${REGION}
**Account:** ${ACCOUNT_ID}
**Drift Count:** ${NEW_COUNT}/${DRIFT_THRESHOLD} ⚠️ **THRESHOLD EXCEEDED**
**Severity:** CRITICAL
**Timestamp:** $(date)

**🚨 IMMEDIATE ACTION REQUIRED**

The drift threshold has been exceeded, indicating persistent configuration drift. This requires immediate investigation and remediation.

**Next Steps:**
1. Review the drift report immediately
2. Identify the source of configuration changes
3. Apply terraform changes or update configuration
4. Implement preventive measures

**Reports:**
📊 HTML Report: ${HTML_REPORT_FILE}
📋 JSON Report: ${JSON_REPORT_FILE}
📝 Log File: ${PLAN_OUTPUT_FILE}

**Build:** ${BUILD_NUMBER:-Manual execution}
**Pipeline:** ${BUILD_URL:-Not available}"

            send_notifications "critical" "${CRITICAL_MESSAGE}"
            
        else
            # Send warning notification
            WARNING_MESSAGE="⚠️ **Configuration Drift Detected**

**Region:** ${REGION}
**Account:** ${ACCOUNT_ID}
**Drift Count:** ${NEW_COUNT}/${DRIFT_THRESHOLD}
**Status:** Within threshold limits
**Timestamp:** $(date)

Configuration drift has been detected in your infrastructure. Review and action recommended.

**Drift Analysis:**
• Current Count: ${NEW_COUNT}
• Threshold: ${DRIFT_THRESHOLD}
• Remaining: $((DRIFT_THRESHOLD - NEW_COUNT)) checks until critical

**Action Items:**
1. Review the terraform plan for changes
2. Verify if changes are expected
3. Apply corrections if needed
4. Monitor for recurring drift

**Reports:**
📊 HTML Report: ${HTML_REPORT_FILE}
📋 JSON Report: ${JSON_REPORT_FILE}

**Build:** ${BUILD_NUMBER:-Manual execution}"

            send_notifications "warning" "${WARNING_MESSAGE}"
        fi
        
        echo -e "${YELLOW}📄 Check the detailed reports:${NC}"
        echo -e "${YELLOW}  📊 HTML: ${HTML_REPORT_FILE}${NC}"
        echo -e "${YELLOW}  📋 JSON: ${JSON_REPORT_FILE}${NC}"
        ;;
esac

# Cleanup temporary files
rm -f "drift_${TIMESTAMP}.tfplan"

# Enhanced summary with execution metrics
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"
echo -e "${WHITE}📋 DRIFT DETECTION SUMMARY${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"
echo -e "${BLUE}🌍 Region: ${REGION}${NC}"
echo -e "${BLUE}🏢 Account: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}📊 Status: $(case ${PLAN_EXIT_CODE} in 0) echo "✅ NO DRIFT";; 1) echo "❌ ERROR";; 2) echo "⚠️ DRIFT DETECTED";; esac)${NC}"
echo -e "${BLUE}⏱️  Execution Time: ${SECONDS} seconds${NC}"
echo -e "${BLUE}🎯 Threshold: ${DRIFT_THRESHOLD}${NC}"
echo -e "${BLUE}📈 Current Count: $(cat "${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}" 2>/dev/null || echo "0")${NC}"
echo -e "${BLUE}📄 HTML Report: ${HTML_REPORT_FILE}${NC}"
echo -e "${BLUE}📋 JSON Report: ${JSON_REPORT_FILE}${NC}"
echo -e "${BLUE}📝 Log File: ${PLAN_OUTPUT_FILE}${NC}"
echo -e "${BLUE}🕐 Completed: $(date)${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..80})${NC}"

# Create summary for external consumption
cat > "${DRIFT_REPORT_DIR}/latest_${REGION}_${ACCOUNT_ID}.json" << EOF
{
    "region": "${REGION}",
    "account_id": "${ACCOUNT_ID}",
    "status": "$(case ${PLAN_EXIT_CODE} in 0) echo "success";; 1) echo "error";; 2) echo "warning";; esac)",
    "drift_count": $(cat "${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}" 2>/dev/null || echo "0"),
    "drift_threshold": ${DRIFT_THRESHOLD},
    "threshold_exceeded": $([ $(cat "${DRIFT_REPORT_DIR}/.drift_count_${REGION}_${ACCOUNT_ID}" 2>/dev/null || echo "0") -ge ${DRIFT_THRESHOLD} ] && echo "true" || echo "false"),
    "last_check": "$(date -Iseconds)",
    "execution_time_seconds": ${SECONDS},
    "html_report": "${HTML_REPORT_FILE}",
    "json_report": "${JSON_REPORT_FILE}",
    "log_file": "${PLAN_OUTPUT_FILE}",
    "build_number": "${BUILD_NUMBER:-null}",
    "build_url": "${BUILD_URL:-null}"
}
EOF

echo -e "${GREEN}✅ Drift detection completed successfully${NC}"
echo -e "${BLUE}📊 Latest status available at: ${DRIFT_REPORT_DIR}/latest_${REGION}_${ACCOUNT_ID}.json${NC}"