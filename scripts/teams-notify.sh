#!/bin/bash

# teams-notify.sh - Enhanced Microsoft Teams notifications with Adaptive Cards

STATUS=${1:-info}
MESSAGE=${2:-"No message provided"}
TEAMS_WEBHOOK_URL=${TEAMS_WEBHOOK_URL:-""}

# Exit if no Teams webhook URL configured
if [ -z "${TEAMS_WEBHOOK_URL}" ]; then
    echo "Teams notification skipped - TEAMS_WEBHOOK_URL not configured"
    exit 0
fi

# Colors and theme colors based on status
case ${STATUS} in
    "success")
        THEME_COLOR="28a745"
        ICON="✅"
        TITLE="Success"
        ACTIVITY_TITLE="Terraform Success"
        ACTIVITY_SUBTITLE="Deployment completed successfully"
        ;;
    "warning")
        THEME_COLOR="ffc107"
        ICON="⚠️"
        TITLE="Warning - Drift Detected"
        ACTIVITY_TITLE="Terraform Warning"
        ACTIVITY_SUBTITLE="Configuration drift detected"
        ;;
    "error"|"failure")
        THEME_COLOR="dc3545"
        ICON="❌"
        TITLE="Error"
        ACTIVITY_TITLE="Terraform Error"
        ACTIVITY_SUBTITLE="Pipeline execution failed"
        ;;
    "critical")
        THEME_COLOR="dc3545"
        ICON="🚨"
        TITLE="CRITICAL ALERT"
        ACTIVITY_TITLE="CRITICAL Terraform Alert"
        ACTIVITY_SUBTITLE="Immediate attention required"
        ;;
    "approval")
        THEME_COLOR="007bff"
        ICON="📋"
        TITLE="Approval Required"
        ACTIVITY_TITLE="Terraform Approval Required"
        ACTIVITY_SUBTITLE="Manual approval needed to proceed"
        ;;
    *)
        THEME_COLOR="17a2b8"
        ICON="ℹ️"
        TITLE="Information"
        ACTIVITY_TITLE="Terraform Notification"
        ACTIVITY_SUBTITLE="Pipeline information"
        ;;
esac

# Get additional context
TIMESTAMP=$(date)
BUILD_URL=${BUILD_URL:-"Not available"}
JENKINS_USER=${BUILD_USER:-"Jenkins"}
REGION=${REGION:-"Multiple"}
ACCOUNT_ID=${ACCOUNT_ID:-"Multiple"}
BUILD_NUMBER=${BUILD_NUMBER:-"N/A"}

# Function to create standard Teams payload
create_standard_payload() {
    cat << EOF
{
    "@type": "MessageCard",
    "@context": "https://schema.org/extensions",
    "summary": "${ACTIVITY_TITLE}",
    "themeColor": "${THEME_COLOR}",
    "sections": [
        {
            "activityTitle": "${ICON} **${ACTIVITY_TITLE}**",
            "activitySubtitle": "${ACTIVITY_SUBTITLE}",
            "activityImage": "https://www.terraform.io/assets/images/logo-hashicorp-3f10732f.svg",
            "facts": [
                {
                    "name": "Status:",
                    "value": "${STATUS^^}"
                },
                {
                    "name": "Region:",
                    "value": "${REGION}"
                },
                {
                    "name": "Account ID:",
                    "value": "${ACCOUNT_ID}"
                },
                {
                    "name": "Build Number:",
                    "value": "${BUILD_NUMBER}"
                },
                {
                    "name": "Triggered By:",
                    "value": "${JENKINS_USER}"
                },
                {
                    "name": "Timestamp:",
                    "value": "${TIMESTAMP}"
                }
            ],
            "text": "${MESSAGE}"
        }
    ]$(if [ "${BUILD_URL}" != "Not available" ]; then
        cat << 'ACTIONS_EOF'
,
    "potentialAction": [
        {
            "@type": "OpenUri",
            "name": "🔍 View Build",
            "targets": [
                {
                    "os": "default",
                    "uri": "${BUILD_URL}"
                }
            ]
        },
        {
            "@type": "OpenUri",
            "name": "📋 View Console",
            "targets": [
                {
                    "os": "default",
                    "uri": "${BUILD_URL}console"
                }
            ]
        }
    ]
ACTIONS_EOF
    fi)
}
EOF
}

