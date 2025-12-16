pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'VM_NAME', defaultValue: 'vm', description: 'VM name prefix')
    choice(name: 'MEMORY', choices: ['2048', '4096', '8192', '16384'], description: 'Memory in MB')
    choice(name: 'CORES', choices: ['1', '2', '4', '6', '8'], description: 'CPU cores')
    choice(name: 'DISK_SIZE', choices: ['20G', '50G', '100G', '200G'], description: 'Disk size')
    booleanParam(name: 'APPLY', defaultValue: true, description: 'Create VM')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {

    stage('Terraform Init + Apply') {
      when { expression { params.APPLY } }

      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
        SSH_PUBLIC_KEY      = credentials('SSH_PUBKEY')
      }

      steps {
        dir(env.WORKSPACE) {
          sh '''
            set -euo pipefail

            echo "Workspace: $(pwd)"
            ls -al

            test -f outputs.tf || { echo "ERROR: outputs.tf missing"; exit 1; }

            VMID=$((200 + BUILD_NUMBER % 100))
            VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"
            STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

            terraform init -input=false

            export TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID"
            export TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET"
            export TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY"
            export TF_VAR_vm_name="$VM_NAME_FINAL"
            export TF_VAR_vmid="$VMID"
            export TF_VAR_memory="$MEMORY"
            export TF_VAR_cores="$CORES"
            export TF_VAR_disk_size="$DISK_SIZE"

            terraform apply -auto-approve -input=false -state="$STATE"

            echo "Waiting for QEMU guest agent IP..."
          '''
        }
      }
    }

    stage('Wait for VM IP + Generate Inventory') {
      when { expression { params.APPLY } }

      steps {
        dir(env.WORKSPACE) {
          sh '''
            set -euo pipefail

            STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

            VM_IP=""
            for i in $(seq 1 60); do
              terraform apply -refresh-only -auto-approve -input=false -state="$STATE" >/dev/null 2>&1 || true
              CANDIDATE=$(terraform output -state="$STATE" -raw vm_ipv4 2>/dev/null || true)

              if echo "$CANDIDATE" | grep -Eq '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$'; then
                VM_IP="$CANDIDATE"
                break
              fi

              echo "Attempt $i/60 — waiting for IP..."
              sleep 5
            done

            if [ -z "$VM_IP" ]; then
              echo "ERROR: Failed to retrieve VM IP"
              terraform output -state="$STATE" || true
              exit 1
            fi

            echo "VM IP: $VM_IP"

            cat > inventory.ini <<EOF
[proxmox_vms]
$VM_IP ansible_user=mirage
EOF

            cat inventory.ini
          '''
        }
      }
    }

    stage('Configure VM with Ansible') {
      when { expression { params.APPLY } }

      steps {
        sshagent(credentials: ['ansible_ssh']) {
          dir(env.WORKSPACE) {
            sh '''
              set -euo pipefail

              export ANSIBLE_HOST_KEY_CHECKING=False

              if ! command -v ansible >/dev/null 2>&1; then
                apt-get update -y
                apt-get install -y ansible
              fi

              ansible -i inventory.ini proxmox_vms -m ping
              ansible-playbook -i inventory.ini ansible/site.yml
            '''
          }
        }
      }
    }
  }

  post {
    success {
      echo "VM successfully created and configured"
    }
    failure {
      echo "Pipeline failed — check logs"
    }
    always {
      archiveArtifacts artifacts: 'inventory.ini', allowEmptyArchive: true
    }
  }
}

