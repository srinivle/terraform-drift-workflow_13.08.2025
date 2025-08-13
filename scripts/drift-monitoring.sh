#!/bin/bash

# drift-monitoring.sh - Comprehensive multi-region drift monitoring with all notification channels
# Features: Real-time dashboard, multi-channel notifications, detailed analytics

set -e

ACCOUNT_ID=${1:-123456789012}
REGIONS=("us-east-1" "us-west-1" "ap-south-1" "cn-north-1" "cn-northwest-1")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
MONITORING_REPORT_DIR="drift-reports/monitoring"
OVERALL_STATUS="success"
DRIFT_SUMMARY=""

# Enhanced colors for better terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Enhanced header with build context
echo -e "${CYAN}$(printf '═%.0s' {1..90})${NC}"
echo -e "${WHITE}🔍 TERRAFORM MULTI-REGION DRIFT MONITORING DASHBOARD 🔍${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..90})${NC}"
echo -e "${BLUE}🏢 Account ID: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}🌍 Regions: ${#REGIONS[@]} regions (${REGIONS[*]})${NC}"
echo -e "${BLUE}🕐 Started: $(date)${NC}"
echo -e "${BLUE}🏗️  Build: ${BUILD_NUMBER:-Manual}${NC}"
echo -e "${BLUE}👤 User: ${BUILD_USER:-$(whoami)}${NC}"
echo -e "${BLUE}📊 Pipeline: ${JOB_NAME:-drift-monitoring}${NC}"
echo -e "${CYAN}$(printf '═%.0s' {1..90})${NC}"

# Create comprehensive monitoring reports directory structure
mkdir -p ${MONITORING_REPORT_DIR}/{html,json,csv,logs}

# Initialize comprehensive counters and tracking
TOTAL_REGIONS=0
SUCCESS_COUNT=0
WARNING_COUNT=0
ERROR_COUNT=0
CRITICAL_COUNT=0
TOTAL_DRIFT_COUNT=0

# Initialize monitoring report files with enhanced metadata
MONITORING_REPORT="${MONITORING_REPORT_DIR}/html/monitoring_${ACCOUNT_ID}_${TIMESTAMP}.html"
JSON_REPORT="${MONITORING_REPORT_DIR}/json/monitoring_${ACCOUNT_ID}_${TIMESTAMP}.json"
CSV_REPORT="${MONITORING_REPORT_DIR}/csv/monitoring_${ACCOUNT_ID}_${TIMESTAMP}.csv"
SUMMARY_REPORT="${MONITORING_REPORT_DIR}/summary_${ACCOUNT_ID}_${TIMESTAMP}.txt"

