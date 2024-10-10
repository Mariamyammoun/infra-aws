pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('jenkins-aws') 
        AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws') 
        SSH_KEY = '/home/jenkins/.ssh/mariam-key.pem' 
    }
    stages {
        stage('Terraform Init') {
            steps {
                script {
                    // Initialiser Terraform
                    sh '''
                    cd Terraform
                    terraform init
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                script {
                    // Appliquer la configuration Terraform et créer l'instance
                    sh '''
                    cd Terraform
                    terraform apply -auto-approve -var "server_name=${params.SERVER_NAME}"
                    '''
                    
                    // Récupérer l'adresse IP publique de l'instance EC2
                    def public_ip = sh(script: '''
                    cd Terraform
                    terraform output -raw instance_public_ip
                    ''', returnStdout: true).trim()

                    // Créer le fichier d'inventaire Ansible
                    writeFile file: 'hosts.ini', text: """
                    [ec2]
                    ${public_ip}

                    [ec2:vars]
                    ansible_user=ubuntu
                    ansible_ssh_private_key_file=${env.SSH_KEY}
                    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
                    """
                }
            }
        }

        stage('Ansible Setup') {
            steps {
                script {
                    // Exécuter le playbook Ansible pour configurer l'instance
                    sh '''
                    cd Ansible
                    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ../hosts.ini playbook.yml
                    '''
                }
            }
        }
    }
}
