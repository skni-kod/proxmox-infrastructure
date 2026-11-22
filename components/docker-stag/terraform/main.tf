terraform {
  backend "s3" {
    bucket                      = "terraform-state"
    key                         = "docker-stag/terraform.tfstate"
    region                      = "main"
    endpoints                   = { s3 = "http://192.168.1.125:9000" }
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    use_path_style              = true
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.pm_api_url
  insecure = true
}

module "docker_stag" {
  source = "git::https://github.com/skni-kod/terraform-modules.git//proxmox-vm?ref=v1.0.0"

  name           = var.docker_node.name
  target_node    = var.target_node
  vmid           = var.docker_node.vmid
  tags           = ["docker", "staging"]
  cores          = var.docker_node.cores
  memory         = var.docker_node.mem
  disk_size      = var.docker_node.disk_size
  cloned_vm_id   = 9000
  network_bridge = var.network_bridge
  ip_address     = var.docker_node.ip
  gateway        = var.gateway
  ci_user        = var.ci_user
  ssh_public_key = var.ssh_public_key
}
