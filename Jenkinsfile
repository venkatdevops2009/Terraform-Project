pipeline {

    agent any

    options {
        ansiColor('xterm')
        timestamps()
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    parameters {
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select Terraform Action'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
        EC2_CREDS = credentials('ec2-login')
    }

    stages {

        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                dir('Infra') {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds']
                    ]) {
                        sh '''
                        terraform init -reconfigure
                        '''
                    }
                }
            }
        }

        stage('Terraform Validate') {
            steps {
                dir('Infra') {
                    sh '''
                    terraform fmt -check
                    terraform validate
                    '''
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression {
                    params.ACTION == "plan" || params.ACTION == "apply"
                }
            }

            steps {

                dir('Infra') {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds']
                    ]) {

                        sh '''
                        terraform plan -out=tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                input message: "Approve Terraform Apply?"

                dir('Infra') {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds']
                    ]) {

                        sh '''
                        terraform apply -auto-approve tfplan
                        '''
                    }
                }
            }
        }

        stage('Terraform Destroy') {

            when {
                expression {
                    params.ACTION == "destroy"
                }
            }

            steps {

                input message: "Destroy Infrastructure?"

                dir('Infra') {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds']
                    ]) {

                        sh '''
                        terraform destroy -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Generate Ansible Inventory') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('Infra') {

                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-creds']
                    ]) {

                        sh """
                        JAVA_IP=\$(terraform output -raw java_server_public_ip)
                        DB_IP=\$(terraform output -raw db_server_private_ip)

                        cat > ../Ansible/inventory.ini <<EOF
[java_server]
\$JAVA_IP ansible_user=${EC2_CREDS_USR} ansible_password=${EC2_CREDS_PSW} ansible_connection=ssh

[db_server]
\$DB_IP ansible_user=${EC2_CREDS_USR} ansible_password=${EC2_CREDS_PSW} ansible_connection=ssh
EOF

                        echo "======================================"
                        echo "Generated Inventory"
                        echo "======================================"

                        cat ../Ansible/inventory.ini
                        """
                    }
                }
            }
        }

        stage('Configure Database Server') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('Ansible') {

                    sh '''
                    ansible-playbook -i inventory.ini db-server.yml
                    '''
                }
            }
        }

        stage('Configure Java Server') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('Ansible') {

                    sh '''
                    ansible-playbook -i inventory.ini java-server.yml
                    '''
                }
            }
        }

    }

    post {

        success {
            echo "Infrastructure deployment completed successfully."
        }

        failure {
            echo "Pipeline failed. Check the console logs for details."
        }

        always {
            cleanWs()
        }

    }
}