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

# SSH public key text
variable "ssh_public_key" {
  description = "SSH public key for cloud-init"
  type        = string
}

# (Optional) add other inputs here later, e.g. vm_name, memory, etc.

