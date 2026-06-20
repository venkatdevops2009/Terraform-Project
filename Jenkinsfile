pipeline {
    agent any

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Choose Terraform action to perform'
        )
    }

    environment {
        AWS_DEFAULT_REGION = "us-east-1"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
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

        stage('Terraform Action') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    ansiColor('xterm') {
                        script {
                            if (params.ACTION == 'plan') {
                                sh 'terraform plan -out=tfplan'
                            } else if (params.ACTION == 'apply') {
                                input message: 'Are you sure you want to APPLY changes?'
                                sh 'terraform apply -auto-approve tfplan'
                            } else if (params.ACTION == 'destroy') {
                                input message: 'Are you sure you want to DESTROY all resources?'
                                sh 'terraform destroy -auto-approve'
                            }
                        }
                    }
                }
            }
        }
    }
}
