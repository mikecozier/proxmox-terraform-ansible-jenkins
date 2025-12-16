output "vm_ip" {
  value = proxmox_vm_qemu.vm-instance.default_ipv4_address
}

