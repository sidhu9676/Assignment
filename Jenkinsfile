pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sidhu9676/assignment:15'
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'docker' // Jenkins credentials ID for Docker Hub
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
                    // Empty string '' defaults to public Docker Hub registry.
                    docker.withRegistry('', env.DOCKER_CREDENTIALS_ID) {
                        def customImage = docker.build("${env.IMAGE_NAME}:${env.IMAGE_TAG}")
                        
                        // Push image to registry
                        customImage.push()
                        
                        // Save image tag for later reference
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
                timeout(time: 2, unit: 'MINUTES') {
                    retry(10) {
                        script {
                            def response = sh(
                                script: 'curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health',
                                returnStdout: true
                            ).trim()

                            if (response != '200') {
                                sleep 5
                                error("Application not healthy yet (HTTP Status: ${response})")
                            }
                        }
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
            echo "SUCCESS: Build #${env.BUILD_NUMBER} completed successfully."
        }
        failure {
            script {
                // Rollback logic: tear down broken deployment
                sh "docker-compose -f ${env.DEPLOY_COMPOSE_FILE} down || true"
            }
            echo "FAILURE: Build #${env.BUILD_NUMBER} failed."
        }
        always {
            sh 'docker image prune -f'
        }
    }
}
