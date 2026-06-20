pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Version') {
            steps {
                ansiColor('xterm') {
                    sh 'terraform version'
                }
            }
        }

        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        sh 'terraform init'
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        sh 'terraform validate'
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        sh 'terraform plan -out=tfplan'
                    }
                }
            }
        }

        stage('Approval') {
            steps {
                input 'Apply Terraform?'
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        sh 'terraform apply -auto-approve tfplan'
                    }
                }
            }
        }

        stage('Destroy Approval') {
            steps {
                input 'Destroy Terraform resources?'
            }
        }

        stage('Terraform Destroy') {
            when {
                beforeAgent true
                expression {
                    // Only run if user approved the Destroy stage
                    true
                }
            }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        sh 'terraform destroy -auto-approve'
                    }
                }
            }
        }
    }
}
