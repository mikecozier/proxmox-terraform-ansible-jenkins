pipeline {
  agent any
  options { timestamps() }

  parameters {
    string(name: 'VM_NAME', defaultValue: 'vm', description: 'VM name prefix')
    choice(name: 'MEMORY', choices: ['2048', '4096', '8192', '16384'], description: 'Memory (MB)')
    choice(name: 'CORES', choices: ['1', '2', '4', '6', '8'], description: 'CPU cores')
    choice(name: 'DISK_SIZE', choices: ['20G', '50G', '100G', '200G'], description: 'Disk size')
    booleanParam(name: 'APPLY', defaultValue: true, description: 'Create + configure VM')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT = '0'
    // Proxmox API base (use your private IP or your domain)
    PM_API_URL = 'https://192.168.1.100:8006/api2/json'
    PM_NODE    = 'proxmox'
  }

  stages {
    stage('Terraform Apply') {
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

          echo "Creating VM: ${VM_NAME_FINAL} (VMID=${VMID})"
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

          echo "$VMID" > vmid.txt
          echo "$STATE" > tfstate_path.txt
        '''
        archiveArtifacts artifacts: 'vmid.txt,tfstate_path.txt', onlyIfSuccessful: false
      }
    }

    stage('Wait for Guest Agent IP (Proxmox API)') {
      when { expression { return params.APPLY } }

      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
      }

      steps {
        sh '''
          set -euo pipefail

          VMID="$(cat vmid.txt)"
          echo "Waiting for guest-agent IP for VMID=${VMID} ..."

          AUTH_HEADER="Authorization: PVEAPIToken=${PM_API_TOKEN_ID}=${PM_API_TOKEN_SECRET}"

          VM_IP=""
          for i in $(seq 1 60); do
            JSON="$(curl -sk -H "$AUTH_HEADER" \
              "${PM_API_URL}/nodes/${PM_NODE}/qemu/${VMID}/agent/network-get-interfaces" || true)"

            VM_IP="$(echo "$JSON" | jq -r '
              .data.result[]?.["ip-addresses"][]? |
              select(.["ip-address-type"]=="ipv4") |
              .["ip-address"]
            ' 2>/dev/null | grep -E '^[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+$' | grep -Ev '^(127\\.|169\\.254\\.)' | head -n1 || true)"

            if [ -n "$VM_IP" ]; then
              echo "VM_IP=$VM_IP"
              break
            fi

            echo "Attempt $i/60: IP not ready yet"
            sleep 5
          done

          if [ -z "$VM_IP" ]; then
            echo "ERROR: Could not get VM IP from Proxmox guest agent."
            echo "Last JSON:"
            echo "$JSON" | head -c 2000 || true
            exit 1
          fi

          cat > inventory.ini <<EOF
[proxmox_vms]
$VM_IP ansible_user=mirage
EOF

          echo "Generated inventory.ini:"
          cat inventory.ini
        '''
        archiveArtifacts artifacts: 'inventory.ini', onlyIfSuccessful: false
      }
    }

    stage('Configure VM with Ansible') {
      when { expression { return params.APPLY } }

      environment {
        // Expose Vault unseal keys to the shell/ansible-playbook process
        VAULT_UNSEAL_KEY_1 = credentials('vault-unseal-key-1')
        VAULT_UNSEAL_KEY_2 = credentials('vault-unseal-key-2')
        VAULT_UNSEAL_KEY_3 = credentials('vault-unseal-key-3')
      }

      steps {
        sshagent(credentials: ['ansible_ssh']) {
          sh '''
            set -euo pipefail
            export ANSIBLE_HOST_KEY_CHECKING=False

            # Make sure Ansible can read these env vars
            test -n "$VAULT_UNSEAL_KEY_1"
            test -n "$VAULT_UNSEAL_KEY_2"
            test -n "$VAULT_UNSEAL_KEY_3"

            ansible -i inventory.ini proxmox_vms -m ping

            # Your playbook should read the keys via lookup('env','VAULT_UNSEAL_KEY_1') etc
            ansible-playbook -i inventory.ini ansible/site.yml
          '''
        }
      }
    }
  }

  post {
    success { echo 'VM successfully created + configured.' }
    failure { echo 'Pipeline failed — check logs.' }
    always  { archiveArtifacts artifacts: 'inventory.ini,vmid.txt,tfstate_path.txt', onlyIfSuccessful: false }
  }
}

