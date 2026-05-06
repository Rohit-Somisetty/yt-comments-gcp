pipeline {
    agent any

    environment {
        PROJECT_ID = 'yt-comments-495004'
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Run Sentiment Analysis') {
            steps {
                // Use the Jenkins credentials plugin to inject the service account key
                withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'SERVICE_ACCOUNT_KEY')]) { 
                    // Set the environment variable so Python can see the credentials
                    withEnv(["GOOGLE_APPLICATION_CREDENTIALS=${SERVICE_ACCOUNT_KEY}"]) {
                        sh '''
                        echo "Activating service account..."
                        gcloud auth activate-service-account --key-file=$GOOGLE_APPLICATION_CREDENTIALS
                        
                        echo "Setting GCP project..."
                        gcloud config set project $PROJECT_ID

                        echo "Verifying credentials..."
                        gcloud auth list

                        echo "Running Ansible playbook..."
                        ansible-playbook -i ansible/inventory ansible/playbooks/run_pretrained_sentiment.yml
                        '''
                    }
                }
            }
        }
    }
} 