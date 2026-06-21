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
            description: 'Terraform Action'
        )
    }

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_IN_AUTOMATION = 'true'
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

                        archiveArtifacts artifacts: 'tfplan'
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

                    sh '''
                    JAVA_IP=$(terraform output -raw java_server_public_ip)
                    DB_IP=$(terraform output -raw db_server_private_ip)

                    cat > ../Ansible/inventory.ini <<EOF
[java_server]
$JAVA_IP ansible_user=ec2-user

[db_server]
$DB_IP ansible_user=ec2-user
EOF

                    echo "=============================="
                    echo "Generated Inventory"
                    echo "=============================="

                    cat ../Ansible/inventory.ini
                    '''
                }
            }
        }

        stage('Wait For SSH') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'aws-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    dir('Infra') {

                        sh '''
                        chmod 600 $SSH_KEY

                        JAVA_IP=$(terraform output -raw java_server_public_ip)
                        DB_IP=$(terraform output -raw db_server_private_ip)

                        for HOST in $JAVA_IP $DB_IP
                        do

                            echo "Waiting for SSH on $HOST..."

                            for i in {1..30}
                            do

                                ssh \
                                  -o StrictHostKeyChecking=no \
                                  -o UserKnownHostsFile=/dev/null \
                                  -o ConnectTimeout=5 \
                                  -i $SSH_KEY \
                                  $SSH_USER@$HOST "echo SSH Ready" && break

                                echo "Retry $i..."

                                sleep 10

                            done

                        done
                        '''
                    }
                }
            }
        }

        stage('Ansible Connectivity Test') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'aws-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    dir('Ansible') {

                        sh '''
                        chmod 600 $SSH_KEY

                        ansible all \
                          -i inventory.ini \
                          -m ping \
                          --private-key=$SSH_KEY \
                          -u $SSH_USER
                        '''
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

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'aws-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    retry(3) {

                        dir('Ansible') {

                            sh '''
                            chmod 600 $SSH_KEY

                            ansible-playbook \
                              -i inventory.ini \
                              --private-key=$SSH_KEY \
                              -u $SSH_USER \
                              db-server.yml
                            '''
                        }
                    }
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

                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'aws-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {

                    retry(3) {

                        dir('Ansible') {

                            sh '''
                            chmod 600 $SSH_KEY

                            ansible-playbook \
                              -i inventory.ini \
                              --private-key=$SSH_KEY \
                              -u $SSH_USER \
                              java-server.yml
                            '''
                        }
                    }
                }
            }
        }

        stage('Application Health Check') {

            when {
                expression {
                    params.ACTION == "apply"
                }
            }

            steps {

                dir('Infra') {

                    sh '''
                    JAVA_IP=$(terraform output -raw java_server_public_ip)

                    echo "Waiting for application..."

                    sleep 30

                    curl -I http://$JAVA_IP:8080 || true
                    '''
                }
            }
        }
    }

    post {

        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed.'
        }

        always {
            cleanWs()
        }
    }
}