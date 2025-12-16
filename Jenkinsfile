pipeline {
  agent any
  options { timestamps() }

  parameters {
    booleanParam(
      name: 'APPLY',
      defaultValue: true,
      description: 'Create VM'
    )
    string(
      name: 'VM_NAME',
      defaultValue: 'vm',
      description: 'VM name prefix'
    )
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {

    stage('Terraform Create VM') {
      when { expression { return params.APPLY } }

      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
      }

      steps {
        sh '''
          set -e

          # ----------------------------------------------------
          # Generate unique name + VMID (200–299)
          # ----------------------------------------------------
          VMID=$((200 + BUILD_NUMBER % 100))
          VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"

          echo "Creating VM: ${VM_NAME_FINAL} (VMID: ${VMID})"

          # ----------------------------------------------------
          # Use a THROWAWAY state file (no replacements ever)
          # ----------------------------------------------------
          STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

          terraform init -input=false

          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          TF_VAR_vm_name="$VM_NAME_FINAL" \
          TF_VAR_vmid="$VMID" \
          terraform apply \
            -input=false \
            -auto-approve \
            -state="$STATE"
        '''
      }
    }
  }

  post {
    success {
      echo 'VM successfully created.'
    }
    failure {
      echo 'VM creation failed — check logs.'
    }
  }
}

