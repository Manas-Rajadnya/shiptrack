pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo "Building ${env.JOB_NAME} #${env.BUILD_NUMBER}"
            }
        }

        stage('Lint') {
            steps {
                sh 'bash -n scripts/*.sh && echo "shell syntax OK"'
            }
        }

        stage('Test') {
            steps {
                sh 'test -f app/main.py && echo "app present"'
                sh 'test -f Dockerfile && echo "Dockerfile present"'
            }
        }

        stage('Build') {
            steps {
                echo 'Image build would run here'
            }
        }
    }

    post {
        success { echo 'Pipeline green' }
        failure { echo 'Pipeline red - check the stage that went red above' }
        always  { echo 'This runs no matter what happened' }
    }
}