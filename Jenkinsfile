pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'VM_NAME', defaultValue: 'vm', description: 'VM name prefix')

    choice(name: 'CORES', choices: "1\n2\n4\n6\n8", description: 'Number of CPU cores')
    choice(name: 'MEMORY', choices: "2048\n4096\n8192\n16384", description: 'Memory in MB')
    choice(name: 'DISK_SIZE', choices: "20G\n50G\n100G\n200G", description: 'Disk size')

    booleanParam(name: 'APPLY', defaultValue: true, description: 'Create VM')
    booleanParam(name: 'RUN_ANSIBLE', defaultValue: true, description: 'Run Ansible after Terraform')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {

    stage('Terraform Init & Apply') {
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

          echo "Creating VM: ${VM_NAME_FINAL} (VMID: ${VMID})"
          echo "Specs: ${CORES} cores, ${MEMORY} MB RAM, ${DISK_SIZE} disk"

          # Throwaway state so runs never replace prior VMs
          STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

          terraform -version
          terraform init -input=false
          terraform fmt -check || true
          terraform validate

          TF_VAR_pm_api_token_id="$PM_API_TOKEN_ID" \
          TF_VAR_pm_api_token_secret="$PM_API_TOKEN_SECRET" \
          TF_VAR_ssh_pubkey="$SSH_PUBLIC_KEY" \
          TF_VAR_vm_name="$VM_NAME_FINAL" \
          TF_VAR_vmid="$VMID" \
          TF_VAR_memory="$MEMORY" \
          TF_VAR_cores="$CORES" \
          TF_VAR_disk_size="$DISK_SIZE" \
          terraform apply \
            -input=false \
            -auto-approve \
            -state="$STATE"

          # Wait a bit for DHCP + guest agent/IP reporting (adjust if needed)
          VM_IP=""
          for i in $(seq 1 30); do
            VM_IP="$(terraform output -raw -state="$STATE" vm_ip 2>/dev/null || true)"
            if [ -n "$VM_IP" ]; then
              break
            fi
            echo "Waiting for vm_ip... (${i}/30)"
            sleep 5
          done

          if [ -z "$VM_IP" ]; then
            echo "ERROR: vm_ip output is empty. (Guest agent not ready / no IP reported.)"
            echo "Tip: ensure qemu-guest-agent is installed+enabled in the template and agent=1 in Terraform."
            exit 1
          fi

          echo "VM_IP=$VM_IP" | tee vm_ip.env
          echo "VM created at IP: $VM_IP"

          # Generate Ansible inventory in the workspace
          cat > inventory.ini <<EOF
[all]
$VM_IP ansible_user=mirage
EOF

          echo "----- inventory.ini -----"
          cat inventory.ini
          echo "-------------------------"
        '''
      }
    }

    stage('Configure with Ansible') {
      when {
        allOf {
          expression { return params.APPLY }
          expression { return params.RUN_ANSIBLE }
          expression { fileExists('site.yml') }
          expression { fileExists('inventory.ini') }
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
    always  { archiveArtifacts artifacts: 'inventory.ini, vm_ip.env', allowEmptyArchive: true }
  }
}

