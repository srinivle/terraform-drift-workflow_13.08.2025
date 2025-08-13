#!/bin/bash

# slack-notify.sh - Enhanced Slack notifications with rich formatting

STATUS=${1:-info}
MESSAGE=${2:-"No message provided"}
SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL:-""}

# Exit if no webhook URL configured
if [ -z "${SLACK_WEBHOOK_URL}" ]; then
    echo "SLACK_WEBHOOK_URL not configured, skipping Slack notification"
    exit 0
fi

# Colors and icons based on status
case ${STATUS} in
    "success")
        COLOR="good"
        ICON=":white_check_mark:"
        EMOJI="✅"
        TITLE="Success"
        ;;
    "warning")
        COLOR="warning"  
        ICON=":warning:"
        EMOJI="⚠️"
        TITLE="Warning - Drift Detected"
        ;;
    "error"|"failure")
        COLOR="danger"
        ICON=":x:"
        EMOJI="❌"
        TITLE="Error"
        ;;
    "critical")
        COLOR="danger"
        ICON=":rotating_light:"
        EMOJI="🚨"
        TITLE="CRITICAL ALERT"
        ;;
    "approval")
        COLOR="#439FE0"
        ICON=":point_right:"
        EMOJI="👉"
        TITLE="Approval Required"
        ;;
    *)
        COLOR="#439FE0"
        ICON=":information_source:"
        EMOJI="ℹ️"
        TITLE="Information"
        ;;
esac

# Get additional context
TIMESTAMP=$(date)
BUILD_URL=${BUILD_URL:-"Not available"}
JENKINS_USER=${BUILD_USER:-"Jenkins"}
REGION=${REGION:-"Multiple"}
ACCOUNT_ID=${ACCOUNT_ID:-"Multiple"}

# Create rich Slack message
SLACK_PAYLOAD=$(cat << EOF
{
    "username": "Terraform Bot",
    "icon_emoji": ":terraform:",
    "attachments": [
        {
            "color": "${COLOR}",
            "pretext": "${EMOJI} *${TITLE}*",
            "title": "Terraform Infrastructure Pipeline",
            "title_link": "${BUILD_URL}",
            "text": "${MESSAGE}",
            "fields": [
                {
                    "title": "Region",
                    "value": "${REGION}",
                    "short": true
                },
                {
                    "title": "Account ID",
                    "value": "${ACCOUNT_ID}",
                    "short": true
                },
                {
                    "title": "Build Number",
                    "value": "${BUILD_NUMBER:-N/A}",
                    "short": true
                },
                {
                    "title": "Triggered By",
                    "value": "${JENKINS_USER}",
                    "short": true
                }
            ],
            "footer": "Terraform Pipeline",
            "footer_icon": "https://www.terraform.io/assets/images/logo-hashicorp-3f10732f.svg",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
fi

# Send notification with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=$(curl -s -o /tmp/slack_response.txt -w "%{http_code}" \
        -X POST \
        -H 'Content-type: application/json' \
        --data "${SLACK_PAYLOAD}" \
        "${SLACK_WEBHOOK_URL}")
    
    if [ "$HTTP_STATUS" -eq 200 ]; then
        echo "✅ Slack notification sent successfully"
        echo "   Status: ${STATUS}"
        echo "   Region: ${REGION}"
        echo "   Account: ${ACCOUNT_ID}"
        echo "   Timestamp: ${TIMESTAMP}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️  Slack notification failed (attempt ${RETRY_COUNT}/${MAX_RETRIES})"
        echo "   HTTP Status: ${HTTP_STATUS}"
        
        if [ -f /tmp/slack_response.txt ]; then
            echo "   Response: $(cat /tmp/slack_response.txt)"
        fi
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "   Retrying in 3 seconds..."
            sleep 3
        else
            echo "❌ Failed to send Slack notification after ${MAX_RETRIES} attempts"
            exit 1
        fi
    fi
done

# Cleanup
rm -f /tmp/slack_response.txt

# Enhanced payload for critical alerts
if [ "${STATUS}" = "critical" ]; then
    SLACK_PAYLOAD=$(cat << EOF
{
    "username": "Terraform Bot",
    "icon_emoji": ":rotating_light:",
    "text": "<!channel> ${EMOJI} *CRITICAL TERRAFORM ALERT*",
    "attachments": [
        {
            "color": "danger",
            "title": "🚨 IMMEDIATE ACTION REQUIRED",
            "title_link": "${BUILD_URL}",
            "text": "${MESSAGE}",
            "fields": [
                {
                    "title": "Priority",
                    "value": "🔴 CRITICAL",
                    "short": true
                },
                {
                    "title": "Region",
                    "value": "${REGION}",
                    "short": true
                },
                {
                    "title": "Account ID",
                    "value": "${ACCOUNT_ID}",
                    "short": true
                },
                {
                    "title": "Alert Time",
                    "value": "${TIMESTAMP}",
                    "short": true
                }
            ],
            "actions": [
                {
                    "type": "button",
                    "text": "View Build",
                    "url": "${BUILD_URL}",
                    "style": "danger"
                },
                {
                    "type": "button",
                    "text": "View Logs",
                    "url": "${BUILD_URL}console",
                    "style": "primary"
                }
            ],
            "footer": "Terraform Critical Alert System",
            "ts": $(date +%s)
        }
    ]
}
EOF
)
fi

# Enhanced payload for approval requests
if [ "${STATUS}" = "approval" ]; then
    SLACK_PAYLOAD=$(cat << EOF
{
    "username": "Terraform Bot",
    "icon_emoji": ":point_right:",
    "text": "${EMOJI} *Terraform Approval Required*",
    "attachments": [
        {
            "color": "#439FE0",
            "title": "📋 Deployment Awaiting Approval",
            "title_link": "${BUILD_URL}",
            "text": "${MESSAGE}",
            "fields": [
                {
                    "title": "Action",
                    "value": "${ACTION:-apply}",
                    "short": true
                },
                {
                    "title": "Region",
                    "value": "${REGION}",
                    "short": true
                },
                {
                    "title": "Account ID",
                    "value": "${ACCOUNT_ID}",
                    "short": true
                },
                {
                    "title": "Requested By",
                    "value": "${JENKINS_USER}",
                    "short": true
                }
            ],
            "actions": [
                {
                    "type": "button",
                    "text": "🔍 Review & Approve",
                    "url": "${BUILD_URL}",
                    "style": "primary"
                },
                {
                    "type": "button",
                    "text": "📋 View Plan",
                    "url": "${BUILD_URL}artifact/",
                    "style": "default"
                }
            ],
            "footer": "Terraform Approval System",
            "ts": $(date +%s)
        }
    ]
}
EOF
)