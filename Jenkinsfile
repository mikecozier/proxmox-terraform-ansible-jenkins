pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'VM_NAME', defaultValue: 'vm', description: 'VM name prefix')
    choice(name: 'MEMORY', choices: ['2048', '4096', '8192', '16384'], description: 'Memory in MB')
    choice(name: 'CORES', choices: ['1', '2', '4', '6', '8'], description: 'Number of CPU cores')
    choice(name: 'DISK_SIZE', choices: ['20G', '50G', '100G', '200G'], description: 'Disk size')
    booleanParam(name: 'APPLY', defaultValue: true, description: 'Create VM')
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
          set -euo pipefail

          VMID=$((200 + BUILD_NUMBER % 100))
          VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"
          STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

          echo "Creating VM: ${VM_NAME_FINAL} (VMID: ${VMID})"
          echo "Specs: ${CORES} cores, ${MEMORY} MB RAM, ${DISK_SIZE} disk"

          rm -rf .terraform terraform.tfstate terraform.tfstate.backup || true
          terraform init -input=false

          export TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID"
          export TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET"
          export TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY"
          export TF_VAR_vm_name="$VM_NAME_FINAL"
          export TF_VAR_vmid="$VMID"
          export TF_VAR_memory="$MEMORY"
          export TF_VAR_cores="$CORES"
          export TF_VAR_disk_size="$DISK_SIZE"

          terraform apply -input=false -auto-approve -state="$STATE"

          echo "=== DEBUG: terraform output (from STATE) ==="
          terraform output -state="$STATE" || true
        '''
      }
    }

    stage('Generate Inventory (VM IP)') {
      when { expression { return params.APPLY } }

      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
      }

      steps {
        sh '''
          set -euo pipefail

          VMID=$((200 + BUILD_NUMBER % 100))
          VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"
          STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

          export TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID"
          export TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET"
          export TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY"
          export TF_VAR_vm_name="$VM_NAME_FINAL"
          export TF_VAR_vmid="$VMID"
          export TF_VAR_memory="$MEMORY"
          export TF_VAR_cores="$CORES"
          export TF_VAR_disk_size="$DISK_SIZE"

          # ✅ CRITICAL FIX: init again in this NEW shell/stage so outputs are loaded
          terraform init -input=false

          echo "Waiting for vm_ipv4 to become a real IPv4 address..."

          VM_IP=""
          for i in $(seq 1 60); do
            CANDIDATE="$(terraform output -state="$STATE" -raw vm_ipv4 2>/dev/null || true)"

            if echo "$CANDIDATE" | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$'; then
              VM_IP="$CANDIDATE"
              echo "VM_IP=$VM_IP"
              break
            fi

            echo "Attempt $i/60: not ready (got: '$CANDIDATE')"
            sleep 5
          done

          if [ -z "$VM_IP" ]; then
            echo "ERROR: Could not get vm_ipv4 from Terraform state."
            echo "State file: $STATE"
            terraform output -state="$STATE" || true
            exit 1
          fi

          cat > inventory.ini <<EOF
[proxmox_vms]
$VM_IP ansible_user=mirage
EOF

          echo "Generated inventory.ini:"
          cat inventory.ini
        '''
      }
    }

    stage('Configure VM with Ansible') {
      when { expression { return params.APPLY } }

      steps {
        sshagent(credentials: ['ansible_ssh']) {
          sh '''
            set -euo pipefail

            if ! command -v ansible >/dev/null 2>&1; then
              sudo apt-get update -y
              sudo apt-get install -y ansible
            fi

            export ANSIBLE_HOST_KEY_CHECKING=False

            ansible -i inventory.ini proxmox_vms -m ping
            ansible-playbook -i inventory.ini ansible/site.yml
          '''
        }
      }
    }
  }

  post {
    success { echo 'VM successfully created + configured.' }
    failure { echo 'Pipeline failed — check logs.' }
    always  { archiveArtifacts artifacts: 'inventory.ini', onlyIfSuccessful: false }
  }
}

