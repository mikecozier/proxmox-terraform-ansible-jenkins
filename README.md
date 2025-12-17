# Proxmox VM Provisioning Pipeline
Terraform • Ansible • Jenkins • Vault • Prometheus

This repository demonstrates an end-to-end infrastructure automation pipeline for provisioning and configuring virtual machines on Proxmox VE using modern DevOps practices.

The pipeline uses Terraform for Infrastructure as Code (IaC), Jenkins for CI/CD orchestration, Ansible for post-provisioning configuration, HashiCorp Vault for short-lived SSH certificates, and Prometheus for automated monitoring.

## What This Project Does

### Jenkins Pipeline
- Triggers infrastructure builds
- Accepts parameters (VM name, CPU, memory)
- Orchestrates Terraform + Ansible
- Uses Jenkins Credentials (no secrets in Git)

### Terraform (IaC)
- Provisions VMs on Proxmox from templates
- Configures CPU, memory, disk, networking
- Injects SSH keys via cloud-init
- Uses API tokens (least privilege)

### Ansible Configuration
- Applies baseline configuration
- Installs Docker + Node Exporter
- Requests Vault-signed SSH certificates
- Configures secure SSH usage

### Vault SSH Authentication
- Uses Vault as an SSH Certificate Authority
- Eliminates static SSH keys
- Issues short-lived certificates via AppRole

### Prometheus Integration
- Registers new VMs as scrape targets
- Uses file_sd for clean, idempotent updates
- Restarts Prometheus safely when needed

## Architecture Overview

    Jenkins
       |
       |--> Terraform (Proxmox API)
       |       |
       |       --> VM Created (Cloud-Init)
       |
       |--> Ansible
               |
               |--> OS Baseline
               |--> Docker + Node Exporter
               |--> Vault SSH Cert Signing
               |
               |--> Prometheus Target Registration

## Security Model
- No secrets committed to Git
- Credentials injected via Jenkins Credentials / environment variables
- Vault must already be unsealed / auto-unsealed
- SSH access uses short-lived certificates
- Terraform secrets are marked sensitive
- .gitignore prevents state/secret leakage

## Repository Structure

    .
    ├── Jenkinsfile
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── ansible/
    │   ├── site.yml
    │   └── ssh_config.j2
    └── README.md

## License
MIT
