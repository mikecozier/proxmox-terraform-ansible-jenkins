pipeline {
  agent any

  options {
    timestamps()
    skipDefaultCheckout(true)   // we’ll checkout once explicitly
  }

  environment {
    PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
    PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
    SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')   // your pub key (Secret Text)
  }

  parameters {
    booleanParam(name: 'APPLY', defaultValue: false, description: 'Run terraform apply (and Ansible)')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Init & Plan') {
      steps {
        sh '''
          set -e
          terraform -version
          terraform init -input=false
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          terraform plan -input=false -out=plan.out
        '''
      }
    }

    stage('Terraform Apply') {
      when { expression { return params.APPLY } }
      steps {
        sh '''
          set -e
          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          terraform apply -input=false -auto-approve plan.out
        '''
      }
    }

stage('Configure with Ansible') {
  when {
    allOf {
      expression { fileExists('inventory.ini') }
      expression { fileExists('site.yml') }
      expression { return params.APPLY }  // only after apply
    }
  }
  environment { ANSIBLE_HOST_KEY_CHECKING = 'False' }
  steps {
    sshagent(credentials: ['ansible_ssh']) {
      sh '''
        set -e
        ansible --version
        ansible-playbook -i inventory.ini site.yml -v
      '''
    }
  }
}

  post {
    success { archiveArtifacts artifacts: 'plan.out', onlyIfSuccessful: true }
    failure { echo 'Build failed — check the console log above.' }
  }
}

