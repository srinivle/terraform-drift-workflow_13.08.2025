#!/bin/bash

# webex-notify.sh - Enhanced Cisco Webex notifications with rich formatting

STATUS=${1:-info}
MESSAGE=${2:-"No message provided"}
WEBEX_WEBHOOK_URL=${WEBEX_WEBHOOK_URL:-""}
WEBEX_ROOM_ID=${WEBEX_ROOM_ID:-""}
WEBEX_ACCESS_TOKEN=${WEBEX_ACCESS_TOKEN:-""}

# Exit if no Webex configuration
if [ -z "${WEBEX_WEBHOOK_URL}" ] && [ -z "${WEBEX_ACCESS_TOKEN}" ]; then
    echo "Webex notification skipped - Neither WEBEX_WEBHOOK_URL nor WEBEX_ACCESS_TOKEN configured"
    exit 0
fi

# Colors and icons based on status
case ${STATUS} in
    "success")
        COLOR="Good"
        ICON="✅"
        EMOJI="✅"
        TITLE="Success"
        WEBEX_COLOR="#28a745"
        ;;
    "warning")
        COLOR="Warning"  
        ICON="⚠️"
        EMOJI="⚠️"
        TITLE="Warning - Drift Detected"
        WEBEX_COLOR="#ffc107"
        ;;
    "error"|"failure")
        COLOR="Attention"
        ICON="❌"
        EMOJI="❌"
        TITLE="Error"
        WEBEX_COLOR="#dc3545"
        ;;
    "critical")
        COLOR="Attention"
        ICON="🚨"
        EMOJI="🚨"
        TITLE="CRITICAL ALERT"
        WEBEX_COLOR="#dc3545"
        ;;
    "approval")
        COLOR="Good"
        ICON="📋"
        EMOJI="👉"
        TITLE="Approval Required"
        WEBEX_COLOR="#007bff"
        ;;
    *)
        COLOR="Good"
        ICON="ℹ️"
        EMOJI="ℹ️"
        TITLE="Information"
        WEBEX_COLOR="#17a2b8"
        ;;
esac

# Get additional context
TIMESTAMP=$(date)
BUILD_URL=${BUILD_URL:-"Not available"}
JENKINS_USER=${BUILD_USER:-"Jenkins"}
REGION=${REGION:-"Multiple"}
ACCOUNT_ID=${ACCOUNT_ID:-"Multiple"}
BUILD_NUMBER=${BUILD_NUMBER:-"N/A"}

# Function to send via webhook (Adaptive Cards)
send_via_webhook() {
    local webhook_url=$1
    
    # Create Adaptive Card payload for Webex
    local WEBEX_PAYLOAD=$(cat << EOF
{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.2",
        "body": [
            {
                "type": "Container",
                "style": "emphasis",
                "items": [
                    {
                        "type": "ColumnSet",
                        "columns": [
                            {
                                "type": "Column",
                                "width": "auto",
                                "items": [
                                    {
                                        "type": "Image",
                                        "url": "https://www.terraform.io/assets/images/logo-hashicorp-3f10732f.svg",
                                        "size": "Small"
                                    }
                                ]
                            },
                            {
                                "type": "Column",
                                "width": "stretch",
                                "items": [
                                    {
                                        "type": "TextBlock",
                                        "text": "${EMOJI} **${TITLE}**",
                                        "weight": "Bolder",
                                        "size": "Large",
                                        "color": "$(case ${STATUS} in success) echo Attention;; warning) echo Warning;; error|failure|critical) echo Attention;; *) echo Default;; esac)"
                                    },
                                    {
                                        "type": "TextBlock",
                                        "text": "Terraform Infrastructure Pipeline",
                                        "weight": "Lighter",
                                        "size": "Medium"
                                    }
                                ]
                            }
                        ]
                    }
                ]
            },
            {
                "type": "TextBlock",
                "text": "${MESSAGE}",
                "wrap": true,
                "spacing": "Medium"
            },
            {
                "type": "FactSet",
                "facts": [
                    {
                        "title": "Region:",
                        "value": "${REGION}"
                    },
                    {
                        "title": "Account ID:",
                        "value": "${ACCOUNT_ID}"
                    },
                    {
                        "title": "Build Number:",
                        "value": "${BUILD_NUMBER}"
                    },
                    {
                        "title": "Triggered By:",
                        "value": "${JENKINS_USER}"
                    },
                    {
                        "title": "Timestamp:",
                        "value": "${TIMESTAMP}"
                    }
                ],
                "spacing": "Medium"
            }$(if [ "${BUILD_URL}" != "Not available" ]; then
                cat << 'ACTIONS_EOF'
,
            {
                "type": "ActionSet",
                "actions": [
                    {
                        "type": "Action.OpenUrl",
                        "title": "🔍 View Build",
                        "url": "${BUILD_URL}"
                    },
                    {
                        "type": "Action.OpenUrl",
                        "title": "📋 View Console",
                        "url": "${BUILD_URL}console"
                    }
                ],
                "spacing": "Medium"
            }
ACTIONS_EOF
            fi)
        ]
    }
}
EOF
    )
    
    # Send the webhook
    curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        --data "${WEBEX_PAYLOAD}" \
        "${webhook_url}"
}

