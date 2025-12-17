terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "= 3.0.2-rc06"
    }
  }
}

# ----------------------------
# Provider (PUBLIC-SAFE)
# - No hardcoded internal IP
# - No hardcoded node name
# - TLS settings configurable
# ----------------------------
provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
}

resource "proxmox_vm_qemu" "vm_instance" {
  name        = var.vm_name
  vmid        = var.vmid
  target_node = var.pm_node

  clone      = var.template_name
  full_clone = true

  memory = var.memory
  qemu_os = "l26"

  cpu {
    sockets = 1
    cores   = var.cores
    type    = "host"
  }

  # Controller + boot order (stabilizes readbacks)
  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0;net0"

  disk {
    type    = "disk"
    size    = var.disk_size
    storage = var.storage
    slot    = "scsi0"
    discard = true
  }

  # Cloud-init drive (guarantees it exists)
  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = var.storage
  }

  network {
    id        = 0
    model     = "virtio"
    bridge    = var.bridge
    firewall  = false
    link_down = false
  }

  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  # --- Cloud-Init ---
  agent     = 1
  ciuser    = var.ci_user
  sshkeys   = trimspace(var.ssh_pubkey)
  ipconfig0 = "ip=dhcp"

  define_connection_info = false
  additional_wait        = 0
}
