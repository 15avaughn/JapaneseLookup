// Jenkinsfile for Inventory in CS 3260
// Students: Do not modify this file in any way.
pipeline {
    agent {
        node { label 'mac' }
    }

    stages {
        stage('Build') {
            steps {
                echo 'Building..'
                sh 'cs3260inventorybuild'
            }
            post {
                failure {
                    echo 'Sending console log to submitter'
                    sh 'cs3260sendlog "Build failed"'
                }
            }
        }
        stage('Test') {
            steps {
                echo 'Testing..'
                sh 'cs3260inventorytest'
            }
            post {
                always {
                    echo 'Grading the assignment....'
                    sh "cs3260grade $WORKSPACE $GIT_COMMIT"
                    echo 'Reporting to the student....'
                    sh "cs3260report $WORKSPACE $GIT_COMMIT"

                }
            }
        }
    }
}
