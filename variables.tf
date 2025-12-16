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

variable "memory" {
  description = "VM memory in MB"
  type        = number
  default     = 4096
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "disk_size" {
  description = "Disk size (e.g. 20G, 50G, 100G)"
  type        = string
  default     = "50G"
}

