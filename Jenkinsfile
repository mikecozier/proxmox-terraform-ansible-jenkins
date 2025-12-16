pipeline {
  agent any
  options { timestamps() }

  parameters {
    booleanParam(name: 'APPLY', defaultValue: false, description: 'Run terraform apply (otherwise only plan).')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {

    stage('Terraform Init & Plan') {
      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')  // your SSH pubkey text
      }
      steps {
        sh '''
          set -e
          terraform -version
          terraform init -input=false
          terraform fmt -check || true
          terraform validate

          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          terraform plan -input=false -out=plan.out
        '''
      }
    }

    stage('Terraform Apply') {
      when { expression { return params.APPLY } }
      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
      }
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
          expression { return params.APPLY }           // only after apply
          expression { fileExists('inventory.ini') }   // only if inventory is present
          expression { fileExists('site.yml') }        // only if playbook is present
        }
      }
      environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
      }
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
  }

  post {
    success { echo 'Build succeeded.' }
    failure { echo 'Build failed — check the console log above.' }
    always  { archiveArtifacts artifacts: 'plan.out', allowEmptyArchive: true, onlyIfSuccessful: false }
  }
}