# Start comprehensive JSON report
cat > "${JSON_REPORT}" << EOF
{
    "metadata": {
        "account_id": "${ACCOUNT_ID}",
        "timestamp": "$(date -Iseconds)",
        "build_number": "${BUILD_NUMBER:-null}",
        "build_user": "${BUILD_USER:-$(whoami)}",
        "job_name": "${JOB_NAME:-drift-monitoring}",
        "build_url": "${BUILD_URL:-null}",
        "total_regions": ${#REGIONS[@]},
        "regions_list": $(printf '"%s",' "${REGIONS[@]}" | sed 's/,$//' | sed 's/^/[/' | sed 's/$/]/')
    },
    "regions": [
EOF

# Start enhanced CSV report with comprehensive headers
echo "Region,Status,DriftCount,LastCheck,ExecutionTime,ThresholdExceeded,Details,ErrorMessage,RecommendedAction" > "${CSV_REPORT}"

# Initialize comprehensive HTML dashboard
cat > "${MONITORING_REPORT}" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Drift Monitoring Dashboard - Account ${ACCOUNT_ID}</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .container { max-width: 1600px; margin: 0 auto; padding: 20px; }
        
        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(15px);
            padding: 40px;
            border-radius: 25px;
            text-align: center;
            margin-bottom: 30px;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
        }
        
        .header h1 {
            font-size: 3.5em;
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
            padding: 25px;
            border-radius: 15px;
            text-align: center;
            backdrop-filter: blur(5px);
            transition: all 0.3s ease;
            border: 2px solid transparent;
        }
        
        .info-card:hover { 
            transform: translateY(-8px); 
            border-color: #667eea;
            box-shadow: 0 15px 35px rgba(102, 126, 234, 0.3);
        }
        
        .info-label { font-size: 0.9em; color: #666; margin-bottom: 10px; font-weight: 600; }
        .info-value { font-size: 1.6em; font-weight: bold; color: #333; }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
            gap: 25px;
            margin-bottom: 40px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(15px);
            padding: 30px;
            border-radius: 20px;
            text-align: center;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
            border-left: 5px solid #e9ecef;
        }
        
        .stat-card:hover {
            transform: translateY(-10px);
            box-shadow: 0 30px 60px rgba(0, 0, 0, 0.15);
        }
        
        .stat-number {
            font-size: 3.5em;
            font-weight: bold;
            margin-bottom: 15px;
            background: linear-gradient(135deg, var(--stat-color), var(--stat-color-light));
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
        }
        
        .stat-label {
            font-size: 1.2em;
            color: #666;
            font-weight: 600;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 10px;
        }
        
        .success-stat { --stat-color: #28a745; --stat-color-light: #40d062; border-left-color: #28a745; }
        .warning-stat { --stat-color: #ffc107; --stat-color-light: #ffcd39; border-left-color: #ffc107; }
        .error-stat { --stat-color: #dc3545; --stat-color-light: #e4556d; border-left-color: #dc3545; }
        .info-stat { --stat-color: #17a2b8; --stat-color-light: #3fc3d8; border-left-color: #17a2b8; }
        
        .regions-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(450px, 1fr));
            gap: 30px;
            margin-bottom: 40px;
        }
        
        .region-card {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(15px);
            border-radius: 20px;
            overflow: hidden;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            transition: all 0.3s ease;
        }
        
        .region-card:hover {
            transform: translateY(-8px);
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.15);
        }
        
        .region-header {
            padding: 25px;
            font-weight: bold;
            font-size: 1.4em;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .region-content { padding: 0 25px 25px 25px; }
        
        .status-success {
            background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%);
            color: #155724;
        }
        
        .status-warning {
            background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%);
            color: #856404;
        }
        
        .status-error {
            background: linear-gradient(135deg, #f8d7da 0%, #f1c2c7 100%);
            color: #721c24;
        }
        
        .status-critical {
            background: linear-gradient(135deg, #f8d7da 0%, #dc3545 100%);
            color: #721c24;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.8; }
            100% { opacity: 1; }
        }
        
        .details-toggle {
            background: linear-gradient(135deg, #007bff 0%, #0056b3 100%);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            margin-top: 15px;
            font-weight: 600;
            transition: all 0.3s ease;
            box-shadow: 0 4px 15px rgba(0, 123, 255, 0.3);
        }
        
        .details-toggle:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 25px rgba(0, 123, 255, 0.4);
        }
        
        .details-content {
            display: none;
            background: #1e1e1e;
            color: #f8f8f2;
            padding: 20px;
            border-radius: 15px;
            margin-top: 15px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.85em;
            max-height: 400px;
            overflow-y: auto;
            border: 1px solid #333;
            white-space: pre-wrap;
        }
        
        .footer {
            text-align: center;
            margin-top: 50px;
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(15px);
            padding: 30px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }
        
        .footer p { margin-bottom: 10px; color: #666; }
        
        .action-buttons {
            display: flex;
            justify-content: center;
            gap: 15px;
            flex-wrap: wrap;
            margin-top: 20px;
        }
        
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 25px;
            font-weight: 600;
            text-decoration: none;
            transition: all 0.3s ease;
            cursor: pointer;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn:hover { transform: translateY(-3px); }
        .btn-primary { background: linear-gradient(135deg, #007bff, #0056b3); color: white; }
        .btn-success { background: linear-gradient(135deg, #28a745, #1e7e34); color: white; }
        .btn-warning { background: linear-gradient(135deg, #ffc107, #e0a800); color: #212529; }
        .btn-info { background: linear-gradient(135deg, #17a2b8, #138496); color: white; }
        
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 10px;
            animation: blink 2s infinite;
        }
        
        .indicator-success { background: #28a745; }
        .indicator-warning { background: #ffc107; }
        .indicator-error { background: #dc3545; }
        .indicator-critical { background: #dc3545; animation: blink 0.5s infinite; }
        
        @keyframes blink {
            0%, 50% { opacity: 1; }
            51%, 100% { opacity: 0.3; }
        }
        
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e9ecef;
            border-radius: 10px;
            overflow: hidden;
            margin: 15px 0;
        }
        
        .progress-fill {
            height: 100%;
            transition: width 1s ease;
            border-radius: 10px;
        }
        
        .alert-banner {
            background: linear-gradient(135deg, #dc3545, #c82333);
            color: white;
            padding: 20px;
            border-radius: 15px;
            margin-bottom: 30px;
            text-align: center;
            animation: shake 0.5s infinite;
            display: none;
        }
        
        @keyframes shake {
            0%, 100% { transform: translateX(0); }
            25% { transform: translateX(-5px); }
            75% { transform: translateX(5px); }
        }
        
        @media (max-width: 768px) {
            .container { padding: 10px; }
            .stats-grid { grid-template-columns: 1fr; }
            .regions-grid { grid-template-columns: 1fr; }
            .header h1 { font-size: 2.5em; }
            .action-buttons { flex-direction: column; align-items: center; }
        }
    </style>
    <script>
        function toggleDetails(regionId) {
            var details = document.getElementById('details-' + regionId);
            var button = document.getElementById('button-' + regionId);
            if (details.style.display === 'none' || details.style.display === '') {
                details.style.display = 'block';
                button.innerHTML = '<i class="fas fa-eye-slash"></i> Hide Details';
            } else {
                details.style.display = 'none';
                button.innerHTML = '<i class="fas fa-eye"></i> Show Details';
            }
        }
        
        function refreshPage() {
            document.body.style.opacity = '0.5';
            location.reload();
        }
        
        function downloadJSON() {
            window.open('./monitoring_${ACCOUNT_ID}_${TIMESTAMP}.json', '_blank');
        }
        
        function downloadCSV() {
            window.open('./monitoring_${ACCOUNT_ID}_${TIMESTAMP}.csv', '_blank');
        }
        
        function showAlert(message, type) {
            var alertBanner = document.querySelector('.alert-banner');
            alertBanner.innerHTML = '<i class="fas fa-exclamation-triangle"></i> ' + message;
            alertBanner.style.display = 'block';
            if (type === 'critical') {
                alertBanner.style.animation = 'shake 0.5s infinite';
            }
        }
        
        // Auto-refresh every 5 minutes
        setTimeout(function() {
            showAlert('Auto-refreshing drift monitoring dashboard...', 'info');
            setTimeout(refreshPage, 3000);
        }, 300000);
        
        // Update timestamps every minute
        setInterval(function() {
            document.getElementById('last-updated').textContent = new Date().toLocaleString();
        }, 60000);
    </script>
</head>
<body>
    <div class="container">
        <div class="alert-banner" id="alert-banner">
            <!-- Critical alerts will appear here -->
        </div>
        
        <div class="header animate__animated animate__fadeInDown">
            <h1><i class="fas fa-radar"></i> Terraform Drift Monitoring</h1>
            <div class="header-grid">
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-building"></i> Account ID</div>
                    <div class="info-value">${ACCOUNT_ID}</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-clock"></i> Last Updated</div>
                    <div class="info-value" id="last-updated">$(date '+%H:%M:%S')</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-globe"></i> Total Regions</div>
                    <div class="info-value">${#REGIONS[@]}</div>
                </div>
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-heartbeat"></i> Status</div>
                    <div class="info-value" id="overall-status"><i class="fas fa-spinner fa-spin"></i> Scanning...</div>
                </div>
                $([ -n "${BUILD_NUMBER}" ] && echo '
                <div class="info-card">
                    <div class="info-label"><i class="fas fa-hashtag"></i> Build</div>
                    <div class="info-value">'${BUILD_NUMBER}'</div>
                </div>')
            </div>
        </div>
        
        <div class="stats-grid animate__animated animate__fadeInUp" id="stats-container">
            <!-- Stats will be populated by JavaScript -->
        </div>
        
        <div class="regions-grid animate__animated animate__fadeInUp" id="regions-container">
            <!-- Region cards will be populated by JavaScript -->
        </div>
        
        <div class="footer animate__animated animate__fadeInUp">
            <p><strong><i class="fas fa-cogs"></i> Terraform Infrastructure Pipeline</strong></p>
            <p><i class="fas fa-fingerprint"></i> Report ID: monitoring_${ACCOUNT_ID}_${TIMESTAMP}</p>
            <p><i class="fas fa-user"></i> Build User: ${BUILD_USER:-$(whoami)} | <i class="fas fa-calendar"></i> Generated: $(date)</p>
            $([ -n "${BUILD_URL}" ] && echo '<p><i class="fas fa-link"></i> Jenkins Build: <a href="'${BUILD_URL}'" target="_blank">'${BUILD_URL}'</a></p>')
            
            <div class="action-buttons">
                <button class="btn btn-primary" onclick="refreshPage()">
                    <i class="fas fa-sync-alt"></i> Refresh Now
                </button>
                <button class="btn btn-info" onclick="downloadJSON()">
                    <i class="fas fa-download"></i> Download JSON
                </button>
                <button class="btn btn-success" onclick="downloadCSV()">
                    <i class="fas fa-file-csv"></i> Download CSV
                </button>
                <a href="${BUILD_URL:-#}" class="btn btn-warning" target="_blank">
                    <i class="fas fa-external-link-alt"></i> View Pipeline
                </a>
            </div>
        </div>
    </div>
    
    <script>
        var monitoringData = [];
EOF

# Enhanced region monitoring with comprehensive error handling
FIRST_REGION=true
for region in "${REGIONS[@]}"; do
    echo -e "${PURPLE}$(printf '━%.0s' {1..90})${NC}"
    echo -e "${YELLOW}🌍 Monitoring region: ${region}${NC}"
    
    TOTAL_REGIONS=$((TOTAL_REGIONS + 1))
    REGION_START_TIME=$SECONDS
    
    # Run comprehensive drift detection for this region
    set +e
    REGION_LOG="${MONITORING_REPORT_DIR}/logs/region_${region}_${ACCOUNT_ID}_${TIMESTAMP}.log"
    echo -e "${CYAN}  └─ Running enhanced drift detection...${NC}"
    
    # Capture both stdout and stderr with timestamps
    {
        echo "=== DRIFT DETECTION START: $(date) ==="
        echo "Region: ${region}"
        echo "Account: ${ACCOUNT_ID}"
        echo "Threshold: ${DRIFT_THRESHOLD:-5}"
        echo "Build: ${BUILD_NUMBER:-Manual}"
        echo "=== EXECUTING TERRAFORM COMMANDS ==="
        
        ./scripts/drift-detection.sh "${region}" "${ACCOUNT_ID}" 2>&1
        
        echo "=== DRIFT DETECTION END: $(date) ==="
    } > "${REGION_LOG}" 2>&1
    
    DRIFT_EXIT_CODE=$?
    REGION_EXECUTION_TIME=$((SECONDS - REGION_START_TIME))
    set -e
    
    # Get comprehensive drift information
    DRIFT_COUNT_FILE="drift-reports/.drift_count_${region}_${ACCOUNT_ID}"
    DRIFT_COUNT=$(cat "${DRIFT_COUNT_FILE}" 2>/dev/null || echo "0")
    LAST_CHECK=$(date -Iseconds)
    
    # Determine detailed status and recommendations
    STATUS=""
    STATUS_TEXT=""
    STATUS_ICON=""
    THRESHOLD_EXCEEDED="false"
    RECOMMENDED_ACTION=""
    ERROR_MESSAGE=""
    
    case ${DRIFT_EXIT_CODE} in
        0)
            echo -e "${GREEN}  └─ ✅ ${region}: No drift detected (${REGION_EXECUTION_TIME}s)${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            STATUS="success"
            STATUS_TEXT="No Drift"
            STATUS_ICON="✅"
            RECOMMENDED_ACTION="Continue monitoring"
            ;;
        2)
            echo -e "${YELLOW}  └─ ⚠️  ${region}: Configuration drift detected (${REGION_EXECUTION_TIME}s)${NC}"
            WARNING_COUNT=$((WARNING_COUNT + 1))
            OVERALL_STATUS="warning"
            STATUS="warning"
            STATUS_TEXT="Drift Detected"
            STATUS_ICON="⚠️"
            TOTAL_DRIFT_COUNT=$((TOTAL_DRIFT_COUNT + DRIFT_COUNT))
            RECOMMENDED_ACTION="Review and apply terraform changes"
            
            # Check for critical threshold
            if [ ${DRIFT_COUNT} -ge ${DRIFT_THRESHOLD:-5} ]; then
                CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
                STATUS="critical"
                STATUS_TEXT="Critical Drift"
                STATUS_ICON="🚨"
                THRESHOLD_EXCEEDED="true"
                RECOMMENDED_ACTION="IMMEDIATE ACTION REQUIRED - Apply fixes"
                echo -e "${RED}    ⚠️ CRITICAL: Drift threshold exceeded!${NC}"
            fi
            
            DRIFT_SUMMARY="${DRIFT_SUMMARY}\n  • ${region}: Drift detected (count: ${DRIFT_COUNT})"
            ;;
        *)
            echo -e "${RED}  └─ ❌ ${region}: Error during drift check (${REGION_EXECUTION_TIME}s)${NC}"
            ERROR_COUNT=$((ERROR_COUNT + 1))
            OVERALL_STATUS="error"
            STATUS="error"
            STATUS_TEXT="Check Failed"
            STATUS_ICON="❌"
            RECOMMENDED_ACTION="Investigate and resolve errors"
            ERROR_MESSAGE="Drift detection failed with exit code ${DRIFT_EXIT_CODE}"
            
            DRIFT_SUMMARY="${DRIFT_SUMMARY}\n  • ${region}: Error during check (exit code: ${DRIFT_EXIT_CODE})"
            ;;
    esac
    
    # Read and process log content for reports
    LOG_CONTENT=""
    if [ -f "${REGION_LOG}" ]; then
        # Get last 100 lines and escape for JSON/HTML
        LOG_CONTENT=$(tail -100 "${REGION_LOG}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\\'/g" | tr '\n' '\\n' | head -c 2000)
    fi
    
    # Add to JSON report
    if [ "${FIRST_REGION}" != true ]; then
        echo "," >> "${JSON_REPORT}"
    fi
    cat >> "${JSON_REPORT}" << EOF
    {
        "region": "${region}",
        "status": "${STATUS}",
        "drift_count": ${DRIFT_COUNT},
        "drift_threshold": ${DRIFT_THRESHOLD:-5},
        "threshold_exceeded": ${THRESHOLD_EXCEEDED},
        "last_check": "${LAST_CHECK}",
        "execution_time_seconds": ${REGION_EXECUTION_TIME},
        "recommended_action": "${RECOMMENDED_ACTION}",
        "error_message": "${ERROR_MESSAGE}",
        "log_excerpt": "${LOG_CONTENT}",
        "exit_code": ${DRIFT_EXIT_CODE}
    }
EOF
    FIRST_REGION=false
    
    # Add to CSV report with comprehensive data
    CSV_DETAILS=$(echo "${LOG_CONTENT}" | cut -c1-100 | tr '\n' ' ')
    echo "\"${region}\",\"${STATUS}\",\"${DRIFT_COUNT}\",\"${LAST_CHECK}\",\"${REGION_EXECUTION_TIME}s\",\"${THRESHOLD_EXCEEDED}\",\"${CSV_DETAILS}\",\"${ERROR_MESSAGE}\",\"${RECOMMENDED_ACTION}\"" >> "${CSV_REPORT}"
    
    # Add to HTML report with enhanced data
    cat >> "${MONITORING_REPORT}" << EOF
        monitoringData.push({
            region: '${region}',
            status: '${STATUS}',
            statusText: '${STATUS_TEXT}',
            statusIcon: '${STATUS_ICON}',
            driftCount: '${DRIFT_COUNT}',
            driftThreshold: '${DRIFT_THRESHOLD:-5}',
            thresholdExceeded: ${THRESHOLD_EXCEEDED},
            lastCheck: '${LAST_CHECK}',
            executionTime: '${REGION_EXECUTION_TIME}',
            recommendedAction: '${RECOMMENDED_ACTION}',
            errorMessage: '${ERROR_MESSAGE}',
            details: \`${LOG_CONTENT}\`
        });
EOF
    
    # Brief pause between region checks for system stability
    sleep 2
done

# Finalize JSON report
echo "    ]" >> "${JSON_REPORT}"

# Add comprehensive summary to JSON
cat >> "${JSON_REPORT}" << EOF
,
    "summary": {
        "overall_status": "${OVERALL_STATUS}",
        "total_regions": ${TOTAL_REGIONS},
        "success_count": ${SUCCESS_COUNT},
        "warning_count": ${WARNING_COUNT},
        "error_count": ${ERROR_COUNT},
        "critical_count": ${CRITICAL_COUNT},
        "total_drift_count": ${TOTAL_DRIFT_COUNT},
        "success_rate_percentage": $(( SUCCESS_COUNT * 100 / TOTAL_REGIONS )),
        "execution_time_seconds": ${SECONDS}
    },
    "execution_metadata": {
        "completed_at": "$(date -Iseconds)",
        "total_duration_seconds": ${SECONDS},
        "average_region_time_seconds": $(( SECONDS / TOTAL_REGIONS )),
        "build_number": "${BUILD_NUMBER:-null}",
        "build_url": "${BUILD_URL:-null}"
    }
}
EOF

# Complete comprehensive HTML report
cat >> "${MONITORING_REPORT}" << 'EOF'
        
        // Update comprehensive statistics
        document.getElementById('stats-container').innerHTML = `
            <div class="stat-card info-stat">
                <div class="stat-number">${monitoringData.length}</div>
                <div class="stat-label"><i class="fas fa-globe"></i> Total Regions</div>
            </div>
            <div class="stat-card success-stat">
                <div class="stat-number">${monitoringData.filter(d => d.status === 'success').length}</div>
                <div class="stat-label"><i class="fas fa-check-circle"></i> No Drift</div>
            </div>
            <div class="stat-card warning-stat">
                <div class="stat-number">${monitoringData.filter(d => d.status === 'warning').length}</div>
                <div class="stat-label"><i class="fas fa-exclamation-triangle"></i> Drift Detected</div>
            </div>
            <div class="stat-card error-stat">
                <div class="stat-number">${monitoringData.filter(d => d.status === 'error' || d.status === 'critical').length}</div>
                <div class="stat-label"><i class="fas fa-times-circle"></i> Issues Found</div>
            </div>
        `;
        
        // Update regions with enhanced information
        var regionsHtml = '';
        var hasCritical = false;
        
        monitoringData.forEach(function(data, index) {
            var progressWidth = Math.min((data.driftCount / data.driftThreshold) * 100, 100);
            var cardClass = data.status === 'critical' ? 'status-critical' : 'status-' + data.status;
            
            if (data.status === 'critical') {
                hasCritical = true;
            }
            
            regionsHtml += `
                <div class="region-card animate__animated animate__fadeInUp" style="animation-delay: ${index * 0.1}s">
                    <div class="region-header ${cardClass}">
                        <span class="status-indicator indicator-${data.status}"></span>
                        <span><i class="fas fa-globe"></i> ${data.region}</span>
                        <span style="margin-left: auto; font-size: 1.5em;">${data.statusIcon}</span>
                    </div>
                    <div class="region-content">
                        <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 15px; margin-bottom: 15px;">
                            <div>
                                <strong>Status:</strong> ${data.statusText}<br>
                                <strong>Drift Count:</strong> ${data.driftCount}/${data.driftThreshold}
                            </div>
                            <div>
                                <strong>Last Check:</strong> ${new Date(data.lastCheck).toLocaleString()}<br>
                                <strong>Duration:</strong> ${data.executionTime}s
                            </div>
                        </div>
                        
                        ${data.driftCount > 0 ? `
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: ${progressWidth}%; background: linear-gradient(90deg, 
                                ${data.status === 'critical' ? '#dc3545' : '#ffc107'}, 
                                ${data.status === 'critical' ? '#c82333' : '#e0a800'});"></div>
                        </div>
                        <p style="text-align: center; font-size: 0.85em; color: #666; margin-bottom: 10px;">
                            Drift Progress: ${data.driftCount}/${data.driftThreshold} 
                            ${data.thresholdExceeded ? '<span style="color: #dc3545; font-weight: bold;">⚠️ EXCEEDED</span>' : ''}
                        </p>` : ''}
                        
                        <p style="margin-bottom: 15px;"><strong>Recommended Action:</strong> ${data.recommendedAction}</p>
                        
                        ${data.errorMessage ? `<p style="color: #dc3545; margin-bottom: 15px;"><strong>Error:</strong> ${data.errorMessage}</p>` : ''}
                        
                        <button id="button-${index}" class="details-toggle" onclick="toggleDetails('${index}')">
                            <i class="fas fa-eye"></i> Show Details
                        </button>
                        <div id="details-${index}" class="details-content">${data.details}</div>
                    </div>
                </div>
            `;
        });
        
        document.getElementById('regions-container').innerHTML = regionsHtml;
        
        // Update overall status with enhanced logic
        var hasError = monitoringData.some(data => data.status === 'error');
        var hasWarning = monitoringData.some(data => data.status === 'warning');
        var hasCritical = monitoringData.some(data => data.status === 'critical');
        
        var overallStatusElement = document.getElementById('overall-status');
        if (hasCritical) {
            overallStatusElement.innerHTML = '<span style="color: #dc3545;"><i class="fas fa-exclamation-triangle"></i> CRITICAL</span>';
            showAlert('🚨 CRITICAL DRIFT DETECTED! Immediate action required on multiple regions.', 'critical');
        } else if (hasError) {
            overallStatusElement.innerHTML = '<span style="color: #dc3545;"><i class="fas fa-times-circle"></i> ERRORS</span>';
        } else if (hasWarning) {
            overallStatusElement.innerHTML = '<span style="color: #ffc107;"><i class="fas fa-exclamation-triangle"></i> DRIFT DETECTED</span>';
        } else {
            overallStatusElement.innerHTML = '<span style="color: #28a745;"><i class="fas fa-check-circle"></i> ALL CLEAR</span>';
        }
    </script>
</body>
</html>
EOF

# Generate comprehensive summary report
cat > "${SUMMARY_REPORT}" << EOF
TERRAFORM DRIFT MONITORING SUMMARY
==================================

EXECUTION DETAILS
-----------------
Account ID: ${ACCOUNT_ID}
Total Regions Monitored: ${TOTAL_REGIONS}
Execution Started: $(date -d "@$(($(date +%s) - SECONDS))")
Execution Completed: $(date)
Total Duration: ${SECONDS} seconds
Average Time per Region: $(( SECONDS / TOTAL_REGIONS )) seconds

BUILD INFORMATION
-----------------
Build Number: ${BUILD_NUMBER:-Manual execution}
Build User: ${BUILD_USER:-$(whoami)}
Job Name: ${JOB_NAME:-drift-monitoring}
Build URL: ${BUILD_URL:-Not available}

OVERALL STATUS: ${OVERALL_STATUS^^}
================================

SUMMARY STATISTICS
------------------
✅ Successful Checks: ${SUCCESS_COUNT}/${TOTAL_REGIONS} ($(( SUCCESS_COUNT * 100 / TOTAL_REGIONS ))%)
⚠️  Drift Detected: ${WARNING_COUNT}/${TOTAL_REGIONS} ($(( WARNING_COUNT * 100 / TOTAL_REGIONS ))%)
❌ Errors/Failures: ${ERROR_COUNT}/${TOTAL_REGIONS} ($(( ERROR_COUNT * 100 / TOTAL_REGIONS ))%)
🚨 Critical Issues: ${CRITICAL_COUNT}/${TOTAL_REGIONS} ($(( CRITICAL_COUNT * 100 / TOTAL_REGIONS ))%)

DRIFT ANALYSIS
--------------
Total Drift Count Across All Regions: ${TOTAL_DRIFT_COUNT}
Regions Requiring Attention: $(( WARNING_COUNT + ERROR_COUNT + CRITICAL_COUNT ))
Health Score: $(( SUCCESS_COUNT * 100 / TOTAL_REGIONS ))%

DETAILED ISSUES FOUND
---------------------$(if [ -n "${DRIFT_SUMMARY}" ]; then echo -e "${DRIFT_SUMMARY}"; else echo "  No issues detected"; fi)

REPORTS GENERATED
-----------------
📊 HTML Dashboard: ${MONITORING_REPORT}
📋 JSON Report: ${JSON_REPORT}
📈 CSV Export: ${CSV_REPORT}
📄 Summary Report: ${SUMMARY_REPORT}

RECOMMENDATIONS
---------------
$(if [ ${CRITICAL_COUNT} -gt 0 ]; then
    echo "🚨 IMMEDIATE ACTION REQUIRED:"
    echo "   - Critical drift thresholds have been exceeded"
    echo "   - Review and apply terraform changes immediately"
    echo "   - Investigate root cause of persistent drift"
elif [ ${WARNING_COUNT} -gt 0 ]; then
    echo "⚠️  ACTION RECOMMENDED:"
    echo "   - Configuration drift detected in ${WARNING_COUNT} region(s)"
    echo "   - Review terraform plans and apply changes"
    echo "   - Monitor for recurring drift patterns"
elif [ ${ERROR_COUNT} -gt 0 ]; then
    echo "❌ TROUBLESHOOTING REQUIRED:"
    echo "   - ${ERROR_COUNT} region(s) failed drift detection"
    echo "   - Check AWS credentials and permissions"
    echo "   - Verify terraform configuration and connectivity"
else
    echo "✅ NO ACTION REQUIRED:"
    echo "   - All regions are healthy and drift-free"
    echo "   - Continue regular monitoring schedule"
fi)

NEXT STEPS
----------
1. Review the HTML dashboard for detailed analysis
2. Investigate any critical or warning conditions
3. Apply necessary terraform changes
4. Schedule regular drift monitoring
5. Set up automated alerts for critical thresholds

Generated by Terraform Infrastructure Pipeline
Report ID: monitoring_${ACCOUNT_ID}_${TIMESTAMP}
EOF

# Print enhanced comprehensive summary
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"
echo -e "${WHITE}📊 COMPREHENSIVE DRIFT MONITORING RESULTS${NC}"
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"
echo -e "${BLUE}🏢 Account: ${ACCOUNT_ID}${NC}"
echo -e "${BLUE}📈 Overall Status: ${OVERALL_STATUS^^}${NC}"
echo -e "${BLUE}⏱️  Total Execution Time: ${SECONDS} seconds${NC}"
echo -e "${BLUE}📊 Success Rate: $(( SUCCESS_COUNT * 100 / TOTAL_REGIONS ))%${NC}"
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"
echo -e "${GREEN}✅ Successful: ${SUCCESS_COUNT}/${TOTAL_REGIONS} regions${NC}"
echo -e "${YELLOW}⚠️  Warnings: ${WARNING_COUNT}/${TOTAL_REGIONS} regions${NC}"
echo -e "${RED}❌ Errors: ${ERROR_COUNT}/${TOTAL_REGIONS} regions${NC}"
echo -e "${PURPLE}🚨 Critical: ${CRITICAL_COUNT}/${TOTAL_REGIONS} regions${NC}"

if [ -n "${DRIFT_SUMMARY}" ]; then
    echo -e "${YELLOW}🔍 Issues Summary:${NC}"
    echo -e "${DRIFT_SUMMARY}"
fi

echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"
echo -e "${BLUE}📁 Generated Reports:${NC}"
echo -e "  🌐 Interactive Dashboard: ${MONITORING_REPORT}"
echo -e "  📊 JSON Data Export: ${JSON_REPORT}"
echo -e "  📈 CSV Spreadsheet: ${CSV_REPORT}"
echo -e "  📄 Executive Summary: ${SUMMARY_REPORT}"
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"

# Send comprehensive multi-channel notifications
NOTIFICATION_MESSAGE="📊 **Comprehensive Drift Monitoring Complete**

**🏢 Account:** ${ACCOUNT_ID}
**📈 Overall Status:** ${OVERALL_STATUS^^}
**⏱️ Execution Time:** ${SECONDS} seconds

**📊 Summary:**
✅ Success: ${SUCCESS_COUNT}/${TOTAL_REGIONS} ($(( SUCCESS_COUNT * 100 / TOTAL_REGIONS ))%)
⚠️ Warnings: ${WARNING_COUNT}/${TOTAL_REGIONS} ($(( WARNING_COUNT * 100 / TOTAL_REGIONS ))%)
❌ Errors: ${ERROR_COUNT}/${TOTAL_REGIONS} ($(( ERROR_COUNT * 100 / TOTAL_REGIONS ))%)
🚨 Critical: ${CRITICAL_COUNT}/${TOTAL_REGIONS} ($(( CRITICAL_COUNT * 100 / TOTAL_REGIONS ))%)

**🎯 Health Score:** $(( SUCCESS_COUNT * 100 / TOTAL_REGIONS ))%
**📍 Total Regions:** us-east-1, us-west-1, ap-south-1, cn-north-1, cn-northwest-1

**📊 Dashboard:** ${MONITORING_REPORT}
**🏗️ Build:** ${BUILD_NUMBER:-Manual execution}"

if [ "${OVERALL_STATUS}" != "success" ]; then
    NOTIFICATION_MESSAGE="${NOTIFICATION_MESSAGE}

**⚠️ Issues Found:**${DRIFT_SUMMARY}"
fi

# Send notifications to all channels
NOTIFICATION_COUNT=0

echo -e "${CYAN}📢 Sending comprehensive notifications to all channels...${NC}"

# Send Slack notification
if [ -f "./scripts/slack-notify.sh" ]; then
    if ./scripts/slack-notify.sh "${OVERALL_STATUS}" "${NOTIFICATION_MESSAGE}" 2>/dev/null; then
        echo -e "${GREEN}  ✅ Slack notification sent${NC}"
        NOTIFICATION_COUNT=$((NOTIFICATION_COUNT + 1))
    else
        echo -e "${YELLOW}  ⚠️ Slack notification failed${NC}"
    fi
fi

# Send Webex notification
if [ -f "./scripts/webex-notify.sh" ]; then
    if ./scripts/webex-notify.sh "${OVERALL_STATUS}" "${NOTIFICATION_MESSAGE}" 2>/dev/null; then
        echo -e "${GREEN}  ✅ Webex notification sent${NC}"
        NOTIFICATION_COUNT=$((NOTIFICATION_COUNT + 1))
    else
        echo -e "${YELLOW}  ⚠️ Webex notification failed${NC}"
    fi
fi

# Send Teams notification
if [ -f "./scripts/teams-notify.sh" ]; then
    if ./scripts/teams-notify.sh "${OVERALL_STATUS}" "${NOTIFICATION_MESSAGE}" 2>/dev/null; then
        echo -e "${GREEN}  ✅ Teams notification sent${NC}"
        NOTIFICATION_COUNT=$((NOTIFICATION_COUNT + 1))
    else
        echo -e "${YELLOW}  ⚠️ Teams notification failed${NC}"
    fi
fi

# Send Email notification
if [ -f "./scripts/email-notify.sh" ]; then
    if ./scripts/email-notify.sh "${OVERALL_STATUS}" "${NOTIFICATION_MESSAGE}" 2>/dev/null; then
        echo -e "${GREEN}  ✅ Email notification sent${NC}"
        NOTIFICATION_COUNT=$((NOTIFICATION_COUNT + 1))
    else
        echo -e "${YELLOW}  ⚠️ Email notification failed${NC}"
    fi
fi

echo -e "${BLUE}📊 Notifications: ${NOTIFICATION_COUNT}/4 channels successful${NC}"

# Final status display
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"
if [ ${SUCCESS_COUNT} -eq ${TOTAL_REGIONS} ]; then
    echo -e "${GREEN}🎉 ALL REGIONS HEALTHY - No action required${NC}"
elif [ ${CRITICAL_COUNT} -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL ISSUES DETECTED - Immediate action required${NC}"
elif [ ${WARNING_COUNT} -gt 0 ]; then
    echo -e "${YELLOW}⚠️ DRIFT DETECTED - Review and action recommended${NC}"
else
    echo -e "${BLUE}📊 MONITORING COMPLETED - Review reports for details${NC}"
fi

echo -e "${WHITE}✅ Comprehensive drift monitoring completed successfully${NC}"
echo -e "${BLUE}🕐 Total execution time: ${SECONDS} seconds${NC}"
echo -e "${BLUE}📊 Average time per region: $(( SECONDS / TOTAL_REGIONS )) seconds${NC}"
echo -e "${CYAN}$(printf '━%.0s' {1..90})${NC}"

# Create latest status file for external monitoring
cat > "${MONITORING_REPORT_DIR}/latest_${ACCOUNT_ID}.json" << EOF
{
    "account_id": "${ACCOUNT_ID}",
    "last_monitoring": "$(date -Iseconds)",
    "overall_status": "${OVERALL_STATUS}",
    "success_count": ${SUCCESS_COUNT},
    "warning_count": ${WARNING_COUNT},
    "error_count": ${ERROR_COUNT},
    "critical_count": ${CRITICAL_COUNT},
    "total_regions": ${TOTAL_REGIONS},
    "health_score_percentage": $(( SUCCESS_COUNT * 100 / TOTAL_REGIONS )),
    "execution_time_seconds": ${SECONDS},
    "dashboard_url": "${MONITORING_REPORT}",
    "build_number": "${BUILD_NUMBER:-null}",
    "notifications_sent": ${NOTIFICATION_COUNT}
}
EOF

echo -e "${GREEN}📊 Latest monitoring status: ${MONITORING_REPORT_DIR}/latest_${ACCOUNT_ID}.json${NC}"