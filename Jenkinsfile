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
    PVE_URL  = 'https://192.168.1.100:8006'
    PVE_NODE = 'proxmox'
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

            VMID=$((200 + BUILD_NUMBER % 100))
            VM_NAME_FINAL="${VM_NAME}-${BUILD_NUMBER}"
            STATE="/tmp/terraform-${BUILD_NUMBER}.tfstate"

            echo "Creating VM: $VM_NAME_FINAL (VMID=$VMID)"

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

            echo "$VMID" > .vmid
            echo "$STATE" > .tfstate_path
          '''
        }
      }
    }

    stage('Get VM IP from Proxmox Guest Agent API') {
      when { expression { params.APPLY } }

      environment {
        PM_API_TOKEN_ID     = credentials('PM_API_TOKEN_ID')
        PM_API_TOKEN_SECRET = credentials('PM_API_TOKEN_SECRET')
      }

      steps {
        dir(env.WORKSPACE) {
          sh '''
            set -euo pipefail

            # Ensure tools exist in the Jenkins container
            if ! command -v jq >/dev/null 2>&1; then
              apt-get update -y
              apt-get install -y jq curl
            fi

            VMID="$(cat .vmid)"
            AUTH="PVEAPIToken=${PM_API_TOKEN_ID}=${PM_API_TOKEN_SECRET}"

            echo "Waiting for guest-agent IPv4 via Proxmox API (VMID=$VMID)..."

            VM_IP=""
            RESP=""

            for i in $(seq 1 60); do
              RESP=$(curl -sk -H "Authorization: $AUTH" \
                "${PVE_URL}/api2/json/nodes/${PVE_NODE}/qemu/${VMID}/agent/network-get-interfaces" || true)

              VM_IP=$(echo "$RESP" | jq -r '
                .data.result[]? | .["ip-addresses"][]? |
                select(.["ip-address-type"]=="ipv4") |
                .["ip-address"]
              ' 2>/dev/null | grep -Ev '^(127[.]|169[.]254[.])' | head -n 1 || true)

              if echo "$VM_IP" | grep -Eq '^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$'; then
                echo "Found VM IP: $VM_IP"
                break
              fi

              echo "Attempt $i/60 — no IP yet, sleeping..."
              sleep 5
            done

            if [ -z "$VM_IP" ]; then
              echo "ERROR: Could not retrieve VM IP from guest agent API."
              echo "Last response (truncated):"
              echo "$RESP" | head -c 2000 || true
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
    success { echo 'VM successfully created + configured.' }
    failure { echo 'Pipeline failed — check logs.' }
    always  { archiveArtifacts artifacts: 'inventory.ini', allowEmptyArchive: true }
  }
}

