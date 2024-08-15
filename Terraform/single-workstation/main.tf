terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.48.1"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.16.0"
    }
  }
}

variable "proxmox_host" {
  type        = string
  default     = "pve"
  description = "Proxmox node name"
}

variable "hostname" {
  type        = string
  default     = "seclab-win-ws"
  description = "hostname"
}

variable "template_id" {
  type        = string
  description = "Template ID for clone"
}

provider "vault" {

}

data "vault_kv_secret_v2" "seclab" {
  mount = "seclab"
  name  = "seclab"
}

provider "proxmox" {
  # Configuration options
  endpoint  = "https://${var.proxmox_host}:8006/api2/json"
  insecure  = true
  api_token = "${data.vault_kv_secret_v2.seclab.data.proxmox_api_id}=${data.vault_kv_secret_v2.seclab.data.proxmox_api_token}"
}


resource "proxmox_virtual_environment_vm" "seclab-ws" {
  name      = "seclab-ws"
  node_name = var.proxmox_host
  on_boot   = true

  clone {
    vm_id = var.template_id
    full  = false
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr1"
    model  = "e1000"
  }
  # network_device {
  #   bridge = "vmbr3"
  #   model  = "e1000"
  # }

  connection {
    type            = "ssh"
    user            = data.vault_kv_secret_v2.seclab.data.seclab_user
    password        = data.vault_kv_secret_v2.seclab.data.seclab_windows_password
    host            = self.ipv4_addresses[0][0]
    target_platform = "windows"
  }


  provisioner "remote-exec" {
    inline = [
      "powershell.exe -c Rename-Computer '${var.hostname}'",
      "powershell.exe -c Start-Service W32Time",
      "W32tm /resync /force",
      "ipconfig"
    ]
  }

}

output "vm_ip" {
  value       = proxmox_virtual_environment_vm.seclab-ws.ipv4_addresses
  sensitive   = false
  description = "VM IP"
}
