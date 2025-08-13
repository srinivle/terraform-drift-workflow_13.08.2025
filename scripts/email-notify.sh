#!/bin/bash

# email-notify.sh - Send email notifications

STATUS=${1:-info}
MESSAGE=${2:-"No message provided"}
RECIPIENT=${EMAIL_RECIPIENT:-"admin@company.com"}
SMTP_SERVER=${SMTP_SERVER:-"smtp.company.com"}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_USER=${SMTP_USER:-""}
SMTP_PASS=${SMTP_PASS:-""}

# Set subject based on status
case ${STATUS} in
    "success")
        SUBJECT="✅ Terraform Success - ${REGION:-Unknown} (${ACCOUNT_ID:-Unknown})"
        PRIORITY="Normal"
        ;;
    "warning")
        SUBJECT="⚠️  Terraform Warning - Drift Detected"
        PRIORITY="High"
        ;;
    "error"|"failure")
        SUBJECT="❌ Terraform Failure - Action Required"
        PRIORITY="High"
        ;;
    "critical")
        SUBJECT="🚨 CRITICAL: Terraform Drift Threshold Exceeded"
        PRIORITY="Urgent"
        ;;
    "approval")
        SUBJECT="📋 Terraform Approval Required"
        PRIORITY="Normal"
        ;;
    *)
        SUBJECT="ℹ️  Terraform Notification"
        PRIORITY="Normal"
        ;;
esac

# Create email content
EMAIL_CONTENT=$(cat << EOF
Subject: ${SUBJECT}
To: ${RECIPIENT}
MIME-Version: 1.0
Content-Type: text/html; charset=UTF-8
X-Priority: ${PRIORITY}

<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background: #f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .critical { color: #dc3545; font-weight: bold; }
        .approval { color: #007bff; }
        .content { background: #ffffff; padding: 20px; border: 1px solid #dee2e6; border-radius: 5px; }
        .footer { margin-top: 20px; font-size: 12px; color: #6c757d; }
        .message { background: #f8f9fa; padding: 15px; border-left: 4px solid #007bff; margin: 15px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Terraform Infrastructure Notification</h1>
        <p><strong>Status:</strong> <span class="${STATUS}">${STATUS^^}</span></p>
        <p><strong>Timestamp:</strong> $(date)</p>
        <p><strong>Region:</strong> ${REGION:-N/A}</p>
        <p><strong>Account ID:</strong> ${ACCOUNT_ID:-N/A}</p>
        <p><strong>Environment:</strong> ${ENVIRONMENT:-N/A}</p>
    </div>
    
    <div class="content">
        <h2>Details</h2>
        <div class="message">
            ${MESSAGE}
        </div>
        
        $(if [ "${STATUS}" = "approval" ]; then
            echo '<p><strong>Action Required:</strong> Please review and approve the deployment in Jenkins pipeline.</p>'
            echo '<p><a href="'${BUILD_URL:-#}'" style="background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Review & Approve</a></p>'
        fi)
    </div>
    
    <div class="footer">
        <p>This is an automated notification from the Terraform Infrastructure Pipeline.</p>
        <p>Build URL: ${BUILD_URL:-Not available}</p>
    </div>
</body>
</html>
EOF
)

# Send email using sendmail or curl (depending on setup)
if command -v sendmail >/dev/null 2>&1 && [ -n "${SMTP_SERVER}" ]; then
    echo "${EMAIL_CONTENT}" | sendmail -S "${SMTP_SERVER}:${SMTP_PORT}" -au"${SMTP_USER}" -ap"${SMTP_PASS}" "${RECIPIENT}"
    echo "Email notification sent to ${RECIPIENT}"
elif command -v curl >/dev/null 2>&1 && [ -n "${SMTP_SERVER}" ] && [ -n "${SMTP_USER}" ] && [ -n "${SMTP_PASS}" ]; then
    # Send via curl (for SMTP servers that support it)
    echo "${EMAIL_CONTENT}" | curl --url "smtps://${SMTP_SERVER}:${SMTP_PORT}" \
        --ssl-reqd \
        --mail-from "${SMTP_USER}" \
        --mail-rcpt "${RECIPIENT}" \
        --user "${SMTP_USER}:${SMTP_PASS}" \
        --upload-file -
    echo "Email notification sent via curl to ${RECIPIENT}"
else
    echo "Email notification skipped - sendmail/curl not configured or SMTP settings missing"
    echo "Configure SMTP_SERVER, SMTP_USER, SMTP_PASS, and EMAIL_RECIPIENT environment variables"
fi