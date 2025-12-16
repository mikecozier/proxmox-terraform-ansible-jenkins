terraform {
      required_providers {
        proxmox = {
            source = "telmate/proxmox"
              version = "= 3.0.2-rc06"
        }
    }
}

provider "proxmox" {
    pm_api_url          = "https://192.168.1.100:8006/api2/json"
    pm_api_token_id     = var.pm_api_token_id
    pm_api_token_secret = var.pm_api_token_secret
    pm_tls_insecure     = true
}

resource "proxmox_vm_qemu" "vm-instance" {
    name                = var.vm_name
    vmid                = var.vmid
    target_node         = "proxmox"
    clone               = "terraform-template"
    full_clone          = true    
    memory              = var.memory
    qemu_os             = "l26"
    cpu {
      sockets           = 1
      cores             = var.cores
      type              = "host"
}
     
  # Controller + boot order (stabilizes readbacks)
    scsihw = "virtio-scsi-pci"
    boot   = "order=scsi0;net0"
    
 # Explicitly define the Cloud-Init drive to guarantee it exists.
    disk {
      slot    = "ide2"
      type    = "cloudinit"
      storage = "local"
  }
    network {
        id        = 0
        model     = "virtio"
        bridge    = "vmbr0"
        firewall  = false
        link_down = false
    }

    # Serial console (keeps your serial0 path)
    serial {
      id          = 0
      type        = "socket"
}
    vga {
      type = "serial0"
}

    # --- Cloud-Init (ADD THESE) ---
    agent     = 1
    ciuser    = "mirage"
    sshkeys  = trimspace(var.ssh_pubkey)  # <— trims trailing newline/space
    ipconfig0 = "ip=dhcp"

    # Optional: make apply finish fast (Ansible can wait for SSH)
    define_connection_info     = false
    additional_wait            = 0
}
