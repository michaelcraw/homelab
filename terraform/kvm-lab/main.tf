terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~> 0.8"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://michael@100.117.229.28/system?keyfile=/Users/michael/.ssh/id_ed25519"
}
