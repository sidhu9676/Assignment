pipeline {
    agent any

    environment {
        REPO_URL = 'git@github.com:yourusername/your-repo.git'
        IMAGE_NAME = 'yourprivateregistry.com/yourproject/assignment'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-credentials' // Jenkins credentials ID
        GIT_CREDENTIALS_ID = 'github-credentials' // Jenkins credentials ID
        SLACK_CHANNEL = '#build-notifications'
        DEPLOY_COMPOSE_FILE = 'docker-compose.yml'
    }

    stages {
        stage('SCM Pull') {
            steps {
                checkout([$class: 'GitSCM', branches: [[name: 'main']],
                          userRemoteConfigs: [[credentialsId: env.GIT_CREDENTIALS_ID, url: env.REPO_URL]]])
            }
        }

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
                script {
                    sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} down || true"
                    sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} up -d"
                }
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
            // Rollback logic: redeploy previous image
            script {
                def previousTag = 'previous-success-tag' // Implement logic to get previous tag
                sh "docker-compose down || true"
                sh "docker pull ${env.IMAGE_NAME}:${previousTag} || true"
                sh "docker tag ${env.IMAGE_NAME}:${previousTag} ${env.IMAGE_NAME}:${env.BUILD_NUMBER}"
                sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} up -d"
            }
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', message: "Build #${env.BUILD_NUMBER} failed.")
        }
        always {
            // Cleanup dangling images
            sh 'docker image prune -f'
        }
    }
}