# Function to send via Bot API
send_via_api() {
    local access_token=$1
    local room_id=$2
    
    # Create markdown message for Webex API
    local MARKDOWN_MESSAGE=$(cat << EOF
${EMOJI} **${TITLE}**

**Terraform Infrastructure Pipeline**

${MESSAGE}

---

**Details:**
- **Region:** ${REGION}
- **Account ID:** ${ACCOUNT_ID}  
- **Build Number:** ${BUILD_NUMBER}
- **Triggered By:** ${JENKINS_USER}
- **Timestamp:** ${TIMESTAMP}

$(if [ "${BUILD_URL}" != "Not available" ]; then
    echo "**Actions:**"
    echo "- [🔍 View Build](${BUILD_URL})"
    echo "- [📋 View Console](${BUILD_URL}console)"
fi)
EOF
    )
    
    # Prepare API payload
    local API_PAYLOAD=$(cat << EOF
{
    "roomId": "${room_id}",
    "markdown": "${MARKDOWN_MESSAGE}"
}
EOF
    )
    
    # Send via Webex API
    curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
        -X POST \
        -H "Authorization: Bearer ${access_token}" \
        -H "Content-Type: application/json" \
        --data "${API_PAYLOAD}" \
        "https://webexapis.com/v1/messages"
}

# Enhanced payload for critical alerts
send_critical_alert() {
    local method=$1
    
    local CRITICAL_MESSAGE="🚨 **CRITICAL TERRAFORM ALERT** 🚨

⚠️ **IMMEDIATE ACTION REQUIRED** ⚠️

${MESSAGE}

**Priority:** 🔴 CRITICAL
**Alert Time:** ${TIMESTAMP}

This requires immediate investigation and resolution."

    if [ "$method" = "webhook" ]; then
        local CRITICAL_PAYLOAD=$(cat << EOF
{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.2",
        "body": [
            {
                "type": "Container",
                "style": "attention",
                "items": [
                    {
                        "type": "TextBlock",
                        "text": "🚨 **CRITICAL TERRAFORM ALERT**",
                        "weight": "Bolder",
                        "size": "Large",
                        "color": "Attention"
                    },
                    {
                        "type": "TextBlock",
                        "text": "⚠️ IMMEDIATE ACTION REQUIRED ⚠️",
                        "weight": "Bolder",
                        "size": "Medium",
                        "color": "Attention"
                    }
                ]
            },
            {
                "type": "TextBlock",
                "text": "${MESSAGE}",
                "wrap": true,
                "spacing": "Medium"
            },
            {
                "type": "FactSet",
                "facts": [
                    {
                        "title": "Priority:",
                        "value": "🔴 CRITICAL"
                    },
                    {
                        "title": "Region:",
                        "value": "${REGION}"
                    },
                    {
                        "title": "Account ID:",
                        "value": "${ACCOUNT_ID}"
                    },
                    {
                        "title": "Alert Time:",
                        "value": "${TIMESTAMP}"
                    }
                ],
                "spacing": "Medium"
            },
            {
                "type": "ActionSet",
                "actions": [
                    {
                        "type": "Action.OpenUrl",
                        "title": "🚨 View Build",
                        "url": "${BUILD_URL}",
                        "style": "destructive"
                    },
                    {
                        "type": "Action.OpenUrl",
                        "title": "📋 View Logs",
                        "url": "${BUILD_URL}console"
                    }
                ],
                "spacing": "Medium"
            }
        ]
    }
}
EOF
        )
        
        curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            --data "${CRITICAL_PAYLOAD}" \
            "${WEBEX_WEBHOOK_URL}"
    else
        # API method for critical alert
        local CRITICAL_API_PAYLOAD=$(cat << EOF
{
    "roomId": "${WEBEX_ROOM_ID}",
    "markdown": "${CRITICAL_MESSAGE}"
}
EOF
        )
        
        curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
            -X POST \
            -H "Authorization: Bearer ${WEBEX_ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "${CRITICAL_API_PAYLOAD}" \
            "https://webexapis.com/v1/messages"
    fi
}

