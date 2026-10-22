pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        PROJECT_NAME = 'CloudGuard'
        TERRAFORM_DIR = '03-terraform-secure-infrastructure'
    }

    stages {
        stage('Source Checkout') {
            steps {
                echo "Running CI for ${PROJECT_NAME}"
                echo "Repository: ${env.JOB_NAME}"
                echo "Build number: ${env.BUILD_NUMBER}"
                sh 'git rev-parse --short HEAD'
            }
        }

        stage('Environment Check') {
            steps {
                sh '''
                    set -eu
                    echo "Checking required tools..."
                    git --version
                    terraform version
                    checkov --version
                '''
            }
        }

        stage('Terraform Format Check') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform fmt -check -recursive'
                }
            }
        }

        stage('Terraform Initialization') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform init -backend=false -input=false'
                }
            }
        }

        stage('Terraform Validation') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'terraform validate -no-color'
                }
            }
        }

        stage('Checkov Security Scan') {
            steps {
                dir("${TERRAFORM_DIR}") {
                    sh 'checkov -d . --quiet'
                }
            }
        }
    }

    post {
        success {
            echo 'CloudGuard CI completed successfully.'
        }
        failure {
            echo 'CloudGuard CI failed. Review the stage logs.'
        }
        always {
            echo "Build result: ${currentBuild.currentResult}"
        }
    }
}
