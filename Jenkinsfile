pipeline {
    agent any
    environment {
        REPO_URL = 'git@github.com:your_org/your_repo.git'
        IMAGE_NAME = 'myregistry.example.com/myapp'
        IMAGE_TAG = "build-${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker-registry-credentials'
        GIT_CREDENTIALS_ID = 'github-credentials'
        SLACK_CHANNEL = '#devops'
        SLACK_CREDENTIALS_ID = 'slack-token'
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
                sh 'npm install'
                sh 'npm test'
            }
        }
        stage('Build') {
            steps {
                script {
                    // Building Docker image with cache
                    docker.withRegistry('https://myregistry.example.com', env.DOCKER_CREDENTIALS_ID) {
                        def customImage = docker.build("${env.IMAGE_NAME}:${env.IMAGE_TAG}")
                        // Push image
                        customImage.push()
                        // Save image for rollback if needed
                        env.LATEST_IMAGE = "${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
                }
            }
        }
        stage('Deploy') {
            steps {
                sh '''
                # Pull latest image
                docker-compose down --remove-orphans
                docker-compose pull
                docker-compose up -d
                '''
                // Wait for readiness
                script {
                    waitUntil {
                        def response = sh(
                            script: "curl -s -o /dev/null -w \"%{http_code}\" http://localhost:8080/health",
                            returnStdout: true
                        ).trim()
                        return response == '200'
                    }
                }
            }
        }
        stage('Verify Deployment') {
            steps {
                sh 'curl -f http://localhost:8080/health'
            }
        }
    }
    post {
        success {
            slackSend(channel: env.SLACK_CHANNEL, color: 'good', message: "Build ${env.BUILD_NUMBER} succeeded.")
        }
        failure {
            slackSend(channel: env.SLACK_CHANNEL, color: 'danger', message: "Build ${env.BUILD_NUMBER} failed.")
            // Rollback to previous image if exists
            script {
                def previousImage = getPreviousImage()
                if (previousImage) {
                    sh "docker-compose down"
                    sh "docker tag ${previousImage} ${env.IMAGE_NAME}:latest"
                    sh "docker-compose up -d"
                }
            }
        }
        always {
            // Cleanup dangling images and containers
            sh 'docker system prune -f'
            // Notify build status
            slackSend(channel: env.SLACK_CHANNEL, message: "Build ${env.BUILD_NUMBER} completed.")
        }
    }
}

def getPreviousImage() {
    // Implement logic to retrieve last successful image tag, e.g., from a file or registry
    return 'myregistry.example.com/myapp:build-123'
}
