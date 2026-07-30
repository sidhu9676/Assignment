pipeline {
    agent any

    environment {
        IMAGE_NAME = 'yourprivateregistry.com/yourproject/assignment'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials' // Jenkins credentials ID
        SLACK_CHANNEL = '#build-notifications'
        DEPLOY_COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('Install Dependencies and Run Tests') {
            steps {
                sh 'mvn clean test'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://yourprivateregistry.com', env.DOCKER_CREDENTIALS_ID) {
                        def customImage = docker.build("${env.IMAGE_NAME}:${env.IMAGE_TAG}")
                        // Push image
                        customImage.push()
                        // Save image for later rollback if needed
                        env.LATEST_IMAGE = "${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} down || true"
                sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} up -d"
            }
        }

        stage('Wait for Readiness') {
            steps {
                script {
                    def retries = 10
                    def success = false
                    for (int i=0; i<retries; i++) {
                        def response = sh(script: "curl -s -o /dev/null -w \"%{http_code}\" http://localhost:8080/health", returnStdout: true).trim()
                        if (response == '200') {
                            success = true
                            break
                        }
                        sleep 10
                    }
                    if (!success) {
                        error("Application not healthy after retries")
                    }
                }
            }
        }

        stage('Curl Verification') {
            steps {
                sh 'curl -f http://localhost:8080/health'
            }
        }
    }

    post {
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', message: "Build #${env.BUILD_NUMBER} succeeded.")
        }
        failure {
            // Implement rollback logic here
            script {
                // Example rollback: redeploy previous image
                // You might want to store previous image tags or implement a more robust rollback
                sh "docker-compose down || true"
                // Optionally, pull and redeploy previous image
                // sh "docker pull ${env.IMAGE_NAME}:previous-tag || true"
                // sh "docker-compose up -d"
            }
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', message: "Build #${env.BUILD_NUMBER} failed.")
        }
        always {
            sh 'docker image prune -f'
        }
    }
}
