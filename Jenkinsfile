pipeline {
  agent any
  options { timestamps() }

  parameters {
    booleanParam(name: 'APPLY', defaultValue: false, description: 'Run terraform apply (otherwise only plan).')
    string(name: 'VM_NAME', defaultValue: 'vm', description: 'VM name prefix (final name includes build number).')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {

    stage('Terraform Init & Plan') {
      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
      }
      steps {
        sh '''
          set -e

          # Auto-generate VMID in range 200-299
          VMID=$((200 + BUILD_NUMBER % 100))
          VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"

          echo "Plan for VM: $VM_NAME_FINAL (VMID: $VMID)"

          terraform -version
          terraform init -input=false
          terraform fmt -check || true
          terraform validate

          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          TF_VAR_vm_name="$VM_NAME_FINAL" \
          TF_VAR_vmid="$VMID" \
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

          VMID=$((200 + BUILD_NUMBER % 100))
          VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"

          echo "Apply for VM: $VM_NAME_FINAL (VMID: $VMID)"

          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          TF_VAR_vm_name="$VM_NAME_FINAL" \
          TF_VAR_vmid="$VMID" \
          terraform apply -input=false -auto-approve plan.out
        '''
      }
    }

    stage('Configure with Ansible') {
      when {
        allOf {
          expression { return params.APPLY }
          expression { fileExists('inventory.ini') }
          expression { fileExists('site.yml') }
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

