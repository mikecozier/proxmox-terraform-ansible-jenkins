# Proxmox API credentials
variable "pm_api_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "pm_api_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "ssh_pubkey" {
  description = "SSH public key for cloud-init"
  type        = string
}

variable "vm_name" {
  description = "Name of the VM in Proxmox"
  type        = string
}

variable "vmid" {
  description = "Unique VM ID in Proxmox"
  type        = number
}

# (Optional) add other inputs here later, e.g. vm_name, memory, etc.