# Function to create Adaptive Card payload (Teams v2)
create_adaptive_card_payload() {
    cat << EOF
{
    "type": "message",
    "attachments": [
        {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.4",
                "body": [
                    {
                        "type": "Container",
                        "style": "emphasis",
                        "items": [
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
                                    },
                                    {
                                        "title": "Request Time:",
                                        "value": "${TIMESTAMP}"
                                    }
                                ]
                            }
                        ],
                        "spacing": "Medium"
                    },
                    {
                        "type": "TextBlock",
                        "text": "**Please review the terraform plan and provide approval to continue with the deployment.**",
                        "wrap": true,
                        "weight": "Bolder",
                        "spacing": "Medium"
                    },
                    {
                        "type": "ActionSet",
                        "actions": [
                            {
                                "type": "Action.OpenUrl",
                                "title": "🔍 Review & Approve",
                                "url": "${BUILD_URL}",
                                "style": "positive"
                            },
                            {
                                "type": "Action.OpenUrl",
                                "title": "📋 View Terraform Plan",
                                "url": "${BUILD_URL}artifact/"
                            }
                        ],
                        "spacing": "Medium"
                    }
                ]
            }
        }
    ]
}
EOF
}

# Function to send Teams notification
send_teams_notification() {
    local payload=$1
    
    curl -s -o /tmp/teams_response.txt -w "%{http_code}" \
        -X POST \
        -H "Content-Type: application/json" \
        --data "${payload}" \
        "${TEAMS_WEBHOOK_URL}"
}

# Send notification with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_STATUS=""
    
    # Choose payload based on status
    case ${STATUS} in
        "critical")
            echo "🚨 Sending critical Teams alert..."
            PAYLOAD=$(create_critical_payload)
            ;;
        "approval")
            echo "📋 Sending Teams approval request..."
            PAYLOAD=$(create_approval_payload)
            ;;
        *)
            echo "📢 Sending standard Teams notification..."
            # Try Adaptive Cards first, fallback to MessageCard if needed
            PAYLOAD=$(create_adaptive_card_payload)
            ;;
    esac
    
    HTTP_STATUS=$(send_teams_notification "${PAYLOAD}")
    
    if [ "$HTTP_STATUS" -eq 200 ] || [ "$HTTP_STATUS" -eq 202 ]; then
        echo "✅ Teams notification sent successfully"
        echo "   Status: ${STATUS}"
        echo "   Region: ${REGION}"
        echo "   Account: ${ACCOUNT_ID}"
        echo "   Webhook: ${TEAMS_WEBHOOK_URL:0:50}..."
        echo "   Timestamp: ${TIMESTAMP}"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "⚠️  Teams notification failed (attempt ${RETRY_COUNT}/${MAX_RETRIES})"
        echo "   HTTP Status: ${HTTP_STATUS}"
        
        if [ -f /tmp/teams_response.txt ]; then
            echo "   Response: $(cat /tmp/teams_response.txt)"
        fi
        
        # If Adaptive Cards failed, try fallback to MessageCard format
        if [ $RETRY_COUNT -eq 1 ] && [ "${STATUS}" != "critical" ] && [ "${STATUS}" != "approval" ]; then
            echo "   Trying MessageCard format..."
            PAYLOAD=$(create_standard_payload)
        fi
        
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "   Retrying in 3 seconds..."
            sleep 3
        else
            echo "❌ Failed to send Teams notification after ${MAX_RETRIES} attempts"
            echo "   Check TEAMS_WEBHOOK_URL configuration"
            echo "   Webhook URL format should be: https://outlook.office.com/webhook/..."
            exit 1
        fi
    fi
