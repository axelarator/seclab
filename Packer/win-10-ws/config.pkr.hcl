packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "hostname" {
  type    = string
  default = "seclab-win-ws"
}

locals {
  username          = vault("/seclab/data/seclab/", "seclab_user")
  password          = vault("/seclab/data/seclab/", "seclab_windows_password")
  proxmox_api_id    = vault("/seclab/data/seclab/", "proxmox_api_id")
  proxmox_api_token = vault("/seclab/data/seclab/", "proxmox_api_token")
}

variable "pve" {
  type    = string
  default = "192.168.141.60"
}

source "proxmox-iso" "seclab-win-ws" {
  proxmox_url  = "https://${var.pve}:8006/api2/json"
  node         = "pve"
  username     = "${local.proxmox_api_id}"
  token        = "${local.proxmox_api_token}"
  iso_file     = "local:iso/Win-10-Enterprise.iso"
  iso_checksum = "sha256:ef7312733a9f5d7d51cfa04ac497671995674ca5e1058d5164d6028f0938d668"
  /*skip_export             = true*/
  communicator             = "ssh"
  ssh_username             = "${local.username}"
  ssh_password             = "${local.password}"
  ssh_timeout              = "30m"
  qemu_agent               = true
  cores                    = 2
  memory                   = 4096
  vm_name                  = "seclab-win-ws"
  template_description     = "Base Seclab Windows Workstation"
  insecure_skip_tls_verify = true

  additional_iso_files {
    device       = "ide3"
    iso_file     = "local:iso/Autounattend-win-10-ws.iso"
    iso_checksum = "sha256:0d910d36b541259b79d962ecaa4825974bc1886ad2dd649e27d842beda93cdaf"
  }
  additional_iso_files {
    device       = "sata0"
    iso_file     = "local:iso/virtio.iso"
    iso_checksum = "sha256:8a066741ef79d3fb66e536fb6f010ad91269364bd9b8c1ad7f2f5655caf8acd8"
    unmount      = true
  }

  network_adapters {
    bridge = "vmbr2"
  }

  disks {
    type         = "virtio"
    disk_size    = "50G"
    storage_pool = "local-lvm"
  }
  scsi_controller = "virtio-scsi-pci"

}

build {
  sources = ["sources.proxmox-iso.seclab-win-ws"]
  provisioner "windows-shell" {
    inline = ["ipconfig"]
  }
}