# Enhanced payload for approval requests
send_approval_request() {
    local method=$1
    
    local APPROVAL_MESSAGE="📋 **Terraform Approval Required**

🔄 **Deployment Awaiting Approval**

${MESSAGE}

**Action:** ${ACTION:-apply}
**Region:** ${REGION}
**Account ID:** ${ACCOUNT_ID}
**Requested By:** ${JENKINS_USER}

Please review the terraform plan and approve the deployment."

    if [ "$method" = "webhook" ]; then
        local APPROVAL_PAYLOAD=$(cat << EOF
{
    "contentType": "application/vnd.microsoft.card.adaptive",
    "content": {
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "type": "AdaptiveCard",
        "version": "1.2",
        "body": [
            {
                "type": "Container",
                "style": "good",
                "items": [
                    {
                        "type": "TextBlock",
                        "text": "📋 **Terraform Approval Required**",
                        "weight": "Bolder",
                        "size": "Large"
                    },
                    {
                        "type": "TextBlock",
                        "text": "🔄 Deployment Awaiting Approval",
                        "weight": "Lighter",
                        "size": "Medium"
                    }
                ]
            },
            {
                "type": "TextBlock",
                "text": "${MESSAGE}",
                "wrap": true,
                "spacing": "Medium"
            },
            {
                "type": "FactSet",
                "facts": [
                    {
                        "title": "Action:",
                        "value": "${ACTION:-apply}"
                    },
                    {
                        "title": "Region:",
                        "value": "${REGION}"
                    },
                    {
                        "title": "Account ID:",
                        "value": "${ACCOUNT_ID}"
                    },
                    {
                        "title": "Requested By:",
                        "value": "${JENKINS_USER}"
                    }
                ],
                "spacing": "Medium"
            },
            {
                "type": "ActionSet",
                "actions": [
                    {
                        "type": "Action.OpenUrl",
                        "title": "🔍 Review & Approve",
                        "url": "${BUILD_URL}"
                    },
                    {
                        "type": "Action.OpenUrl",
                        "title": "📋 View Plan",
                        "url": "${BUILD_URL}artifact/"
                    }
                ],
                "spacing": "Medium"
            }
        ]
    }
}
EOF
        )
        
        curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
            -X POST \
            -H "Content-Type: application/json" \
            --data "${APPROVAL_PAYLOAD}" \
            "${WEBEX_WEBHOOK_URL}"
    else
        # API method for approval
        local APPROVAL_API_PAYLOAD=$(cat << EOF
{
    "roomId": "${WEBEX_ROOM_ID}",
    "markdown": "${APPROVAL_MESSAGE}"
}
EOF
        )
        
        curl -s -o /tmp/webex_response.txt -w "%{http_code}" \
            -X POST \
            -H "Authorization: Bearer ${WEBEX_ACCESS_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "${APPROVAL_API_PAYLOAD}" \
            "https://webexapis.com/v1/messages"
    fi
}

# Send notification with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=""
    
    # Choose sending method and handle special cases
    if [ "${STATUS}" = "critical" ]; then
        if [ -n "${WEBEX_WEBHOOK_URL}" ]; then
            HTTP_STATUS=$(send_critical_alert "webhook")
        elif [ -n "${WEBEX_ACCESS_TOKEN}" ] && [ -n "${WEBEX_ROOM_ID}" ]; then
            HTTP_STATUS=$(send_critical_alert "api")
        fi
    elif [ "${STATUS}" = "approval" ]; then
        if [ -n "${WEBEX_WEBHOOK_URL}" ]; then
            HTTP_STATUS=$(send_approval_request "webhook")
        elif [ -n "${WEBEX_ACCESS_TOKEN}" ] && [ -n "${WEBEX_ROOM_ID}" ]; then
            HTTP_STATUS=$(send_approval_request "api")
        fi
    else
        # Normal notification
        if [ -n "${WEBEX_WEBHOOK_URL}" ]; then
            HTTP_STATUS=$(send_via_webhook "${WEBEX_WEBHOOK_URL}")
        elif [ -n "${WEBEX_ACCESS_TOKEN}" ] && [ -n "${WEBEX_ROOM_ID}" ]; then
            HTTP_STATUS=$(send_via_api "${WEBEX_ACCESS_TOKEN}" "${WEBEX_ROOM_ID}")
        fi
    fi
    
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 204 ]; then
        echo "✅ Webex notification sent successfully"
        echo "   Status: ${STATUS}"
        echo "   Region: ${REGION}"
        echo "   Account: ${ACCOUNT_ID}"
        echo "   Method: $(if [ -n "${WEBEX_WEBHOOK_URL}" ]; then echo "Webhook"; else echo "Bot API"; fi)"
        echo "   Timestamp: ${TIMESTAMP}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️  Webex notification failed (attempt ${RETRY_COUNT}/${MAX_RETRIES})"
        echo "   HTTP Status: ${HTTP_STATUS}"
        
        if [ -f /tmp/webex_response.txt ]; then
            echo "   Response: $(cat /tmp/webex_response.txt)"
        fi
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "   Retrying in 3 seconds..."
            sleep 3
        else
            echo "❌ Failed to send Webex notification after ${MAX_RETRIES} attempts"
            echo "   Check WEBEX_WEBHOOK_URL or WEBEX_ACCESS_TOKEN/WEBEX_ROOM_ID configuration"
            exit 1
        fi
    fi
done

# Cleanup
rm -f /tmp/webex_response.txt