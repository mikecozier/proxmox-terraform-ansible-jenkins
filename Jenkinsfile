pipeline {
  agent any

  options {
    timestamps()
    ansiColor('xterm')
  }

  environment {
    // Proxmox creds (Secret Text)
    PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
    PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
    // Your SSH PUBLIC key (Secret Text) for cloud-init
    SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
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

    // ----- OPTIONAL: run Ansible after the VM is created -----
    stage('Configure with Ansible') {
      when { expression { return params.APPLY } }
      environment {
        ANSIBLE_HOST_KEY_CHECKING = 'False'
      }
      steps {
        // only run if you actually have these files in the repo
        sh '''
          if [ -f "inventory.ini" ] && [ -f "site.yml" ]; then
            echo "Running Ansible…"
          else
            echo "No inventory.ini or site.yml found — skipping Ansible stage."
            exit 0
          fi
        '''
        sshagent(credentials: ['ansible_ssh']) {
          sh '''
            # Install ansible if it's not already in the Jenkins container
            if ! command -v ansible >/dev/null 2>&1; then
              echo "Installing Ansible in Jenkins container…"
              python3 -m pip install --upgrade pip setuptools wheel >/dev/null 2>&1 || true
              python3 -m pip install ansible
            fi
            ansible --version
            ansible-playbook -i inventory.ini site.yml
          '''
        }
      }
    }
    // ---------------------------------------------------------
  }

  post {
    success {
      archiveArtifacts artifacts: 'plan.out', onlyIfSuccessful: true
    }
    failure {
      echo 'Build failed. Check the console log for errors.'
    }
  }
}

