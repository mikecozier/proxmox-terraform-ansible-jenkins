---

```markdown
# Proxmox VM Provisioning Pipeline  
**Terraform • Ansible • Jenkins • Vault • Prometheus**

This repository demonstrates an end-to-end **infrastructure automation pipeline** for provisioning and configuring virtual machines on **Proxmox VE** using modern DevOps practices.

The pipeline uses **Terraform** for Infrastructure as Code (IaC), **Jenkins** for CI/CD orchestration, **Ansible** for post-provisioning configuration, **HashiCorp Vault** for short-lived SSH certificates, and **Prometheus** for automated monitoring.

This project is designed to mirror **real-world enterprise workflows**, not a simple homelab script.

---

## 🚀 What This Project Does

1. **Jenkins Pipeline**
   - Triggers infrastructure builds
   - Passes parameters (VM name, CPU, memory)
   - Orchestrates Terraform + Ansible
   - Uses secure credential handling (no secrets in Git)

2. **Terraform (IaC)**
   - Provisions VMs on Proxmox from templates
   - Configures CPU, memory, disks, networking
   - Injects SSH keys via cloud-init
   - Uses API tokens (least privilege)

3. **Ansible Configuration**
   - Applies OS baseline configuration
   - Installs Docker and Node Exporter
   - Requests Vault-signed SSH certificates
   - Configures secure SSH access

4. **Vault-Based SSH Authentication**
   - Uses Vault as an SSH Certificate Authority
   - Eliminates static SSH keys
   - Issues short-lived SSH certificates via AppRole

5. **Prometheus Integration**
   - Automatically registers new VMs as scrape targets
   - Uses `file_sd` for clean, idempotent updates
   - Restarts Prometheus safely when needed

---

## 🧱 Architecture Overview

```

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

```

---

## 🔐 Security Model

- **No secrets committed to Git**
- All credentials injected via:
  - Jenkins Credentials
  - Environment variables
- Vault **must already be unsealed / auto-unsealed**
- SSH access uses **short-lived certificates**, not static keys
- Terraform variables marked `sensitive`
- `.gitignore` prevents accidental leakage of state or credentials

---

## 📁 Repository Structure

```

.
├── Jenkinsfile
├── main.tf
├── variables.tf
├── outputs.tf
├── ansible/
│   ├── site.yml
│   └── ssh_config.j2
├── .gitignore
└── README.md

```

---

## ⚙️ Prerequisites

- Proxmox VE (API access enabled)
- Jenkins with:
  - Terraform
  - Ansible
  - SSH Agent plugin
- HashiCorp Vault (AppRole + SSH secrets engine)
- Prometheus (Docker-based or equivalent)
- Ubuntu cloud-init template in Proxmox

---

## 🧪 How It Works (High Level)

1. Jenkins pipeline is triggered
2. Terraform provisions a VM on Proxmox
3. Jenkins waits for VM IP via QEMU guest agent
4. Ansible configures the VM
5. Vault signs the VM’s SSH key
6. Node Exporter is deployed
7. Prometheus is updated automatically

---

## 📌 Why This Project Matters

This project demonstrates:
- Infrastructure as Code (Terraform)
- Configuration management (Ansible)
- CI/CD orchestration (Jenkins)
- Secure access patterns (Vault SSH certs)
- Observability automation (Prometheus)
- Real-world DevOps design decisions

It reflects the type of automation used in **production infrastructure and platform teams**.

---

## 🧠 Author

**Michael Cozier**  
DevOps Engineer | Infrastructure Automation | Linux  
GitHub: https://github.com/mikecozier

---

## 📜 License

MIT License
```

---

