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
        EC2_CREDS = credentials('ec2-login')   // Jenkins credentials ID for username+password
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
                        sh 'terraform init -reconfigure'
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

        stage('Generate Inventory') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh '''
                  JAVA_IP=$(terraform output -raw java_server_ip)
                  DB_IP=$(terraform output -raw db_server_ip)

                  cat <<EOF > infra/ansible/inventory.ini
[java_server]
$JAVA_IP ansible_user=${EC2_CREDS_USR} ansible_password=${EC2_CREDS_PSW} ansible_connection=ssh

[db_server]
$DB_IP ansible_user=${EC2_CREDS_USR} ansible_password=${EC2_CREDS_PSW} ansible_connection=ssh
EOF
                '''
            }
        }

        stage('Configure DB Server') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'ansible-playbook -i infra/ansible/inventory.ini infra/ansible/db-server.yml'
            }
        }

        stage('Configure Java Server') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                sh 'ansible-playbook -i infra/ansible/inventory.ini infra/ansible/java-server.yml'
            }
        }
    }
}