done

# Cleanup
rm -f /tmp/teams_response.txt
                        "style": "$(case ${STATUS} in success) echo good;; warning) echo warning;; error|failure|critical) echo attention;; *) echo default;; esac)",
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
                                                "text": "${ICON} **${ACTIVITY_TITLE}**",
                                                "weight": "Bolder",
                                                "size": "Large"
                                            },
                                            {
                                                "type": "TextBlock",
                                                "text": "${ACTIVITY_SUBTITLE}",
                                                "weight": "Lighter",
                                                "isSubtle": true
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
                                "title": "Status:",
                                "value": "${STATUS^^}"
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
    ]
}
EOF
}

# Function to create critical alert payload
create_critical_payload() {
    cat << EOF
{
    "type": "message",
    "attachments": [
        {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.4",
                "body": [
                    {
                        "type": "Container",
                        "style": "attention",
                        "items": [
                            {
                                "type": "TextBlock",
                                "text": "🚨 **CRITICAL TERRAFORM ALERT** 🚨",
                                "weight": "Bolder",
                                "size": "ExtraLarge",
                                "color": "Attention",
                                "horizontalAlignment": "Center"
                            },
                            {
                                "type": "TextBlock",
                                "text": "⚠️ **IMMEDIATE ACTION REQUIRED** ⚠️",
                                "weight": "Bolder",
                                "size": "Large",
                                "color": "Attention",
                                "horizontalAlignment": "Center",
                                "spacing": "Small"
                            }
                        ]
                    },
                    {
                        "type": "TextBlock",
                        "text": "${MESSAGE}",
                        "wrap": true,
                        "spacing": "Medium",
                        "size": "Medium"
                    },
                    {
                        "type": "Container",
                        "style": "warning",
                        "items": [
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
                                    },
                                    {
                                        "title": "Build Number:",
                                        "value": "${BUILD_NUMBER}"
                                    }
                                ]
                            }
                        ],
                        "spacing": "Medium"
                    },
                    {
                        "type": "TextBlock",
                        "text": "**This requires immediate investigation and resolution.**",
                        "weight": "Bolder",
                        "color": "Attention",
                        "spacing": "Medium"
                    },
                    {
                        "type": "ActionSet",
                        "actions": [
                            {
                                "type": "Action.OpenUrl",
                                "title": "🚨 View Build (URGENT)",
                                "url": "${BUILD_URL}",
                                "style": "destructive"
                            },
                            {
                                "type": "Action.OpenUrl",
                                "title": "📋 View Console Logs",
                                "url": "${BUILD_URL}console"
                            }
                        ],
                        "spacing": "Medium"
                    }
                ]
            }
        }
    ]
}
EOF
}

# Function to create approval request payload
create_approval_payload() {
    cat << EOF
{
    "type": "message",
    "attachments": [
        {
            "contentType": "application/vnd.microsoft.card.adaptive",
            "content": {
                "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                "type": "AdaptiveCard",
                "version": "1.4",
                "body": [
                    {
                        "type": "Container",
                        "style": "good",
                        "items": [
                            {
                                "type": "ColumnSet",
                                "columns": [
                                    {
                                        "type": "Column",
                                        "width": "auto",
                                        "items": [
                                            {
                                                "type": "TextBlock",
                                                "text": "📋",
                                                "size": "ExtraLarge"
                                            }
                                        ]
                                    },
                                    {
                                        "type": "Column",
                                        "width": "stretch",
                                        "items": [
                                            {
                                                "type": "TextBlock",
                                                "text": "**Terraform Approval Required**",
                                                "weight": "Bolder",
                                                "size": "Large"
                                            },
                                            {
                                                "type": "TextBlock",
                                                "text": "🔄 Deployment Awaiting Manual Approval",
                                                "weight": "Lighter",
                                                "isSubtle": true
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
                        "type": "Container",