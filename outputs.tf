output "vm_ipv4" {
  # Proxmox provider exposes the primary IP when guest agent is working
  value = proxmox_vm_qemu.vm-instance.default_ipv4_address
}

