output "vm_ipv4" {
  description = "VM IPv4 from QEMU guest agent"
  value       = proxmox_vm_qemu.vm-instance.default_ipv4_address
}

