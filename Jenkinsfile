pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy', 'drift-check', 'drift-monitor', 'test-notifications'],
            description: 'Select action to perform'
        )
        choice(
            name: 'REGION',
            choices: ['us-east-1', 'us-west-1', 'ap-south-1', 'cn-north-1', 'cn-northwest-1'],
            description: 'Select AWS region'
        )
        choice(
            name: 'ACCOUNT_ID',
            choices: ['123456789012', '234567890123', '345678901234', '456789012345', '567890123456'],
            description: 'Select AWS Account ID'
        )
        booleanParam(
            name: 'DEPLOY_ALL_REGIONS',
            defaultValue: false,
            description: 'Deploy to all regions (overrides REGION parameter)'
        )
        booleanParam(
            name: 'AUTO_APPROVE',
            defaultValue: false,
            description: 'Auto approve terraform apply (skip manual approval stage)'
        )
        booleanParam(
            name: 'SEND_NOTIFICATIONS',
            defaultValue: true,
            description: 'Send notifications to all configured channels'
        )
        booleanParam(
            name: 'ENABLE_DRIFT_ALERTS',
            defaultValue: true,
            description: 'Enable drift detection alerts'
        )
    }
    
    environment {
        AWS_DEFAULT_REGION = "${params.REGION}"
        TF_VAR_region = "${params.REGION}"
        TF_VAR_account_id = "${params.ACCOUNT_ID}"
        TERRAFORM_VERSION = "1.6.0"
        DRIFT_THRESHOLD = "5"
        STATE_BUCKET = "my-terraform-state-bucket"
        
        // Notification flags
        SEND_NOTIFICATIONS = "${params.SEND_NOTIFICATIONS}"
        ENABLE_DRIFT_ALERTS = "${params.ENABLE_DRIFT_ALERTS}"
    }
    
    tools {
        terraform "${TERRAFORM_VERSION}"
    }
    
    stages {
        stage('🚀 Pipeline Initialization') {
            steps {
                script {
                    // Set build timestamp
                    env.BUILD_TIMESTAMP = sh(
                        script: 'date +"%Y%m%d_%H%M%S"',
                        returnStdout: true
                    ).trim()
                    
                    // Display pipeline configuration
                    echo """
                    ════════════════════════════════════════════════════════════════
                    🏗️  TERRAFORM INFRASTRUCTURE PIPELINE
                    ════════════════════════════════════════════════════════════════
                    📋 Action: ${params.ACTION}
                    🌍 Region: ${params.REGION}
                    🏢 Account: ${params.ACCOUNT_ID}
                    🚀 Build: ${env.BUILD_NUMBER}
                    📅 Timestamp: ${env.BUILD_TIMESTAMP}
                    🔄 Multi-Region: ${params.DEPLOY_ALL_REGIONS}
                    ✅ Auto-Approve: ${params.AUTO_APPROVE}
                    📢 Notifications: ${params.SEND_NOTIFICATIONS}
                    ════════════════════════════════════════════════════════════════
                    """
                    
                    // Send pipeline start notification
                    if (params.SEND_NOTIFICATIONS) {
                        sh """
                            if [ -f "./scripts/slack-notify.sh" ]; then
                                ./scripts/slack-notify.sh "info" "🚀 **Terraform Pipeline Started**\\n\\n**Action:** ${params.ACTION}\\n**Region:** ${params.REGION}\\n**Account:** ${params.ACCOUNT_ID}\\n**Build:** ${env.BUILD_NUMBER}\\n**Multi-Region:** ${params.DEPLOY_ALL_REGIONS}\\n\\n📋 Pipeline is now running..."
                            fi
                        """
                    }
                }
                
                // Checkout code
                checkout scm
            }
        }
        
        stage('🔧 Setup AWS Credentials') {
            steps {
                script {
                    def isChina = params.REGION.startsWith('cn-')
                    
                    echo "🔐 Setting up AWS credentials for ${isChina ? 'China' : 'Standard'} regions..."
                    
                    if (isChina) {
                        withCredentials([
                            assumeRole(
                                credentialsId: 'aws-china-role',
                                roleArn: "arn:aws-cn:iam::${params.ACCOUNT_ID}:role/TerraformRole",
                                roleSessionName: 'jenkins-terraform-china'
                            )
                        ]) {
                            env.AWS_REGION = params.REGION
                            echo "✅ China region credentials configured"
                        }
                    } else {
                        withCredentials([
                            assumeRole(
                                credentialsId: 'aws-standard-role',
                                roleArn: "arn:aws:iam::${params.ACCOUNT_ID}:role/TerraformRole",
                                roleSessionName: 'jenkins-terraform-standard'
                            )
                        ]) {
                            env.AWS_REGION = params.REGION
                            echo "✅ Standard region credentials configured"
                        }
                    }
                }
            }
        }
        
        stage('📋 Script Validation') {
            steps {
                script {
                    echo "🔍 Validating required scripts..."
                    sh 'make check-scripts'
                    sh 'make make-scripts-executable'
                    echo "✅ All scripts validated and made executable"
                }
            }
        }
        
        stage('🔧 Terraform Setup') {
            steps {
                script {
                    echo "🔧 Setting up Terraform..."
                    sh """
                        make init REGION=${params.REGION} ACCOUNT_ID=${params.ACCOUNT_ID}
                    """
                    echo "✅ Terraform initialization completed"
                }
            }
        }
        
        stage('✅ Terraform Validation') {
            steps {
                script {
                    echo "✅ Validating and formatting Terraform code..."
                    sh 'make validate'
                    sh 'make format'
                    echo "✅ Terraform validation and formatting completed"
                }
            }
        }
        
        stage('🔒 Security Scan') {
            steps {
                script {
                    echo "🔒 Running security scan..."
                    try {
                        sh 'make security-scan'
                        echo "✅ Security scan completed successfully"
                    } catch (Exception e) {
                        echo "⚠️ Security scan failed or tfsec not available: ${e.getMessage()}"
                        if (params.SEND_NOTIFICATIONS) {
                            sh """
                                if [ -f "./scripts/slack-notify.sh" ]; then
                                    ./scripts/slack-notify.sh "warning" "⚠️ Security scan failed in build ${env.BUILD_NUMBER}"
                                fi
                            """
                        }
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'security-report.json', fingerprint: true, allowEmptyArchive: true
                }
            }
        }
        
        stage('📋 Terraform Plan') {
            when {
                anyOf {
                    expression { params.ACTION == 'plan' }
                    expression { params.ACTION == 'apply' }
                }
            }
            steps {
                script {
                    if (params.DEPLOY_ALL_REGIONS) {
                        echo "🌍 Planning for all regions..."
                        sh """
                            for region in us-east-1 us-west-1 ap-south-1 cn-north-1 cn-northwest-1; do
                                echo "📋 Planning for region: \$region"
                                make plan REGION=\$region ACCOUNT_ID=${params.ACCOUNT_ID}
                                echo "✅ Plan completed for \$region"
                            done
                        """
                    } else {
                        echo "📋 Planning for ${params.REGION}..."
                        sh """
                            make plan REGION=${params.REGION} ACCOUNT_ID=${params.ACCOUNT_ID}
                        """
                        echo "✅ Plan completed for ${params.REGION}"
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'tfplan-*.plan', fingerprint: true, allowEmptyArchive: true
                }
            }
        }
        
        stage('💰 Cost Estimation') {
            when {
                anyOf {
                    expression { params.ACTION == 'plan' }
                    expression { params.ACTION == 'apply' }
                }
            }
            steps {
                script {
                    echo "💰 Estimating infrastructure costs..."
                    try {
                        sh 'make cost-estimate'
                        echo "✅ Cost estimation completed"
                    } catch (Exception e) {
                        echo "⚠️ Cost estimation failed or infracost not available: ${e.getMessage()}"
                    }
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'cost-estimate.json', fingerprint: true, allowEmptyArchive: true
                }
            }
        }
        
        stage('📋 Send Approval Notifications') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    not { params.AUTO_APPROVE }
                    expression { params.SEND_NOTIFICATIONS }
                }
            }
            steps {
                script {
                    echo "📋 Sending approval notifications to all channels..."
                    if (params.DEPLOY_ALL_REGIONS) {
                        sh """
                            ./scripts/approval-notify.sh "apply-multi-region" "ALL-REGIONS" ${params.ACCOUNT_ID}
                        """
                    } else {
                        sh """
                            ./scripts/approval-notify.sh "apply" ${params.REGION} ${params.ACCOUNT_ID}
                        """
                    }
                    echo "✅ Approval notifications sent"
                }
            }
        }
        
        stage('✋ Manual Approval') {
            when {
                allOf {
                    expression { params.ACTION == 'apply' }
                    not { params.AUTO_APPROVE }
                }
            }
            steps {
                script {
                    def approvalMessage = params.DEPLOY_ALL_REGIONS ? 
                        "Review the terraform plans for ALL REGIONS and approve multi-region deployment" :
                        "Review the terraform plan for ${params.REGION} and approve deployment"
                    
                    def userInput = input(
                        id: 'deploymentApproval',
                        message: approvalMessage,
                        parameters: [
                            booleanParam(
                                defaultValue: false,
                                description: 'I have reviewed the plan(s) and approve this deployment',
                                name: 'APPROVE_DEPLOYMENT'
                            ),
                            text(
                                defaultValue: '',
                                description: 'Optional: Add approval comments',
                                name: 'APPROVAL_COMMENTS'
                            )
                        ]
                    )
                    
                    if (!userInput.APPROVE_DEPLOYMENT) {
                        if (params.SEND_NOTIFICATIONS) {
                            sh """
                                if [ -f "./scripts/slack-notify.sh" ]; then
                                    ./scripts/slack-notify.sh "error" "❌ **Deployment Rejected**\\n\\n**Region:** ${params.REGION}\\n**Account:** ${params.ACCOUNT_ID}\\n**Build:** ${env.BUILD_NUMBER}\\n\\nDeployment was rejected by user approval."
                                fi
                            """
                        }
                        error('❌ Deployment not approved by user')
                    }
                    
                    // Log approval
                    env.APPROVAL_COMMENTS = userInput.APPROVAL_COMMENTS ?: "No comments provided"
                    echo "✅ Deployment approved with comments: ${env.APPROVAL_COMMENTS}"
                }
            }
        }
        
        stage('🚀 Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                script {
                    if (params.DEPLOY_ALL_REGIONS) {
                        echo "🌍 Applying to all regions..."
                        sh """
                            make deploy-all-regions ACCOUNT_ID=${params.ACCOUNT_ID}
                        """
                        echo "✅ Multi-region deployment completed"
                    } else {
                        echo "🚀 Applying to ${params.REGION}..."
                        sh """
                            make apply-without-approval REGION=${params.REGION} ACCOUNT_ID=${params.ACCOUNT_ID}
                        """
                        echo "✅ Deployment completed for ${params.REGION}"
                    }
                }
            }
        }
        
        stage('🗑️ Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                script {
                    def userInput = input(
                        id: 'destroyConfirmation',
                        message: '⚠️ WARNING: This will destroy all infrastructure resources!',
                        parameters: [
                            string(
                                defaultValue: '',
                                description: 'Type "DESTROY" in capital letters to confirm destruction',
                                name: 'DESTROY_CONFIRMATION'
                            ),
                            text(
                                defaultValue: '',
                                description: 'Reason for destruction (required)',
                                name: 'DESTRUCTION_REASON'
                            )
                        ]
                    )
                    
                    if (userInput.DESTROY_CONFIRMATION != 'DESTROY') {
                        error('❌ Destruction not confirmed - must type "DESTROY" exactly')
                    }
                    
                    if (!userInput.DESTRUCTION_REASON?.trim()) {
                        error('❌ Destruction reason is required')
                    }
                    
                    echo "🗑️ Destruction approved. Reason: ${userInput.DESTRUCTION_REASON}"
                    
                    // Send destruction warning
                    if (params.SEND_NOTIFICATIONS) {
                        sh """
                            if [ -f "./scripts/slack-notify.sh" ]; then
                                ./scripts/slack-notify.sh "critical" "🗑️ **RESOURCE DESTRUCTION IN PROGRESS**\\n\\n**Region:** ${params.REGION}\\n**Account:** ${params.ACCOUNT_ID}\\n**Reason:** ${userInput.DESTRUCTION_REASON}\\n\\n⚠️ All resources are being destroyed..."
                            fi
                        """
                    }
                    
                    sh """
                        terraform destroy \\
                            -var="region=${params.REGION}" \\
                            -var="account_id=${params.ACCOUNT_ID}" \\
                            -auto-approve
                    """
                    
                    echo "✅ Resources successfully destroyed"
                }
            }
        }
        
        stage('🔍 Drift Detection') {
            when {
                expression { params.ACTION == 'drift-check' }
            }
            steps {
                script {
                    echo "🔍 Running drift detection for ${params.REGION}..."
                    sh """
                        ./scripts/drift-detection.sh ${params.REGION} ${params.ACCOUNT_ID}
                    """
                    echo "✅ Drift detection completed"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'drift-reports/*.log', fingerprint: true, allowEmptyArchive: true
                    archiveArtifacts artifacts: 'drift-reports/*.html', fingerprint: true, allowEmptyArchive: true
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'drift-reports',
                        reportFiles: '*.html',
                        reportName: 'Drift Detection Report'
                    ])
                }
            }
        }
        
        stage('📊 Drift Monitoring') {
            when {
                expression { params.ACTION == 'drift-monitor' }
            }
            steps {
                script {
                    echo "📊 Running comprehensive drift monitoring for account ${params.ACCOUNT_ID}..."
                    sh """
                        ./scripts/drift-monitoring.sh ${params.ACCOUNT_ID}
                    """
                    echo "✅ Drift monitoring completed"
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: 'drift-reports/monitoring/*', fingerprint: true, allowEmptyArchive: true
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'drift-reports/monitoring',
                        reportFiles: '*.html',
                        reportName: 'Drift Monitoring Dashboard'
                    ])
                }
            }
        }
        
        stage('🔔 Test Notifications') {
            when {
                expression { params.ACTION == 'test-notifications' }
            }
            steps {
                script {
                    echo "🔔 Testing all notification systems..."
                    sh """
                        make test-all-notifications REGION=${params.REGION} ACCOUNT_ID=${params.ACCOUNT_ID}
                    """
                    echo "✅ Notification testing completed"
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Cleanup temporary files
                echo "🧹 Cleaning up temporary files..."
                sh 'make clean || true'
                
                // Archive all important artifacts
                archiveArtifacts artifacts: 'drift-reports/**', fingerprint: true, allowEmptyArchive: true
                archiveArtifacts artifacts: 'approval-summary-*.txt', fingerprint: true, allowEmptyArchive: true
                archiveArtifacts artifacts: 'approval-logs/*.log', fingerprint: true, allowEmptyArchive: true
                
                echo "✅ Cleanup completed"
            }
        }
        
        success {
            script {
                if (params.SEND_NOTIFICATIONS) {
                    def successMessage = """
✅ **Terraform Pipeline Completed Successfully**

**📋 Details:**
• **Action:** ${params.ACTION}
• **Region:** ${params.REGION}
• **Account ID:** ${params.ACCOUNT_ID}
• **Build Number:** ${env.BUILD_NUMBER}
• **Duration:** ${currentBuild.durationString}
• **Multi-Region:** ${params.DEPLOY_ALL_REGIONS}
• **Started:** ${env.BUILD_TIMESTAMP}
• **Completed:** \$(date)

**📊 Results:**
✅ All operations completed successfully
📋 No errors encountered

**🔗 Links:**
• [📋 View Build](${env.BUILD_URL})
• [📊 View Artifacts](${env.BUILD_URL}artifact/)
• [📝 View Console](${env.BUILD_URL}console)
                    """
                    
                    // Send success notifications to all channels
                    sh """
                        if [ -f "./scripts/slack-notify.sh" ]; then
                            ./scripts/slack-notify.sh "success" "${successMessage}"
                        fi
                        if [ -f "./scripts/webex-notify.sh" ]; then
                            ./scripts/webex-notify.sh "success" "${successMessage}"
                        fi
                        if [ -f "./scripts/teams-notify.sh" ]; then
                            ./scripts/teams-notify.sh "success" "${successMessage}"
                        fi
                        if [ -f "./scripts/email-notify.sh" ]; then
                            ./scripts/email-notify.sh "success" "${successMessage}"
                        fi
                    """
                }
            }
        }
        
        failure {
            script {
                if (params.SEND_NOTIFICATIONS) {
                    def failureMessage = """
❌ **Terraform Pipeline Failed**

**📋 Details:**
• **Action:** ${params.ACTION}
• **Region:** ${params.REGION}
• **Account ID:** ${params.ACCOUNT_ID}
• **Build Number:** ${env.BUILD_NUMBER}
• **Failed Stage:** ${env.STAGE_NAME}
• **Error:** ${currentBuild.result}
• **Duration:** ${currentBuild.durationString}

**🚨 Action Required:**
Please review the console logs and take corrective action.

**🔗 Links:**
• [🚨 View Build](${env.BUILD_URL})
• [📝 View Console Logs](${env.BUILD_URL}console)
• [📊 View Artifacts](${env.BUILD_URL}artifact/)

**💡 Common Solutions:**
• Check AWS credentials and permissions
• Verify Terraform configuration syntax
• Review resource constraints and limits
• Check network connectivity and security groups
                    """
                    
                    // Send failure notifications to all channels
                    sh """
                        if [ -f "./scripts/slack-notify.sh" ]; then
                            ./scripts/slack-notify.sh "error" "${failureMessage}"
                        fi
                        if [ -f "./scripts/webex-notify.sh" ]; then
                            ./scripts/webex-notify.sh "error" "${failureMessage}"
                        fi
                        if [ -f "./scripts/teams-notify.sh" ]; then
                            ./scripts/teams-notify.sh "error" "${failureMessage}"
                        fi
                        if [ -f "./scripts/email-notify.sh" ]; then
                            ./scripts/email-notify.sh "error" "${failureMessage}"
                        fi
                    """
                }
            }
        }
        
        unstable {
            script {
                if (params.SEND_NOTIFICATIONS) {
                    def unstableMessage = """
⚠️ **Terraform Pipeline Unstable**

**📋 Details:**
• **Action:** ${params.ACTION}
• **Region:** ${params.REGION}
• **Account ID:** ${params.ACCOUNT_ID}
• **Build Number:** ${env.BUILD_NUMBER}
• **Status:** Unstable
• **Duration:** ${currentBuild.durationString}

**📊 Status:**
Pipeline completed with warnings or non-critical issues.

**🔗 Links:**
• [⚠️ View Build](${env.BUILD_URL})
• [📝 View Console](${env.BUILD_URL}console)
                    """
                    
                    // Send unstable notifications
                    sh """
                        if [ -f "./scripts/slack-notify.sh" ]; then
                            ./scripts/slack-notify.sh "warning" "${unstableMessage}"
                        fi
                        if [ -f "./scripts/webex-notify.sh" ]; then
                            ./scripts/webex-notify.sh "warning" "${unstableMessage}"
                        fi
                        if [ -f "./scripts/teams-notify.sh" ]; then
                            ./scripts/teams-notify.sh "warning" "${unstableMessage}"
                        fi
                    """
                }
            }
        }
        
        aborted {
            script {
                if (params.SEND_NOTIFICATIONS) {
                    def abortedMessage = """
🛑 **Terraform Pipeline Aborted**

**📋 Details:**
• **Action:** ${params.ACTION}
• **Region:** ${params.REGION}
• **Account ID:** ${params.ACCOUNT_ID}
• **Build Number:** ${env.BUILD_NUMBER}
• **Status:** Aborted by user or timeout
• **Duration:** ${currentBuild.durationString}

**ℹ️ Information:**
Pipeline was manually aborted or timed out.

**🔗 Links:**
• [🛑 View Build](${env.BUILD_URL})
                    """
                    
                    sh """
                        if [ -f "./scripts/slack-notify.sh" ]; then
                            ./scripts/slack-notify.sh "warning" "${abortedMessage}"
                        fi
                    """
                }
            }
        }
    }
}